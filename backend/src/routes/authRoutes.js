import express from 'express';
import authController from '../controllers/authController.js';
import { loginWithGoogle } from '../controllers/google.js';
import { eliminarMiCuenta } from '../controllers/cuentaController.js';

const router = express.Router();

// 1. Autenticación principal
router.post('/login', authController.login);
router.post('/registrar', authController.registro);

// Autenticación con Google
router.post('/login-google', loginWithGoogle);

// 2. Verificación de cuenta (Ruta única estandarizada)
router.post('/verificar-cuenta', authController.confirmarCuenta);
router.post('/reenviar-codigo', authController.reenviarCodigoVerificacion);

// 3. Recuperación de contraseña
router.post('/recuperar/solicitar-codigo', authController.solicitarCodigoRecuperacion);
router.post('/recuperar/restablecer-password', authController.restablecerPassword);

// 4. Eliminación de cuenta (desde la app, con sesión iniciada)
router.post('/cuenta/eliminar', eliminarMiCuenta);

export default router;