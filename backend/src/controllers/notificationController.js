import Notification from '../models/Notification.js';

const esAdminReq = (req) => String((req.user && req.user.rol) || '').toLowerCase() === 'admin';
const idDeSesion = (req) => String((req.user && (req.user.id || req.user._id)) || '');

// 1. Notificaciones de un usuario (App Móvil). La ruta ya verifica que sea el dueño o un admin.
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

// 2. Marcar una notificación como leída (solo su dueño o un admin)
export const marcarComoLeida = async (req, res) => {
  try {
    const { notificacionId } = req.params;

    const notificacion = await Notification.findById(notificacionId);

    if (!notificacion) {
      return res.status(404).json({ mensaje: 'Notificación no encontrada' });
    }

    if (!esAdminReq(req) && String(notificacion.usuarioId) !== idDeSesion(req)) {
      return res.status(403).json({ mensaje: 'No puedes modificar una notificación que no es tuya' });
    }

    notificacion.leida = true;
    await notificacion.save();

    res.status(200).json(notificacion);
  } catch (error) {
    console.error('Error en marcarComoLeida:', error);
    res.status(500).json({ mensaje: 'Error al actualizar la notificación', error: error.message });
  }
};

// 3. Marcar todas las de un usuario como leídas (la ruta verifica dueño o admin)
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