import express from 'express';
import appointmentController from '../controllers/appointmentController.js';
import authMiddleware, { esAdmin, propioOAdmin } from '../middlewares/authMiddleware.js';
import { obtenerCuposDelDia } from '../utils/cupos.js';

const router = express.Router();

// Middleware de autenticación estandarizado
const verifyToken = authMiddleware.verifyToken || authMiddleware;

// 1. RUTAS DE CONSULTA (GET)
// 🟢 Cupos por hora de un día: GET /api/appointments/cupos?fecha=YYYY-MM-DD
// (rutas fijas primero, antes de las que llevan parámetros)
router.get('/cupos', verifyToken, obtenerCuposDelDia);
// Admin: todas las citas. Cliente: solo las suyas (el filtro se aplica en el controlador)
router.get('/', verifyToken, appointmentController.obtenerTodasLasCitas);
// 🔒 Citas de un usuario: solo su dueño o un admin
router.get('/usuario/:usuarioId', verifyToken, propioOAdmin('usuarioId'), appointmentController.obtenerCitasPorUsuario);
// 🟢 Citas de un día (calendario): GET /api/appointments/fecha/YYYY-MM-DD
// Admin: de todos. Cliente: solo las suyas (el filtro se aplica en el controlador)
router.get('/fecha/:fecha', verifyToken, appointmentController.obtenerCitasPorFecha);

// 2. CREACIÓN (POST)
router.post('/', verifyToken, appointmentController.crearCita);

// 3. ACTUALIZACIÓN (PUT / PATCH)
// 🔒 Reprogramar: el controlador verifica que sea el dueño o un admin
router.put('/reprogramar/:citaId', verifyToken, appointmentController.reprogramarCita);
// 🔒 Cambiar a cualquier estado: solo administrador
router.patch('/estado/:citaId', verifyToken, esAdmin, appointmentController.cambiarEstadoCita);
// 🟢 Cancelar: la puede hacer el dueño de la cita o un administrador
router.patch('/cancelar/:citaId', verifyToken, appointmentController.cancelarCita);

export default router;