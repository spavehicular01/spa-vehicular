import express from 'express';
import upload from '../middlewares/upload.js';
import { verifyToken } from '../middlewares/authMiddleware.js';

const router = express.Router();

// POST /api/upload
// Requiere sesión iniciada: antes cualquiera podía subir imágenes a Cloudinary sin registrarse.
router.post('/', verifyToken, upload.single('image'), (req, res) => {
  try {
    if (!req.file) {
      return res.status(400).json({ mensaje: 'No se ha proporcionado ninguna imagen.' });
    }
    // Retorna la URL generada por Cloudinary
    res.status(200).json({ url: req.file.path });
  } catch (error) {
    res.status(500).json({ mensaje: 'Error al subir la imagen', error: error.message });
  }
});

export default router;