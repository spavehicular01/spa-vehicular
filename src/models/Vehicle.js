const mongoose = require('mongoose');

const vehicleSchema = new mongoose.Schema({
  usuarioId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
  placa: { type: String, required: true, unique: true },
  marca: { type: String, required: true },
  referencia: { type: String, required: true },
  modelo: { type: String, required: true },
  tipoVehiculo: { 
    type: String, 
    enum: ['moto', 'automovil', 'SUV', 'camioneta'], 
    required: true 
  }
});

module.exports = mongoose.model('Vehicle', vehicleSchema);