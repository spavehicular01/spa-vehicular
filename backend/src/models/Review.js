import mongoose from 'mongoose';

// Una opinión por usuario: si vuelve a opinar, se actualiza la que ya tenía.
const reviewSchema = new mongoose.Schema(
  {
    usuarioId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true,
      unique: true
    },
    // Nombre para mostrar (ej. "Carlos M."), se arma en el servidor
    nombre: { type: String, required: true, trim: true, maxlength: 60 },
    calificacion: { type: Number, required: true, min: 1, max: 5 },
    comentario: { type: String, trim: true, maxlength: 300, default: '' }
  },
  { timestamps: true }
);

const Review = mongoose.model('Review', reviewSchema);

export default Review;