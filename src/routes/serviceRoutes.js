const express = require('express');
const router = express.Router();
const serviceController = require('../controllers/serviceController');
const appointmentController = require('../controllers/appointmentController');

// 1. Manejo seguro de la importación del middleware (soporta exportación directa u objeto)
const authModule = require('../middlewares/authMiddleware');
const verifyToken = authModule.verifyToken || authModule;

// ✅ Servicio Público
router.get('/', serviceController.obtenerServicios);

// 🔒 Citas (Protegido)
router.post('/crear', verifyToken, appointmentController.crearCita);

module.exports = router;