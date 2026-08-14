const express = require('express');
const router = express.Router();
const appointmentController = require('../controllers/appointmentController');

router.post('/api/citas/crear', appointmentController.crearCita);
router.put('/api/citas/reprogramar/:citaId', appointmentController.reprogramarCita);

module.exports = router;