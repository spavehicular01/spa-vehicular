const mongoose = require('mongoose');

const opinionSchema = new mongoose.Schema(
  {
    // Un usuario tiene una sola opinión (puede editarla). Evita spam.
    usuarioId: {
      type: mongoose.Schema.Types.ObjectId,
      required: true,
      unique: true,
    },
    // Nombre corto para mostrar, ej. "Carlos M."
    nombre: { type: String, required: true, trim: true },
    estrellas: { type: Number, required: true, min: 1, max: 5 },
    texto: {
      type: String,
      required: true,
      trim: true,
      minlength: 5,
      maxlength: 300,
    },
    // Moderación: ponlo en false desde MongoDB Atlas para ocultar una opinión.
    visible: { type: Boolean, default: true },
  },
  { timestamps: true }
);

module.exports = mongoose.model('Opinion', opinionSchema);