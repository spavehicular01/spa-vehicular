const express = require('express');
const router = express.Router();
const vehicleController = require('../controllers/vehicleController');

// POST: http://localhost:3000/api/vehicles/registrar
router.post('/registrar', vehicleController.registrarVehiculo);

// GET: http://localhost:3000/api/vehicles/usuario/:usuarioId
router.get('/usuario/:usuarioId', vehicleController.obtenerVehiculosPorUsuario);

module.exports = router;