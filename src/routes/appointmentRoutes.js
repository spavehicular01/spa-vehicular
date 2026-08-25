const express = require('express');
const router = express.Router();
const appointmentController = require('../controllers/appointmentController');

const authMiddleware = require('../middlewares/authMiddleware');
const verifyToken = authMiddleware.verifyToken || authMiddleware;

// ==========================================
// RUTAS DE CONSULTA (GET)
// ==========================================

// Obtener todas las citas
router.get('/', verifyToken, appointmentController.obtenerTodasLasCitas || appointmentController.obtenerCitas);

// Obtener citas por cliente específico (App Flutter)
router.get('/usuario/:usuarioId', verifyToken, appointmentController.obtenerCitasPorUsuario);

// ==========================================
// RUTAS DE CREACIÓN Y EDICIÓN (POST / PUT / PATCH)
// ==========================================

// Crear nueva cita
router.post('/crear', verifyToken, appointmentController.crearCita);

// Reprogramar cita
router.put('/reprogramar/:citaId', verifyToken, appointmentController.reprogramarCita);

// Cambiar estado de la cita
router.put('/estado/:citaId', verifyToken, appointmentController.cambiarEstadoCita);
router.patch('/cambiar-estado/:citaId', verifyToken, appointmentController.cambiarEstadoCita);

module.exports = router;