// BACKEND/UTILS/AGENDARDESDECHAT.JS
// Lógica para agendar citas desde el chat (texto o voz).
// El modelo de IA solo PROPONE; aquí se valida todo y se crea la cita.
// Nada de lo que diga el modelo o envíe la app se toma como cierto:
// vehículo, servicio, precio, cupos y horario se comprueban en el servidor.

import mongoose from 'mongoose';
import Appointment from '../models/Appointment.js';
import Vehicle from '../models/Vehicle.js';
import Service from '../models/Service.js';
import User from '../models/User.js';
import { sendEmail } from '../services/emailService.js';
import { contarCitasEnHora, LIMITE_POR_HORA } from './cupos.js';
import { crearNotificacion } from './notificaciones.js';

const ZONA = 'America/Bogota';

// Horas en las que se agendan citas (formato 24 h, hora de Colombia).
// Deben coincidir con las del calendario de la app.
export const HORAS_CITA = [8, 9, 10, 11, 14, 15, 16, 17];

const DIAS_MAXIMOS = 60; // hasta cuántos días adelante se puede agendar
const MINUTOS_MINIMOS = 30; // anticipación mínima

const METODOS_PAGO = [
  { clave: 'efectivo', texto: 'Efectivo', patron: /efect/ },
  { clave: 'transferencia', texto: 'Transferencia', patron: /transf|nequi|davi/ },
  { clave: 'tarjeta', texto: 'Tarjeta', patron: /tarj|debit|credit/ },
];

const sinTildes = (t) =>
  String(t || '')
    .normalize('NFD')
    .replace(/[\u0300-\u036f]/g, '')
    .toLowerCase()
    .trim();

// ───────── Textos de servicio y vehículo ─────────
export const nombreServicio = (s) =>
  s.nombre || s.nombreServicio || s.Nombre || s.name || 'Servicio';

export const duracionServicio = (s) =>
  Number(s.duracionEstimadaMinutos ?? s.duracionMinutos) || 60;

export const describirVehiculo = (v) => {
  const marcaModelo = [v.marca || v.Marca, v.modelo || v.Modelo].filter(Boolean).join(' ');
  const placa = v.placa || v.Placa;
  const base = [marcaModelo, placa ? `(${placa})` : ''].filter(Boolean).join(' ');
  return base || v.tipoVehiculo || 'Vehículo';
};

// ───────── Fechas (siempre en hora de Colombia, UTC-5) ─────────
const fechaValida = (fecha) => {
  if (!/^\d{4}-\d{2}-\d{2}$/.test(String(fecha))) return false;
  const d = new Date(`${fecha}T12:00:00-05:00`);
  return (
    !Number.isNaN(d.getTime()) &&
    d.toLocaleDateString('en-CA', { timeZone: ZONA }) === fecha
  );
};

export const fechaHoraColombia = (fecha, hora) =>
  new Date(`${fecha}T${String(hora).padStart(2, '0')}:00:00-05:00`);

const diaSemanaNumero = (fecha) => new Date(`${fecha}T12:00:00-05:00`).getUTCDay();

export const nombreDia = (fecha) =>
  new Date(`${fecha}T12:00:00-05:00`).toLocaleDateString('es-CO', {
    weekday: 'long',
    timeZone: ZONA,
  });

// Domingos solo hay atención en la mañana (el spa cierra a las 12:00).
export const horasDelDia = (fecha) =>
  diaSemanaNumero(fecha) === 0 ? HORAS_CITA.filter((h) => h < 12) : HORAS_CITA;

const textoHora = (fecha, hora) =>
  fechaHoraColombia(fecha, hora).toLocaleTimeString('es-CO', {
    hour: 'numeric',
    minute: '2-digit',
    timeZone: ZONA,
  });

const textoFechaCompleta = (d) =>
  d.toLocaleString('es-CO', { dateStyle: 'full', timeStyle: 'short', timeZone: ZONA });

const textoFechaLarga = (d) =>
  d.toLocaleString('es-CO', { dateStyle: 'long', timeStyle: 'short', timeZone: ZONA });

