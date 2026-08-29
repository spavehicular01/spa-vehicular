const express = require('express');
const router = express.Router();
const userController = require('../controllers/userController');

// Ruta para actualizar datos del perfil
router.put('/:id', userController.actualizarPerfil);

module.exports = router;