const express = require('express');
const router = express.Router();
const appointmentController = require('../controllers/appointmentController');

// Importamos el middleware (soportando ambas formas de exportación)
const authMiddleware = require('../middlewares/authMiddleware');
const verifyToken = authMiddleware.verifyToken || authMiddleware;

// Ruta para crear cita (protegida con JWT)
router.post('/crear', verifyToken, appointmentController.crearCita);

// Ruta para reprogramar cita (protegida con JWT)
router.put('/reprogramar/:citaId', verifyToken, appointmentController.reprogramarCita);

module.exports = router;