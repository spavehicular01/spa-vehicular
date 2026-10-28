// src/utils/cupos.js
import Appointment from '../models/Appointment.js'; // ajusta la ruta/nombre a tu modelo

export const LIMITE_POR_HORA = 5;
export const ZONA_HORARIA = 'America/Bogota';

// Estados que ocupan cupo. Cancelada y finalizada no cuentan.
const ESTADOS_ACTIVOS = ['pendiente', 'confirmada', 'en_proceso', 'reprogramada'];

/**
 * Cuenta las citas activas dentro de la hora de `fechaHora`
 * (de HH:00:00 a HH:59:59). `excluirId` sirve al reprogramar,
 * para no contar la misma cita dos veces.
 */
export async function contarCitasEnHora(fechaHora, excluirId = null) {
  const inicio = new Date(fechaHora);
  inicio.setUTCMinutes(0, 0, 0); // Colombia (UTC-5) tiene horas enteras, no hay desfase
  const fin = new Date(inicio.getTime() + 60 * 60 * 1000);

  const filtro = {
    fechaHoraCita: { $gte: inicio, $lt: fin },
    estado: { $in: ESTADOS_ACTIVOS },
  };
  if (excluirId) filtro._id = { $ne: excluirId };

  return Appointment.countDocuments(filtro);
}

/**
 * GET /api/citas/cupos?fecha=2026-09-30
 * Responde: { limite: 5, horas: [{ hora: 8, ocupadas: 3, disponibles: 2, ocupado: false }] }
 * Solo devuelve las horas que ya tienen citas; las demás están libres.
 */
export async function obtenerCuposDelDia(req, res) {
  try {
    const { fecha } = req.query; // YYYY-MM-DD
    if (!/^\d{4}-\d{2}-\d{2}$/.test(fecha || '')) {
      return res.status(400).json({ mensaje: 'Usa el formato fecha=YYYY-MM-DD.' });
    }

    const inicioDia = new Date(`${fecha}T00:00:00-05:00`);
    const finDia = new Date(inicioDia.getTime() + 24 * 60 * 60 * 1000);

    const resultado = await Appointment.aggregate([
      {
        $match: {
          fechaHoraCita: { $gte: inicioDia, $lt: finDia },
          estado: { $in: ESTADOS_ACTIVOS },
        },
      },
      {
        $group: {
          _id: { $hour: { date: '$fechaHoraCita', timezone: ZONA_HORARIA } },
          ocupadas: { $sum: 1 },
        },
      },
      { $sort: { _id: 1 } },
    ]);

    const horas = resultado.map((r) => ({
      hora: r._id,
      ocupadas: r.ocupadas,
      disponibles: Math.max(LIMITE_POR_HORA - r.ocupadas, 0),
      ocupado: r.ocupadas >= LIMITE_POR_HORA,
    }));

    res.json({ limite: LIMITE_POR_HORA, horas });
  } catch (error) {
    res.status(500).json({ mensaje: 'Error al consultar los cupos.', error: error.message });
  }
}