const express = require('express');
const router = express.Router();
const authController = require('../controllers/authController.js');

// Rutas de autenticación
router.post('/registrar', authController.registrarUser);
router.post('/login', authController.loginUser);

module.exports = router;