import Notification from '../models/Notification.js';

// 1. Notificaciones de un usuario (App Móvil)
export const obtenerNotificacionesPorUsuario = async (req, res) => {
  try {
    const { usuarioId } = req.params;

    const notificaciones = await Notification.find({ usuarioId })
      .sort({ fecha: -1 })
      .limit(100)
      .lean();

    res.status(200).json(notificaciones);
  } catch (error) {
    console.error('Error en obtenerNotificacionesPorUsuario:', error);
    res.status(500).json({ mensaje: 'Error al obtener notificaciones', error: error.message });
  }
};

// 2. Marcar una notificación como leída
export const marcarComoLeida = async (req, res) => {
  try {
    const { notificacionId } = req.params;

    const notificacion = await Notification.findByIdAndUpdate(
      notificacionId,
      { leida: true },
      { new: true }
    );

    if (!notificacion) {
      return res.status(404).json({ mensaje: 'Notificación no encontrada' });
    }

    res.status(200).json(notificacion);
  } catch (error) {
    console.error('Error en marcarComoLeida:', error);
    res.status(500).json({ mensaje: 'Error al actualizar la notificación', error: error.message });
  }
};

// 3. Marcar todas las de un usuario como leídas
export const marcarTodasComoLeidas = async (req, res) => {
  try {
    const { usuarioId } = req.params;

    await Notification.updateMany({ usuarioId, leida: false }, { leida: true });

    res.status(200).json({ mensaje: 'Notificaciones marcadas como leídas' });
  } catch (error) {
    console.error('Error en marcarTodasComoLeidas:', error);
    res.status(500).json({ mensaje: 'Error al actualizar las notificaciones', error: error.message });
  }
};

export default {
  obtenerNotificacionesPorUsuario,
  marcarComoLeida,
  marcarTodasComoLeidas
};