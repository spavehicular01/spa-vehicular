import mongoose from 'mongoose';
import { TIPOS_VEHICULO } from '../utils/vehicleTypes.js';

// Un precio por cada tipo de vehículo que aplique al servicio.
// Si un tipo no está en la lista, el servicio no se ofrece para ese vehículo.
const precioSchema = new mongoose.Schema({
  tipoVehiculo: { type: String, enum: TIPOS_VEHICULO, required: true },
  precio: { type: Number, required: true, min: 0 }
}, { _id: false });

const serviceSchema = new mongoose.Schema({
  nombreServicio: { type: String, required: true },
  descripcion: { type: String, default: '' },
  imagenUrl: { type: String, default: '' },
  precios: {
    type: [precioSchema],
    validate: {
      validator: (lista) => Array.isArray(lista) && lista.length > 0,
      message: 'El servicio debe tener el precio de al menos un tipo de vehículo'
    }
  },
  duracionEstimadaMinutos: { type: Number, required: true },
  activo: { type: Boolean, default: true }
});

const Service = mongoose.model('Service', serviceSchema);

export default Service;