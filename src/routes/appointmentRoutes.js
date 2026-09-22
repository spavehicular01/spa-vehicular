import express from 'express';
import appointmentController from '../controllers/appointmentController.js';
import authMiddleware from '../middlewares/authMiddleware.js';

const router = express.Router();

// Middleware de autenticación estandarizado
const verifyToken = authMiddleware.verifyToken || authMiddleware;

// 1. RUTAS DE CONSULTA (GET)
router.get('/', verifyToken, appointmentController.obtenerTodasLasCitas);
router.get('/usuario/:usuarioId', verifyToken, appointmentController.obtenerCitasPorUsuario);

// 2. CREACIÓN (POST)
router.post('/', verifyToken, appointmentController.crearCita);

// 3. ACTUALIZACIÓN (PUT / PATCH)
router.put('/reprogramar/:citaId', verifyToken, appointmentController.reprogramarCita);
router.patch('/estado/:citaId', verifyToken, appointmentController.cambiarEstadoCita);

export default router;