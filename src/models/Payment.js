const mongoose = require('mongoose');

const paymentSchema = new mongoose.Schema({
  citaId: { type: mongoose.Schema.Types.ObjectId, ref: 'Appointment', required: true, unique: true },
  monto: { type: Number, required: true },
  metodoPago: { 
    type: String, 
    enum: ['efectivo', 'nequi', 'tarjeta_debito', 'daviplata'], 
    required: true 
  },
  comprobanteUrl: { type: String, default: '' },
  estadoPago: { type: String, enum: ['pendiente', 'aprobado', 'rechazado'], default: 'pendiente' },
  fechaPago: { type: Date, default: Date.now }
});

module.exports = mongoose.model('Payment', paymentSchema);