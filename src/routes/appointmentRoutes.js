import express from 'express';
import appointmentController from '../controllers/appointmentController.js';
import authMiddleware, { esAdmin } from '../middlewares/authMiddleware.js';
import { obtenerCuposDelDia } from '../utils/cupos.js';

const router = express.Router();

// Middleware de autenticación estandarizado
const verifyToken = authMiddleware.verifyToken || authMiddleware;

// 1. RUTAS DE CONSULTA (GET)
// 🟢 Cupos por hora de un día: GET /api/appointments/cupos?fecha=YYYY-MM-DD
// (rutas fijas primero, antes de las que llevan parámetros)
router.get('/cupos', verifyToken, obtenerCuposDelDia);
router.get('/', verifyToken, appointmentController.obtenerTodasLasCitas);
router.get('/usuario/:usuarioId', verifyToken, appointmentController.obtenerCitasPorUsuario);
// 🟢 Citas de un día (calendario): GET /api/appointments/fecha/YYYY-MM-DD
router.get('/fecha/:fecha', verifyToken, appointmentController.obtenerCitasPorFecha);

// 2. CREACIÓN (POST)
router.post('/', verifyToken, appointmentController.crearCita);

// 3. ACTUALIZACIÓN (PUT / PATCH)
router.put('/reprogramar/:citaId', verifyToken, appointmentController.reprogramarCita);
// 🔒 Cambiar a cualquier estado: solo administrador
router.patch('/estado/:citaId', verifyToken, esAdmin, appointmentController.cambiarEstadoCita);
// 🟢 Cancelar: la puede hacer el dueño de la cita o un administrador
router.patch('/cancelar/:citaId', verifyToken, appointmentController.cancelarCita);

export default router;