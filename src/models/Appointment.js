import mongoose from 'mongoose';
import { TIPOS_VEHICULO } from '../utils/vehicleTypes.js';

const appointmentSchema = new mongoose.Schema({
  usuarioId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
  vehiculoId: { type: mongoose.Schema.Types.ObjectId, ref: 'Vehicle', required: true },
  servicioId: { type: mongoose.Schema.Types.ObjectId, ref: 'Service', required: true },
  // Se guardan al agendar: así la cita conserva el precio acordado aunque
  // luego cambie la tarifa del servicio o el tipo del vehículo.
  tipoVehiculo: { type: String, enum: TIPOS_VEHICULO },
  precio: { type: Number, min: 0 },
  fechaHoraCita: { type: Date, required: true },
  tiempoEstimadoMinutos: { type: Number, required: true },
  modalidad: { type: String, enum: ['presencial', 'domicilio'], default: 'presencial' },
  detallesDomicilio: {
    direccion: { type: String, default: '' },
    telefonoContacto: { type: String, default: '' }
  },
  metodoPago: { type: String, trim: true, maxlength: 40, default: '' },
  especificaciones: { type: String, trim: true, maxlength: 500, default: '' },
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

const Appointment = mongoose.model('Appointment', appointmentSchema);

export default Appointment;