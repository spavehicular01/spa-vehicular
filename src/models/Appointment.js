const mongoose = require('mongoose');

const appointmentSchema = new mongoose.Schema({
  usuarioId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
  vehiculoId: { type: mongoose.Schema.Types.ObjectId, ref: 'Vehicle', required: true },
  servicioId: { type: mongoose.Schema.Types.ObjectId, ref: 'Service', required: true },
  fechaHoraCita: { type: Date, required: true },
  tiempoEstimadoMinutos: { type: Number, required: true },
  modalidad: { type: String, enum: ['presencial', 'domicilio'], default: 'presencial' },
  detallesDomicilio: {
    direccion: { type: String, default: '' },
    telefonoContacto: { type: String, default: '' }
  },
  estado: { 
    type: String, 
    enum: ['pendiente', 'confirmada', 'en_proceso', 'finalizada', 'cancelada', 'reprogramada'], 
    default: 'pendiente' 
  },
  historialReprogramaciones: [{
    motivo: String,
    fechaAnterior: Date,
    fechaNueva: Date,
    fechaAccion: { type: Date, default: Date.now }
  }],
  fechaCreacion: { type: Date, default: Date.now }
});

module.exports = mongoose.model('Appointment', appointmentSchema);