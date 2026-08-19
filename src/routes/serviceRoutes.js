const express = require('express');
const router = express.Router();
const serviceController = require('../controllers/serviceController');

// ✅ La raíz '/' equivale a '/api/services'
router.get('/', serviceController.obtenerServicios);
router.post('/', serviceController.crearServicio);

module.exports = router;