import express from 'express';
import vehicleController from '../controllers/vehicleController.js';
import Vehicle from '../models/Vehicle.js';
import { verifyToken, propioOAdmin } from '../middlewares/authMiddleware.js';

const router = express.Router();

const esAdminReq = (req) => String((req.user && req.user.rol) || '').toLowerCase() === 'admin';
const idDeSesion = (req) => String((req.user && (req.user.id || req.user._id)) || '');

// Al registrar: el vehículo queda a nombre del usuario con sesión (el id sale del token,
// no del cuerpo de la petición). El admin sí puede registrar a nombre de otro cliente.
const registroPropio = (req, res, next) => {
  if (!esAdminReq(req)) {
    req.body = { ...req.body, usuarioId: idDeSesion(req) };
  }
  next();
};

// Editar o eliminar: solo el dueño del vehículo o un admin.
const soloDuenoDelVehiculo = async (req, res, next) => {
  try {
    if (esAdminReq(req)) return next();

    const vehiculo = await Vehicle.findById(req.params.id).select('usuarioId').lean();
    if (!vehiculo) {
      return res.status(404).json({ mensaje: 'Vehículo no encontrado' });
    }
    if (String(vehiculo.usuarioId) !== idDeSesion(req)) {
      return res.status(403).json({ mensaje: 'No puedes modificar un vehículo que no es tuyo' });
    }
    next();
  } catch (error) {
    return res.status(400).json({ mensaje: 'Identificador de vehículo no válido' });
  }
};

// Un cliente no puede pasar su vehículo a otro usuario cambiando usuarioId al editar.
const sinCambiarDueno = (req, res, next) => {
  if (!esAdminReq(req) && req.body && 'usuarioId' in req.body) {
    const { usuarioId, ...resto } = req.body;
    req.body = resto;
  }
  next();
};

// Registrar un nuevo vehículo
router.post('/registrar', verifyToken, registroPropio, vehicleController.registerVehicle);

// Obtener vehículos de un usuario por su ID (solo su dueño o un admin)
router.get('/usuario/:userId', verifyToken, propioOAdmin('userId'), vehicleController.getVehiclesByUser);

// Actualizar un vehículo por ID
router.put('/:id', verifyToken, soloDuenoDelVehiculo, sinCambiarDueno, vehicleController.updateVehicle);

// Eliminar un vehículo por ID
router.delete('/:id', verifyToken, soloDuenoDelVehiculo, vehicleController.deleteVehicle);

export default router;