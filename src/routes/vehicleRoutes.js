import express from 'express';
import vehicleController from '../controllers/vehicleController.js';

const router = express.Router();

// Registrar un nuevo vehículo
router.post('/registrar', vehicleController.registerVehicle);

// Obtener vehículos de un usuario por su ID
router.get('/usuario/:userId', vehicleController.getVehiclesByUser);

// Eliminar un vehículo por ID
router.delete('/:id', vehicleController.deleteVehicle);

export default router;