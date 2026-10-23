import express from 'express';
import deviceController from '../controllers/deviceController.js';
import { verifyToken } from '../middlewares/authMiddleware.js';

const router = express.Router();

// POST /api/devices      -> registrar el token del celular (al iniciar sesión)
// POST /api/devices/baja -> quitar el token del celular (al cerrar sesión)
router.post('/', verifyToken, deviceController.registrarDispositivo);
router.post('/baja', verifyToken, deviceController.eliminarDispositivo);

export default router;