import Payment from '../models/Payment.js';
import Appointment from '../models/Appointment.js';
import { crearNotificacion } from '../utils/notificaciones.js';

const METODOS_VALIDOS = ['efectivo', 'transferencia', 'nequi', 'daviplata', 'tarjeta'];

// 1. Registrar pago (lo hace el administrador al entregar el vehículo)
export const registrarPago = async (req, res) => {
  try {
    const { citaId, monto, metodoPago, referencia, comprobanteUrl } = req.body;

    if (!METODOS_VALIDOS.includes(metodoPago)) {
      return res.status(400).json({ mensaje: `Método de pago inválido: ${metodoPago}` });
    }

    const cita = await Appointment.findById(citaId);
    if (!cita) {
      return res.status(404).json({ mensaje: 'Cita no encontrada' });
    }

    if (cita.estado === 'cancelada') {
      return res.status(400).json({ mensaje: 'No se puede registrar un pago en una cita cancelada' });
    }

    if (cita.estadoPago === 'pagado') {
      return res.status(409).json({ mensaje: 'Esta cita ya tiene un pago registrado' });
    }

    // Si el admin no envía monto, se usa el precio guardado en la cita
    const montoFinal = monto !== undefined && monto !== null && monto !== '' ? Number(monto) : cita.precio;
    if (!Number.isFinite(montoFinal) || montoFinal < 0) {
      return res.status(400).json({ mensaje: 'El monto no es válido' });
    }

    const pago = await Payment.create({
      citaId: cita._id,
      usuarioId: cita.usuarioId,
      monto: montoFinal,
      metodoPago,
      referencia: String(referencia || '').trim().slice(0, 100),
      comprobanteUrl: String(comprobanteUrl || '').trim(),
      registradoPor: req.user && (req.user.id || req.user._id)
    });

    cita.estadoPago = 'pagado';
    await cita.save();

    await crearNotificacion(
      {
        usuarioId: cita.usuarioId,
        citaId: cita._id,
        tipo: 'pago_registrado',
        titulo: '💰 Pago recibido',
        mensaje: `Registramos tu pago de $${Number(montoFinal).toLocaleString('es-CO')} (${metodoPago}). ¡Gracias!`
      },
      req.io
    );

    // 🔒 El aviso con los datos del pago solo llega a los administradores conectados
    if (req.io) {
      req.io.to('admins').emit('pago_registrado', { citaId: cita._id, pago });
    }

    res.status(201).json({ mensaje: 'Pago registrado correctamente', pago, cita });
  } catch (error) {
    if (error.code === 11000) {
      return res.status(409).json({ mensaje: 'Esta cita ya tiene un pago registrado' });
    }
    console.error('Error en registrarPago:', error);
    res.status(500).json({ mensaje: 'Error al registrar el pago', error: error.message });
  }
};

// 2. Listar todos los pagos (Panel Admin)
export const obtenerPagos = async (req, res) => {
  try {
    const pagos = await Payment.find()
      .populate('usuarioId', 'nombres Nombre apellidos Apellido')
      .populate({
        path: 'citaId',
        populate: [{ path: 'servicioId' }, { path: 'vehiculoId' }]
      })
      .sort({ fechaPago: -1 })
      .lean();

    res.status(200).json(pagos);
  } catch (error) {
    console.error('Error en obtenerPagos:', error);
    res.status(500).json({ mensaje: 'Error al obtener los pagos', error: error.message });
  }
};

// 3. Obtener el pago de una cita
export const obtenerPagoPorCita = async (req, res) => {
  try {
    const { citaId } = req.params;
    const pago = await Payment.findOne({ citaId }).lean();

    if (!pago) {
      return res.status(404).json({ mensaje: 'Esta cita aún no tiene pago registrado' });
    }

    res.status(200).json(pago);
  } catch (error) {
    console.error('Error en obtenerPagoPorCita:', error);
    res.status(500).json({ mensaje: 'Error al obtener el pago', error: error.message });
  }
};

// ───────────────────────────────────────────────────────────────
// 4. Resumen de pagos para el panel de reportes (solo admin)
// Los rangos (hoy, semana, mes) se calculan con la hora de Colombia (UTC-5, sin horario de verano).
// ───────────────────────────────────────────────────────────────
const OFFSET_COLOMBIA_MS = -5 * 60 * 60 * 1000;
const MS_DIA = 24 * 60 * 60 * 1000;

const inicioDelDiaColombia = (fecha = new Date()) => {
  const local = new Date(fecha.getTime() + OFFSET_COLOMBIA_MS);
  local.setUTCHours(0, 0, 0, 0);
  return new Date(local.getTime() - OFFSET_COLOMBIA_MS);
};

const inicioDeSemanaColombia = (fecha = new Date()) => {
  const inicioHoy = inicioDelDiaColombia(fecha);
  const local = new Date(fecha.getTime() + OFFSET_COLOMBIA_MS);
  const diasDesdeLunes = (local.getUTCDay() + 6) % 7; // lunes = 0
  return new Date(inicioHoy.getTime() - diasDesdeLunes * MS_DIA);
};

const inicioDeMesColombia = (fecha = new Date()) => {
  const local = new Date(fecha.getTime() + OFFSET_COLOMBIA_MS);
  return new Date(Date.UTC(local.getUTCFullYear(), local.getUTCMonth(), 1) - OFFSET_COLOMBIA_MS);
};

const resumenDesde = async (desde) => {
  const filas = await Payment.aggregate([
    { $match: { fechaPago: { $gte: desde } } },
    { $group: { _id: '$metodoPago', total: { $sum: '$monto' }, cantidad: { $sum: 1 } } }
  ]);

  const porMetodo = {};
  let total = 0;
  let cantidad = 0;
  for (const fila of filas) {
    porMetodo[fila._id] = { total: fila.total, cantidad: fila.cantidad };
    total += fila.total;
    cantidad += fila.cantidad;
  }

  return { total, cantidad, porMetodo };
};

export const obtenerResumen = async (req, res) => {
  try {
    const ahora = new Date();

    const [hoy, semana, mes, pendientesFilas] = await Promise.all([
      resumenDesde(inicioDelDiaColombia(ahora)),
      resumenDesde(inicioDeSemanaColombia(ahora)),
      resumenDesde(inicioDeMesColombia(ahora)),
      // Citas con el lavado terminado que todavía no se han cobrado
      Appointment.aggregate([
        { $match: { estado: 'finalizada', estadoPago: { $ne: 'pagado' } } },
        { $group: { _id: null, total: { $sum: { $ifNull: ['$precio', 0] } }, cantidad: { $sum: 1 } } }
      ])
    ]);

    const pendientes = pendientesFilas[0]
      ? { total: pendientesFilas[0].total, cantidad: pendientesFilas[0].cantidad }
      : { total: 0, cantidad: 0 };

    res.status(200).json({ hoy, semana, mes, pendientes });
  } catch (error) {
    console.error('Error en obtenerResumen:', error);
    res.status(500).json({ mensaje: 'Error al obtener el resumen de pagos', error: error.message });
  }
};

export default {
  registrarPago,
  obtenerPagos,
  obtenerPagoPorCita,
  obtenerResumen
};