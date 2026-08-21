const express = require('express');
const router = express.Router();
const appointmentController = require('../controllers/appointmentController');

// Importamos el middleware (soportando ambas formas de exportación)
const authMiddleware = require('../middlewares/authMiddleware');
const verifyToken = authMiddleware.verifyToken || authMiddleware;

// ==========================================
// RUTAS DE CONSULTA (GET)
// ==========================================

// 1. Obtener TODAS las citas (Para el panel Admin)
router.get('/', verifyToken, appointmentController.obtenerTodasLasCitas);

// 2. Obtener citas de un CLIENTE ESPECÍFICO (Para la App Flutter)
router.get('/usuario/:usuarioId', verifyToken, appointmentController.obtenerCitasPorUsuario);


// ==========================================
// RUTAS DE CREACIÓN Y EDICIÓN (POST / PUT)
// ==========================================

// 3. Crear cita (protegida con JWT)
router.post('/crear', verifyToken, appointmentController.crearCita);

// 4. Reprogramar cita (protegida con JWT)
router.put('/reprogramar/:citaId', verifyToken, appointmentController.reprogramarCita);

// 5. Cambiar estado de la cita (En Proceso / Completado / Cancelado)
router.put('/estado/:citaId', verifyToken, appointmentController.cambiarEstadoCita);


module.exports = router;