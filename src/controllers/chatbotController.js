// BACKEND/CONTROLLERS/CHATBOTCONTROLLER.JS

import Groq from "groq-sdk";
import Service from "../models/Service.js";

const groq = new Groq({ apiKey: process.env.GROQ_API_KEY });

export const chatearConAsesor = async (req, res) => {
  try {
    const { mensaje } = req.body;

    if (!mensaje || !mensaje.trim()) {
      return res.status(400).json({ message: "Debes enviar un mensaje válido." });
    }

    // 1. Consultar el catálogo de servicios en MongoDB (sin proyección estricta para evitar undefined)
    const servicios = await Service.find({}).lean();

    if (!servicios || servicios.length === 0) {
      return res.status(200).json({
        respuesta: "¡Hola! En este momento no tenemos servicios registrados en el spa."
      });
    }

    // 2. Formatear el catálogo tolerando claves en minúsculas o mayúsculas
    const catalogoTexto = servicios.map(s => {
      const nombre = s.nombre || s.Nombre || s.name || "Servicio sin nombre";
      const descripcion = s.descripcion || s.Descripcion || s.description || "Sin descripción disponible";
      const precio = s.precio ?? s.Precio ?? s.price ?? 0;

      return `- **${nombre}**: $${precio.toLocaleString("es-CO")} COP | Descripción: ${descripcion}`;
    }).join("\n");

    // 3. Prompt de comportamiento para el Asesor de Spa Vehicular
    const systemPrompt = `
Eres el asesor virtual experto de nuestro Spa Vehicular "Cars-Wash". Eres amable, atento y capacitado para guiar al cliente en la reserva de servicios.

CATÁLOGO DE SERVICIOS DISPONIBLES:
${catalogoTexto}

HORARIOS DE ATENCIÓN DEL SPA:
- Lunes a Sábado: 6:30 AM - 6:00 PM
- Domingos y Festivos: 6:30 AM - 2:00 PM

PAUTAS Y REGLAS DE ATENCIÓN SEGÚN LA INTENCIÓN DEL CLIENTE:

1. SALUDOS Y BIENVENIDA:
   Si el cliente solo saluda (ej: "Hola", "Buenas tardes"), responde cordialmente sin enviar el catálogo completo:
   "¡Hola! Bienvenido a nuestro Spa Vehicular 🚗✨ ¿En qué te podemos ayudar hoy?"

2. SERVICIOS Y PRECIOS:
   Si preguntan qué servicios hay o sus precios, entrega la lista formateada del catálogo.

3. AGENDAMIENTO, FECHAS Y HORARIOS DISPONIBLES:
   Si el cliente pregunta por disponibilidad de fechas, días u horarios (ej: "¿Qué fechas hay disponibles?", "¿Abren los domingos?"):
   - Informa nuestro horario regular de atención.
   - Explícale con amabilidad que para agendar una cita exacta debe ingresar a la sección "Reservas / Citas" de nuestra aplicación o indicar qué día y hora prefiere para verificar.

4. RECOMENDACIONES Y CUIDADO VEHICULAR:
   Si piden consejos (ej: "mi carro tiene rayones", "limpieza de cojinería", "proteger pintura"), recomienda el servicio adecuado basándote en las descripciones del catálogo.

5. UBICACIÓN Y CONTACTO:
   Si preguntan dónde estamos ubicados o cómo contactarnos, indica que nos encontramos en la sede principal del Spa Vehicular y pueden comunicarse mediante la app.

6. CONSULTAS FUERA DE ÁMBITO:
   Si solicitan mecánica pesada (cambio de frenos, motor), aclara amablemente que nos especializamos únicamente en lavado, detallado y estética automotriz.

Sé conciso, profesional y responde siempre en oraciones claras y amables.
`;

    // 4. Inferencia con el modelo activo de Groq
    // 4. Inferencia con un modelo activo de Groq
    // 4. Inferencia con un modelo activo en Groq
    const completion = await groq.chat.completions.create({
      model: "openai/gpt-oss-120b",
      messages: [
        { role: "system", content: systemPrompt },
        { role: "user", content: mensaje }
      ],
      temperature: 0.3,
      max_tokens: 500,
    });
    const respuestaTexto = completion.choices[0]?.message?.content || "No pude generar una respuesta.";

    return res.status(200).json({
      respuesta: respuestaTexto
    });

  } catch (error) {
    console.error("Error en Groq Chat:", error);
    return res.status(500).json({
      message: "Error al procesar la respuesta del asesor",
      error: error.message
    });
  }
};