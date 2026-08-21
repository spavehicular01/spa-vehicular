const express = require('express');
const router = express.Router();
const appointmentController = require('../controllers/appointmentController');

const authMiddleware = require('../middlewares/authMiddleware');
const verifyToken = authMiddleware.verifyToken || authMiddleware;

// 1. Obtener citas (Puedes agregar 'verifyToken' si quieres que solo usuarios/admins logueados las vean)
router.get('/', verifyToken, appointmentController.obtenerCitas);

// 2. Agendar nueva cita (Protegida)
router.post('/crear', verifyToken, appointmentController.crearCita);

// 3. Reprogramar cita (Protegida)
router.put('/reprogramar/:citaId', verifyToken, appointmentController.reprogramarCita);

// 4. Cambiar estado de la cita (Protegida)
router.patch('/cambiar-estado/:citaId', verifyToken, appointmentController.cambiarEstadoCita);

module.exports = router;