import Notification from '../models/Notification.js';

// Guarda una notificación en la base de datos. Nunca lanza error:
// si falla, solo se registra en consola para no romper la operación principal.
export const crearNotificacion = async ({ usuarioId, citaId, tipo, titulo, mensaje }, io) => {
  try {
    if (!usuarioId) return null;

    const notificacion = await Notification.create({
      usuarioId,
      citaId,
      tipo,
      titulo,
      mensaje
    });

    if (io) {
      io.emit('nueva_notificacion', notificacion);
    }

    return notificacion;
  } catch (error) {
    console.error('⚠️ No se pudo guardar la notificación:', error.message);
    return null;
  }
};

export default { crearNotificacion };