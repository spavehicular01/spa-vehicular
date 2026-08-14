const mongoose = require('mongoose');

const serviceSchema = new mongoose.Schema({
  nombreServicio: { type: String, required: true },
  descripcion: { type: String, required: true },
  precios: [{
    tipoVehiculo: { type: String, enum: ['moto', 'automovil', 'SUV', 'camioneta'], required: true },
    precio: { type: Number, required: true }
  }],
  duracionEstimadaMinutos: { type: Number, required: true },
  activo: { type: Boolean, default: true }
});

module.exports = mongoose.model('Service', serviceSchema);