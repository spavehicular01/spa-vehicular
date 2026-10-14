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

    if (req.io) {
      req.io.emit('pago_registrado', { citaId: cita._id, pago });
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

export default {
  registrarPago,
  obtenerPagos,
  obtenerPagoPorCita
};