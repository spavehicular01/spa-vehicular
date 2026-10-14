import express from 'express';
import notificationController from '../controllers/notificationController.js';
import authMiddleware from '../middlewares/authMiddleware.js';

const router = express.Router();

// Middleware de autenticación estandarizado (igual que appointmentRoutes)
const verifyToken = authMiddleware.verifyToken || authMiddleware;

// Rutas fijas primero, antes de las que llevan parámetros
router.patch('/usuario/:usuarioId/leidas', verifyToken, notificationController.marcarTodasComoLeidas);
router.get('/usuario/:usuarioId', verifyToken, notificationController.obtenerNotificacionesPorUsuario);
router.patch('/:notificacionId/leida', verifyToken, notificationController.marcarComoLeida);

export default router;