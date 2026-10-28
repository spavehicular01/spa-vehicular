import dotenv from 'dotenv';

dotenv.config();

// Función auxiliar para realizar peticiones HTTP a la API REST de Brevo
const enviarEmailBrevo = async ({ correo, nombre, asunto, html }) => {
  const apiKey = process.env.BREVO_API_KEY;

  if (!apiKey) {
    throw new Error('No se ha configurado la variable de entorno BREVO_API_KEY');
  }

  // Sanitización y validación estricta del email de destino
  const emailLimpio = correo ? String(correo).trim().toLowerCase() : '';

  if (!emailLimpio || !emailLimpio.includes('@')) {
    throw new Error(`El email de destino no es válido. Valor recibido: "${correo}"`);
  }

  const senderEmail = process.env.EMAIL_USER || 'didiercediel58@gmail.com';

  const response = await fetch('https://api.brevo.com/v3/smtp/email', {
    method: 'POST',
    headers: {
      'accept': 'application/json',
      'api-key': apiKey,
      'content-type': 'application/json'
    },
    body: JSON.stringify({
      sender: { 
        name: 'Cars Wash', 
        email: senderEmail.trim() 
      },
      to: [
        { 
          email: emailLimpio,
          name: nombre ? String(nombre).trim() : 'Usuario'
        }
      ],
      subject: asunto,
      htmlContent: html
    })
  });

  const data = await response.json();

  if (!response.ok) {
    throw new Error(`Error Brevo API: ${data.message || JSON.stringify(data)}`);
  }

  return data;
};

// 1. Enviar código de verificación al registrarse (Soporta envío directo o por objeto)
export const enviarCodigoVerificacion = async (correoParam, codigoParam, nombreParam) => {
  let correo = correoParam;
  let codigo = codigoParam;
  let nombre = nombreParam;

  // Compatibilidad por si se llama con un objeto: enviarCodigoVerificacion({ correo, codigo, nombre })
  if (typeof correoParam === 'object' && correoParam !== null) {
    correo = correoParam.correo || correoParam.email;
    codigo = correoParam.codigo;
    nombre = correoParam.nombre;
  }

  const html = `
    <div style="font-family: Arial, sans-serif; padding: 20px; color: #333; max-width: 500px; border: 1px solid #eee; border-radius: 8px;">
      <h2 style="color: #0052cc;">¡Bienvenido a Cars Wash! 🚗✨</h2>
      <p>Hola <strong>${nombre || 'Usuario'}</strong>, gracias por registrarte. Tu código para activar tu cuenta es:</p>
      <div style="background-color: #f4f6f8; padding: 15px; text-align: center; border-radius: 6px; margin: 20px 0;">
        <h1 style="color: #0052cc; letter-spacing: 5px; margin: 0; font-size: 32px;">${codigo}</h1>
      </div>
      <p style="font-size: 13px; color: #666;">Este código expira en 10 minutos.</p>
    </div>
  `;

  return await enviarEmailBrevo({ 
    correo, 
    nombre, 
    asunto: 'Código de Verificación - Cars Wash', 
    html 
  });
};

// 2. Enviar código de recuperación de contraseña
export const enviarCodigoRecuperacion = async (correoParam, codigoParam, nombreParam) => {
  let correo = correoParam;
  let codigo = codigoParam;
  let nombre = nombreParam;

  if (typeof correoParam === 'object' && correoParam !== null) {
    correo = correoParam.correo || correoParam.email;
    codigo = correoParam.codigo;
    nombre = correoParam.nombre;
  }

  const html = `
    <div style="font-family: Arial, sans-serif; padding: 20px; color: #333; max-width: 500px; border: 1px solid #eee; border-radius: 8px;">
      <h2 style="color: #dc3545;">Restablecer Contraseña 🔒</h2>
      <p>Hola <strong>${nombre || 'Usuario'}</strong>, has solicitado restablecer tu contraseña. Usa el siguiente código:</p>
      <div style="background-color: #fcf8f8; padding: 15px; text-align: center; border-radius: 6px; margin: 20px 0;">
        <h1 style="color: #dc3545; letter-spacing: 5px; margin: 0; font-size: 32px;">${codigo}</h1>
      </div>
      <p style="font-size: 13px; color: #666;">Si no solicitaste este cambio, ignora este mensaje. El código expira en 10 minutos.</p>
    </div>
  `;

  return await enviarEmailBrevo({ 
    correo, 
    nombre, 
    asunto: 'Recuperación de Contraseña - Cars Wash', 
    html 
  });
};

export default {
  enviarCodigoVerificacion,
  enviarCodigoRecuperacion
};