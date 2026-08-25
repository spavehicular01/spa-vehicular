const express = require('express');
const router = express.Router();
const Cita = require('../models/Cita');

// Actualizar el estado de una cita (Admin)
router.put('/:id/estado', async (req, res) => {
  try {
    const { estado } = req.body;
    const { id } = req.params;

    const citaActualizada = await Cita.findByIdAndUpdate(
      id,
      { estado },
      { new: true }
    );

    if (!citaActualizada) {
      return res.status(404).json({ mensaje: 'Cita no encontrada' });
    }

    // Aquí se invoca el envío de notificación push/socket si está configurado
    res.json({
      mensaje: `Estado actualizado a ${estado}`,
      cita: citaActualizada
    });
  } catch (error) {
    res.status(500).json({ error: 'Error al actualizar el estado de la cita' });
  }
});

module.exports = router;