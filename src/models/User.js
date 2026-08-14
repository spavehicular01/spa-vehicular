const mongoose = require('mongoose');

const userSchema = new mongoose.Schema({
  nombres: { type: String, required: true },
  apellidos: { type: String, required: true },
  documentoIdentidad: { type: String, required: true, unique: true },
  correo: { type: String, required: true, unique: true },
  celular: { type: String, required: true },
  password: { type: String, required: true },
  rol: { 
    type: String, 
    enum: ['cliente', 'administrador', 'operario'], 
    default: 'cliente' 
  },
  direccionPrincipal: { type: String, default: '' },
  fechaRegistro: { type: Date, default: Date.now }
});

module.exports = mongoose.model('User', userSchema);