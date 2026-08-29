import express from 'express';
import authController from '../controllers/authController.js';

const router = express.Router();

// 1. Autenticación principal
router.post('/login', authController.login);
router.post('/registrar', authController.registro);

// 2. Recuperación de contraseña
router.post('/recuperar/solicitar-codigo', authController.solicitarCodigoRecuperacion);
router.post('/recuperar/restablecer-password', authController.restablecerPassword);

export default router;