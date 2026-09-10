import express from 'express';
import serviceController from '../controllers/serviceController.js';
import verifyToken from '../middlewares/authMiddleware.js';

const router = express.Router();

// GET /api/services - Obtener servicios activos
router.get('/', serviceController.obtenerServicios);

// POST /api/services - Crear un nuevo servicio
router.post('/', serviceController.crearServicio);

// PUT /api/services/:id - Actualizar un servicio existente por ID
router.put('/:id', serviceController.actualizarServicio);

// DELETE /api/services/:id - Eliminar un servicio por ID
router.delete('/:id', serviceController.eliminarServicio);

export default router;