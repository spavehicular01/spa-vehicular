const express = require('express');
const router = express.Router();
const appointmentController = require('../controllers/appointmentController');

// 1. Obtener todas las citas (Para Panel Admin)
// GET /api/appointments
router.get('/', appointmentController.obtenerTodasLasCitas);

// 2. Obtener citas por ID de usuario (Para App Móvil Flutter)
// GET /api/appointments/usuario/:usuarioId
router.get('/usuario/:usuarioId', appointmentController.obtenerCitasPorUsuario);

// 3. Crear una nueva cita
// POST /api/appointments
router.post('/', appointmentController.crearCita);

// 4. Reprogramar una cita existente
// PUT /api/appointments/:citaId/reprogramar
router.put('/:citaId/reprogramar', appointmentController.reprogramarCita);

// 5. Cambiar el estado de una cita (Pendiente, En Proceso, Completado, Cancelado)
// PATCH /api/appointments/:citaId/estado
router.patch('/:citaId/estado', appointmentController.cambiarEstadoCita);

module.exports = router;