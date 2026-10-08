import mongoose from 'mongoose';
import { TIPOS_VEHICULO } from '../utils/vehicleTypes.js';

const vehicleSchema = new mongoose.Schema({
  usuarioId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
  placa: { type: String, required: true, unique: true },
  marca: { type: String, required: true },
  referencia: { type: String, required: true },
  modelo: { type: String, required: true },
  tipoVehiculo: { type: String, required: true, enum: TIPOS_VEHICULO },
  imagenUrl: { type: String, default: '' }
}, {
  timestamps: true
});

const Vehicle = mongoose.model('Vehicle', vehicleSchema);

export default Vehicle;