import mongoose from 'mongoose';

const notificationSchema = new mongoose.Schema({
  usuarioId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true, index: true },
  citaId: { type: mongoose.Schema.Types.ObjectId, ref: 'Appointment' },
  tipo: {
    type: String,
    enum: ['cita_creada', 'cita_reprogramada', 'cambio_estado', 'pago_registrado'],
    required: true
  },
  titulo: { type: String, required: true, trim: true, maxlength: 120 },
  mensaje: { type: String, required: true, trim: true, maxlength: 500 },
  leida: { type: Boolean, default: false },
  fecha: { type: Date, default: Date.now }
});

const Notification = mongoose.model('Notification', notificationSchema);

export default Notification;