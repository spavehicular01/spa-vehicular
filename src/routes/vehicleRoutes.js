const express = require('express');
const router = express.Router();
const vehicleController = require('../controllers/vehicleController');

router.post('/api/vehiculos/registrar', vehicleController.registrarVehiculo);
router.get('/api/vehiculos/usuario/:usuarioId', vehicleController.obtenerVehiculosPorUsuario);

module.exports = router;