import Notification from '../models/Notification.js';
import { enviarPush } from '../services/pushService.js';

// Guarda una notificación en la base de datos y se la avisa en tiempo real SOLO a su dueño
// (sala "usuario:<id>" del WebSocket). Nunca lanza error: si falla, solo se registra en
// consola para no romper la operación principal.
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
      io.to(`usuario:${String(usuarioId)}`).emit('nueva_notificacion', notificacion);
    }

    // Notificación push al celular (no se espera: no debe frenar la operación principal)
    enviarPush(usuarioId, {
      titulo,
      mensaje,
      datos: {
        tipo,
        citaId: citaId ? String(citaId) : '',
        notificacionId: String(notificacion._id)
      }
    });

    return notificacion;
  } catch (error) {
    console.error('⚠️ No se pudo guardar la notificación:', error.message);
    return null;
  }
};

// Emite un evento en tiempo real solo al dueño de la cita y a los administradores conectados.
export const emitirAUsuarioYAdmins = (io, usuarioId, evento, payload) => {
  if (!io) return;

  let destino = io.to('admins');
  if (usuarioId) {
    destino = destino.to(`usuario:${String(usuarioId)}`);
  }
  destino.emit(evento, payload);
};

export default { crearNotificacion, emitirAUsuarioYAdmins };