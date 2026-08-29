const express = require('express');
const router = express.Router();
const authController = require('../controllers/authController');

// 1. Autenticación principal
router.post('/login', authController.login);
router.post('/registrar', authController.registro);

// 2. Recuperación de contraseña
router.post('/recuperar/solicitar-codigo', authController.solicitarCodigoRecuperacion);
router.post('/recuperar/restablecer-password', authController.restablecerPassword);

module.exports = router;