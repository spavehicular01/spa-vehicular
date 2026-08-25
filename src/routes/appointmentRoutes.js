const express = require('express');
const router = express.Router();
const appointmentController = require('../controllers/appointmentController');

const authMiddleware = require('../middlewares/authMiddleware');
const verifyToken = authMiddleware.verifyToken || authMiddleware;

<<<<<<< HEAD
// 1. Obtener citas (Puedes agregar 'verifyToken' si quieres que solo usuarios/admins logueados las vean)
router.get('/', verifyToken, appointmentController.obtenerCitas);

// 2. Agendar nueva cita (Protegida)
router.post('/crear', verifyToken, appointmentController.crearCita);

// 3. Reprogramar cita (Protegida)
router.put('/reprogramar/:citaId', verifyToken, appointmentController.reprogramarCita);

// 4. Cambiar estado de la cita (Protegida)
router.patch('/cambiar-estado/:citaId', verifyToken, appointmentController.cambiarEstadoCita);
=======
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

>>>>>>> origin/feature/diego

module.exports = router;