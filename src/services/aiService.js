// src/services/aiService.js

/**
 * Función para responder preguntas frecuentes del SPA Vehicular.
 * Puedes conectar esto a la API de OpenAI, Gemini o usar lógica de respuestas automáticas.
 */
const generateChatResponse = async (userMessage) => {
  const messageLower = userMessage.toLowerCase();

  // Respuestas dinámicas/reglas de negocio según palabras clave
  if (messageLower.includes('servicio') || messageLower.includes('lavado')) {
    return "Ofrecemos Lavado General Básica, Lavado Premium + Polichado, Limpieza de Cojinería y Servicio a Domicilio. ¿Te gustaría agendar alguno?";
  }

  if (messageLower.includes('horario') || messageLower.includes('abierto')) {
    return "Nuestro horario de atención es de Lunes a Sábado de 8:00 AM a 6:00 PM.";
  }

  if (messageLower.includes('domicilio')) {
    return "¡Sí! Contamos con servicio a domicilio para la comodidad de tu hogar o trabajo. Solo seleccionalo al agendar tu cita.";
  }

  if (messageLower.includes('precio') || messageLower.includes('costo')) {
    return "Nuestros servicios van desde $25,000 COP para lavado básico hasta $80,000 COP para detallado de interiores. Puedes ver el catálogo completo en la app.";
  }

  // Respuesta por defecto si no coincide
  return "Hola, soy el asistente virtual del SPA Vehicular. ¿En qué te puedo ayudar hoy? Puedes preguntarme sobre nuestros servicios, horarios o domicilios.";
};

module.exports = { generateChatResponse };