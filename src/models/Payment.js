import mongoose from 'mongoose';

// Pago REAL: lo registra el administrador cuando el cliente paga al recoger el vehículo.
// (El método que el cliente elige al agendar vive en Appointment.metodoPago y es solo "previsto".)
const paymentSchema = new mongoose.Schema({
  citaId: { type: mongoose.Schema.Types.ObjectId, ref: 'Appointment', required: true, unique: true },
  usuarioId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
  monto: { type: Number, required: true, min: 0 },
  metodoPago: {
    type: String,
    enum: ['efectivo', 'transferencia', 'nequi', 'daviplata', 'tarjeta'],
    required: true
  },
  referencia: { type: String, trim: true, maxlength: 100, default: '' },
  comprobanteUrl: { type: String, default: '' },
  registradoPor: { type: mongoose.Schema.Types.ObjectId, ref: 'User' },
  fechaPago: { type: Date, default: Date.now }
});

const Payment = mongoose.model('Payment', paymentSchema);

export default Payment;