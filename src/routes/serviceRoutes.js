const express = require('express');
const router = express.Router();
const serviceController = require('../controllers/serviceController');

// Manejo del middleware de autenticación (opcional si deseas proteger la creación)
const authModule = require('../middlewares/authMiddleware');
const verifyToken = authModule.verifyToken || authModule;

// GET /api/services - Obtener servicios activos
router.get('/', serviceController.obtenerServicios);

// POST /api/services - Crear un nuevo servicio
router.post('/', serviceController.crearServicio);

module.exports = router;