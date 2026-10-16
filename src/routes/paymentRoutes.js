import express from 'express';
import paymentController from '../controllers/paymentController.js';
import { verifyToken, esAdmin } from '../middlewares/authMiddleware.js';

const router = express.Router();

// POST /api/payments              -> registrar pago (solo admin)
// GET  /api/payments              -> listar pagos (solo admin)
// GET  /api/payments/resumen      -> totales de hoy, semana y mes por método (solo admin)
// GET  /api/payments/cita/:citaId -> pago de una cita (solo admin)
router.post('/', verifyToken, esAdmin, paymentController.registrarPago);
router.get('/', verifyToken, esAdmin, paymentController.obtenerPagos);
router.get('/resumen', verifyToken, esAdmin, paymentController.obtenerResumen);
router.get('/cita/:citaId', verifyToken, esAdmin, paymentController.obtenerPagoPorCita);

export default router;