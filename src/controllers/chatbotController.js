// src/controllers/chatbotController.js
const { generateChatResponse } = require('../services/aiService');

exports.handleMessage = async (req, res) => {
  try {
    const { message } = req.body;

    if (!message) {
      return res.status(400).json({ message: 'El mensaje es obligatorio.' });
    }

    const reply = await generateChatResponse(message);

    res.json({
      success: true,
      userMessage: message,
      reply
    });
  } catch (error) {
    res.status(500).json({ message: 'Error al procesar el mensaje del chatbot.', error: error.message });
  }
};