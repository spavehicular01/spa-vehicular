import mongoose from 'mongoose';

// Identificador (token FCM) de cada celular donde un usuario tiene la app instalada.
// Con él el servidor puede enviarle notificaciones push aunque la app esté cerrada.
const deviceTokenSchema = new mongoose.Schema({
  usuarioId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true, index: true },
  // Un mismo celular solo puede estar a nombre de un usuario a la vez
  token: { type: String, required: true, unique: true },
  plataforma: { type: String, enum: ['android', 'ios', 'otro'], default: 'android' },
  actualizadoEn: { type: Date, default: Date.now }
});

const DeviceToken = mongoose.model('DeviceToken', deviceTokenSchema);

export default DeviceToken;