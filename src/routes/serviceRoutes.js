import express from 'express';
import serviceController from '../controllers/serviceController.js';
import { verifyToken, esAdmin } from '../middlewares/authMiddleware.js';

const router = express.Router();

// GET /api/services - Obtener servicios activos (público: se ven antes de iniciar sesión)
router.get('/', serviceController.obtenerServicios);

// Crear, editar y eliminar servicios: solo el administrador
// POST /api/services - Crear un nuevo servicio
router.post('/', verifyToken, esAdmin, serviceController.crearServicio);

// PUT /api/services/:id - Actualizar un servicio existente por ID
router.put('/:id', verifyToken, esAdmin, serviceController.actualizarServicio);

// DELETE /api/services/:id - Eliminar un servicio por ID
router.delete('/:id', verifyToken, esAdmin, serviceController.eliminarServicio);

export default router;