const express = require('express');
const router = express.Router();
const serviceController = require('../controllers/serviceController');

// Rutas de servicios (RF009)
router.get('/api/servicios', serviceController.obtenerServicios);
router.post('/api/servicios/crear', serviceController.crearServicio);

// OBLIGATORIO: Debe exportarse 'router'
module.exports = router;