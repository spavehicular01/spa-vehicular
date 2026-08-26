const mongoose = require('mongoose');

const usuarioSchema = new mongoose.Schema({
  nombres: { type: String, required: true },
  correo: { type: String, required: true, unique: true },
  password: { type: String, required: true },
  rol: { type: String, enum: ['cliente', 'admin'], default: 'cliente' },
  documento: { type: String },
  telefono: { type: String },
  codigoRecuperacion: {
    codigo: { type: String, default: null },
    expiracion: { type: Date, default: null }
  }
}, { timestamps: true });

module.exports = mongoose.model('User', usuarioSchema);