const express = require('express');
const router = express.Router();
const upload = require('../middlewares/upload');

// POST /api/upload
router.post('/', upload.single('image'), (req, res) => {
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

module.exports = router;