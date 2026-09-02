import mongoose from 'mongoose';

const vehicleSchema = new mongoose.Schema({
  usuarioId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
  placa: { type: String, required: true, unique: true },
  marca: { type: String, required: true },
  referencia: { type: String, required: true },
  modelo: { type: String, required: true },
  tipoVehiculo: { type: String, required: true }
}, {
  timestamps: true
});

const Vehicle = mongoose.model('Vehicle', vehicleSchema);

export default Vehicle;