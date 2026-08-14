// src/routes/chatbotRoutes.js
const express = require('express');
const router = express.Router();
const chatbotController = require('../controllers/chatbotController');

router.post('/api/chatbot/message', chatbotController.handleMessage);

module.exports = router;