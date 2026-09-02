import express from 'express';
import serviceController from '../controllers/serviceController.js';
import verifyToken from '../middlewares/authMiddleware.js';

const router = express.Router();

// GET /api/services - Obtener servicios activos
router.get('/', serviceController.obtenerServicios);

// POST /api/services - Crear un nuevo servicio
router.post('/', serviceController.crearServicio);

export default router;