// ───────── Cupos de un día ─────────
export async function cuposDelDia(fecha) {
  if (!fechaValida(fecha)) {
    return { ok: false, error: 'Fecha inválida. Usa el formato AAAA-MM-DD.' };
  }

  const limite = Date.now() + MINUTOS_MINIMOS * 60000;
  const horasDisponibles = [];
  const horasSinCupo = [];

  for (const hora of horasDelDia(fecha)) {
    const f = fechaHoraColombia(fecha, hora);
    if (f.getTime() <= limite) continue; // ya pasó o es muy pronto
    const ocupadas = await contarCitasEnHora(f);
    const item = { hora, texto: textoHora(fecha, hora) };
    if (ocupadas >= LIMITE_POR_HORA) horasSinCupo.push(item);
    else horasDisponibles.push(item);
  }

  return {
    ok: true,
    fecha,
    dia: nombreDia(fecha),
    horasDisponibles,
    horasSinCupo,
  };
}

// ───────── Validación completa de una cita ─────────
export async function validarCita(usuarioId, datos = {}) {
  const { vehiculoId, servicioId } = datos;
  const fecha = String(datos.fecha || '').trim();
  const hora = Number(datos.hora);
  const modalidad = datos.modalidad === 'domicilio' ? 'domicilio' : 'presencial';
  const direccion = String(datos.direccion || '').trim().slice(0, 200);
  const notas = String(datos.notas || '').trim().slice(0, 500);

  if (!mongoose.isValidObjectId(vehiculoId) || !mongoose.isValidObjectId(servicioId)) {
    return { ok: false, status: 400, error: 'Falta elegir el vehículo y el servicio.' };
  }

  // El vehículo debe ser del cliente que está agendando
  const [vehiculo, servicio] = await Promise.all([
    Vehicle.findOne({ _id: vehiculoId, usuarioId }).lean(),
    Service.findById(servicioId).lean(),
  ]);

  if (!vehiculo) {
    return { ok: false, status: 400, error: 'Ese vehículo no está registrado en tu cuenta.' };
  }
  if (!servicio) {
    return { ok: false, status: 400, error: 'El servicio indicado no existe.' };
  }

  // El precio sale del servicio según el tipo de vehículo; nunca del cliente
  const tarifa = (servicio.precios || []).find(
    (p) => p.tipoVehiculo === vehiculo.tipoVehiculo
  );
  if (!tarifa) {
    return {
      ok: false,
      status: 400,
      error: 'Ese servicio no tiene precio para el tipo de tu vehículo.',
    };
  }

  if (!fechaValida(fecha)) {
    return { ok: false, status: 400, error: 'La fecha no es válida.' };
  }

  const permitidas = horasDelDia(fecha);
  if (!Number.isInteger(hora) || !permitidas.includes(hora)) {
    return {
      ok: false,
      status: 400,
      error: `Esa hora no se puede agendar ese día. Horas disponibles del día: ${permitidas
        .map((h) => textoHora(fecha, h))
        .join(', ')}.`,
    };
  }

  const fechaHora = fechaHoraColombia(fecha, hora);
  const ahora = Date.now();
  if (fechaHora.getTime() <= ahora + MINUTOS_MINIMOS * 60000) {
    return { ok: false, status: 400, error: 'Esa hora ya pasó o es demasiado pronto.' };
  }
  if (fechaHora.getTime() > ahora + DIAS_MAXIMOS * 86400000) {
    return {
      ok: false,
      status: 400,
      error: `Solo se puede agendar hasta con ${DIAS_MAXIMOS} días de anticipación.`,
    };
  }

  if (modalidad === 'domicilio' && direccion.length < 5) {
    return { ok: false, status: 400, error: 'Para el servicio a domicilio falta la dirección.' };
  }

  const textoPago = sinTildes(datos.metodoPago);
  const metodo = METODOS_PAGO.find((m) => m.patron.test(textoPago));
  if (!metodo) {
    return {
      ok: false,
      status: 400,
      error: 'Falta indicar cómo pagarás: efectivo, transferencia (Nequi o Daviplata) o tarjeta.',
    };
  }

  const ocupadas = await contarCitasEnHora(fechaHora);
  if (ocupadas >= LIMITE_POR_HORA) {
    return {
      ok: false,
      status: 409,
      error: 'Esa hora ya no tiene cupos disponibles. Elige otro horario.',
    };
  }

  return {
    ok: true,
    vehiculo,
    servicio,
    tarifa,
    fechaHora,
    modalidad,
    direccion,
    notas,
    metodo,
    // Datos limpios que la app reenvía al confirmar
    normalizado: {
      vehiculoId: String(vehiculo._id),
      servicioId: String(servicio._id),
      fecha,
      hora,
      modalidad,
      direccion,
      metodoPago: metodo.clave,
      notas,
    },
  };
}

