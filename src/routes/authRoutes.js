const express = require('express');
const router = express.Router();
const authController = require('../controllers/authController');

// Rutas de la API con prefijo api
router.post('/api/registrar', authController.registrarUser);
router.post('/api/login', authController.loginUser);

module.exports = router;