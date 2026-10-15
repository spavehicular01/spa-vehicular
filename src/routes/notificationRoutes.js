import express from 'express';
import notificationController from '../controllers/notificationController.js';
import authMiddleware, { propioOAdmin } from '../middlewares/authMiddleware.js';

const router = express.Router();

// Middleware de autenticación estandarizado (igual que appointmentRoutes)
const verifyToken = authMiddleware.verifyToken || authMiddleware;

// Rutas fijas primero, antes de las que llevan parámetros
// 🔒 Solo el dueño de las notificaciones o un admin
router.patch('/usuario/:usuarioId/leidas', verifyToken, propioOAdmin('usuarioId'), notificationController.marcarTodasComoLeidas);
router.get('/usuario/:usuarioId', verifyToken, propioOAdmin('usuarioId'), notificationController.obtenerNotificacionesPorUsuario);
// 🔒 El controlador verifica que la notificación sea del usuario con sesión
router.patch('/:notificacionId/leida', verifyToken, notificationController.marcarComoLeida);

export default router;