// ───────── Textos para mostrar al cliente ─────────
export function resumenCita(r) {
  const lineas = [
    'Este es el resumen de tu cita:',
    `• Servicio: ${nombreServicio(r.servicio)}`,
    `• Vehículo: ${describirVehiculo(r.vehiculo)}`,
    `• Fecha y hora: ${textoFechaCompleta(r.fechaHora)}`,
    `• Lugar: ${r.modalidad === 'domicilio' ? `A domicilio (${r.direccion})` : 'En el spa'}`,
    `• Precio: $${Number(r.tarifa.precio).toLocaleString('es-CO')} COP`,
    `• Pago previsto: ${r.metodo.texto} (el pago se realiza al finalizar el servicio)`,
  ];
  if (r.notas) lineas.push(`• Notas: ${r.notas}`);
  return lineas.join('\n');
}

// Versión corta y natural para leer en voz alta
export function resumenVoz(r) {
  const cuando = r.fechaHora.toLocaleString('es-CO', {
    weekday: 'long',
    day: 'numeric',
    month: 'long',
    hour: 'numeric',
    minute: '2-digit',
    timeZone: ZONA,
  });
  const lugar = r.modalidad === 'domicilio' ? 'a domicilio' : 'en el spa';
  return (
    `Voy a agendar ${nombreServicio(r.servicio)} para ${describirVehiculo(r.vehiculo)}, ` +
    `el ${cuando}, ${lugar}, por ${Number(r.tarifa.precio)} pesos. ¿Confirmas?`
  );
}

// ───────── Crear la cita ─────────
export async function crearCitaDesdeDatos(usuarioId, datos, { io, correo } = {}) {
  const r = await validarCita(usuarioId, datos);
  if (!r.ok) return r;

  const usuario = await User.findById(usuarioId).select('celular telefono').lean();
  const telefono = String((usuario && (usuario.celular || usuario.telefono)) || '')
    .trim()
    .slice(0, 20);

  const cita = new Appointment({
    usuarioId,
    vehiculoId: r.vehiculo._id,
    servicioId: r.servicio._id,
    tipoVehiculo: r.vehiculo.tipoVehiculo,
    precio: r.tarifa.precio,
    fechaHoraCita: r.fechaHora,
    tiempoEstimadoMinutos: duracionServicio(r.servicio),
    modalidad: r.modalidad,
    detallesDomicilio: {
      direccion: r.modalidad === 'domicilio' ? r.direccion : '',
      telefonoContacto: telefono,
    },
    metodoPago: r.metodo.texto,
    especificaciones: r.notas,
  });
  await cita.save();

  const fechaLarga = textoFechaLarga(r.fechaHora);

  // Notificación guardada (la campana y el push salen de aquí)
  await crearNotificacion(
    {
      usuarioId: cita.usuarioId,
      citaId: cita._id,
      tipo: 'cita_creada',
      titulo: '🚗 Cita agendada',
      mensaje: `Tu cita quedó agendada para el ${fechaLarga}.`,
    },
    io
  );

  if (correo) {
    sendEmail({
      to: correo,
      subject: '🚗 Confirmación de Cita - SPA Vehicular',
      html: `
        <div style="font-family: Arial, sans-serif; padding: 20px; border: 1px solid #e2e8f0; border-radius: 8px;">
          <h2 style="color: #2b6cb0;">¡Tu cita ha sido agendada con éxito!</h2>
          <p>Hola, hemos registrado tu solicitud de servicio en <b>SPA Vehicular</b>.</p>
          <hr style="border: 0; border-top: 1px solid #eee;" />
          <p><b>📅 Fecha y Hora:</b> ${fechaLarga}</p>
          <p><b>💰 Precio:</b> $${Number(cita.precio).toLocaleString('es-CO')}</p>
          <p><b>📌 Estado:</b> ${cita.estado || 'Pendiente'}</p>
          <br/>
          <p>¡Gracias por confiar en nosotros! Te esperamos a tiempo.</p>
        </div>
      `,
    }).catch((err) =>
      console.error('⚠️ No se pudo enviar el correo de la cita (chat):', err.message)
    );
  }

  return {
    ok: true,
    cita,
    texto:
      `✅ ¡Listo! Tu cita de ${nombreServicio(r.servicio)} quedó agendada para el ${fechaLarga}. ` +
      'Te llegará un aviso y un correo de confirmación. Puedes verla en la pestaña "Lavadas".',
  };
}