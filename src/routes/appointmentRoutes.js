import express from 'express';
import appointmentController from '../controllers/appointmentController.js';
import authMiddleware from '../middlewares/authMiddleware.js';

const router = express.Router();
const verifyToken = authMiddleware.verifyToken || authMiddleware;

// RUTAS DE CONSULTA (GET)
router.get('/', verifyToken, appointmentController.obtenerTodasLasCitas || appointmentController.obtenerCitas);
router.get('/usuario/:usuarioId', verifyToken, appointmentController.obtenerCitasPorUsuario);

// RUTAS DE CREACIÓN Y EDICIÓN (POST / PUT / PATCH)
// Acepta tanto POST /api/appointments como POST /api/appointments/crear
router.post('/', verifyToken, appointmentController.crearCita);
router.post('/crear', verifyToken, appointmentController.crearCita);

router.put('/reprogramar/:citaId', verifyToken, appointmentController.reprogramarCita);
router.put('/estado/:citaId', verifyToken, appointmentController.cambiarEstadoCita);
router.patch('/cambiar-estado/:citaId', verifyToken, appointmentController.cambiarEstadoCita);

export default router;