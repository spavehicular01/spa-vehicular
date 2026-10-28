import mongoose from 'mongoose';
import Review from '../models/Review.js';

const idDelToken = (req) =>
  String(req.user?.id || req.user?._id || req.user?.userId || '');

// "Carlos Andrés" + "Mendoza Ruiz" -> "Carlos M."
const nombreCorto = (nombres = '', apellidos = '') => {
  const primerNombre = String(nombres).trim().split(/\s+/)[0] || 'Cliente';
  const inicial = String(apellidos).trim().charAt(0).toUpperCase();
  return inicial ? `${primerNombre} ${inicial}.` : primerNombre;
};

// GET /api/reviews  (público) — las más recientes primero
export const listarOpiniones = async (req, res) => {
  try {
    const opiniones = await Review.find()
      .sort({ updatedAt: -1 })
      .limit(30)
      .select('nombre calificacion comentario updatedAt');

    const total = opiniones.length;
    const promedio = total
      ? Number((opiniones.reduce((s, o) => s + o.calificacion, 0) / total).toFixed(1))
      : 0;

    res.json({ ok: true, promedio, total, opiniones });
  } catch (error) {
    console.error('Error en listarOpiniones:', error);
    res.status(500).json({ ok: false, mensaje: 'No se pudieron cargar las opiniones' });
  }
};

// GET /api/reviews/mia  — la opinión del usuario con sesión (o null)
export const obtenerMiOpinion = async (req, res) => {
  try {
    const opinion = await Review.findOne({ usuarioId: idDelToken(req) });
    res.json({ ok: true, opinion });
  } catch (error) {
    console.error('Error en obtenerMiOpinion:', error);
    res.status(500).json({ ok: false, mensaje: 'No se pudo cargar tu opinión' });
  }
};

// POST /api/reviews  — crea o actualiza la opinión del usuario con sesión
export const guardarOpinion = async (req, res) => {
  try {
    const usuarioId = idDelToken(req);
    if (!usuarioId) {
      return res.status(401).json({ ok: false, mensaje: 'Usuario no autenticado' });
    }

    const calificacion = Number(req.body.calificacion);
    if (!Number.isInteger(calificacion) || calificacion < 1 || calificacion > 5) {
      return res
        .status(400)
        .json({ ok: false, mensaje: 'La calificación debe ser de 1 a 5 estrellas' });
    }

    const comentario = String(req.body.comentario || '').trim().slice(0, 300);

    // El nombre sale de la cuenta, nunca de lo que mande la app
    const usuario = await mongoose.model('User').findById(usuarioId);
    if (!usuario) {
      return res.status(404).json({ ok: false, mensaje: 'Usuario no encontrado' });
    }
    const nombre = nombreCorto(usuario.nombres, usuario.apellidos);

    const opinion = await Review.findOneAndUpdate(
      { usuarioId },
      { usuarioId, nombre, calificacion, comentario },
      { new: true, upsert: true, runValidators: true, setDefaultsOnInsert: true }
    );

    res.status(201).json({ ok: true, mensaje: 'Gracias por tu opinión', opinion });
  } catch (error) {
    console.error('Error en guardarOpinion:', error);
    res.status(500).json({ ok: false, mensaje: 'No se pudo guardar tu opinión' });
  }
};

// DELETE /api/reviews/:id  — el dueño o un administrador
export const eliminarOpinion = async (req, res) => {
  try {
    const opinion = await Review.findById(req.params.id);
    if (!opinion) {
      return res.status(404).json({ ok: false, mensaje: 'Opinión no encontrada' });
    }

    const esDueno = String(opinion.usuarioId) === idDelToken(req);
    const esAdministrador = String(req.user?.rol || '').toLowerCase() === 'admin';
    if (!esDueno && !esAdministrador) {
      return res.status(403).json({ ok: false, mensaje: 'No puedes borrar esta opinión' });
    }

    await opinion.deleteOne();
    res.json({ ok: true, mensaje: 'Opinión eliminada' });
  } catch (error) {
    console.error('Error en eliminarOpinion:', error);
    res.status(500).json({ ok: false, mensaje: 'No se pudo eliminar la opinión' });
  }
};