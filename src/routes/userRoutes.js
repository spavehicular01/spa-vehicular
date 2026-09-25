import express from 'express';
import { actualizarPerfil, obtenerClientes } from '../controllers/userController.js';
import { verifyToken, esAdmin } from '../middlewares/authMiddleware.js';

const router = express.Router();

router.put('/perfil/:id', verifyToken, actualizarPerfil);
router.get('/clientes', verifyToken, esAdmin, obtenerClientes);

export default router;