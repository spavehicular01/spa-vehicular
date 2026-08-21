const express = require('express');
const router = express.Router();
const appointmentController = require('../controllers/appointmentController');

// Obtener todas las citas (Admin)
router.get('/', appointmentController.obtenerTodasLasCitas);

// Obtener citas por cliente (App Móvil Flutter)
router.get('/usuario/:usuarioId', appointmentController.obtenerCitasPorUsuario);

// Crear cita
router.post('/', appointmentController.crearCita);

// Cambiar estado
router.put('/estado/:citaId', appointmentController.cambiarEstadoCita);

// Reprogramar
router.put('/reprogramar/:citaId', appointmentController.reprogramarCita);

module.exports = router;