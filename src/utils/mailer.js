import dotenv from 'dotenv';

dotenv.config();

// Función auxiliar para realizar peticiones HTTP a la API REST de Brevo
const enviarEmailBrevo = async ({ correo, asunto, html }) => {
  const response = await fetch('https://api.brevo.com/v3/smtp/email', {
    method: 'POST',
    headers: {
      'accept': 'application/json',
      'api-key': process.env.BREVO_API_KEY,
      'content-type': 'application/json'
    },
    body: JSON.stringify({
      sender: { 
        name: 'Cars Wash', 
        email: process.env.EMAIL_USER || 'didiercediel58@gmail.com' 
      },
      to: [{ email: correo }],
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

// 1. Enviar código de verificación al registrarse
export const enviarCodigoVerificacion = async (correo, codigo) => {
  const html = `
    <div style="font-family: Arial, sans-serif; padding: 20px; color: #333;">
      <h2>¡Bienvenido a Cars Wash! 🚗✨</h2>
      <p>Tu código de verificación para activar tu cuenta es:</p>
      <h1 style="color: #007bff; letter-spacing: 2px;">${codigo}</h1>
      <p>Este código expira en 15 minutos.</p>
    </div>
  `;
  return await enviarEmailBrevo({ correo, asunto: 'Código de Verificación - Cars Wash', html });
};

// 2. Enviar código de recuperación de contraseña
export const enviarCodigoRecuperacion = async (correo, codigo) => {
  const html = `
    <div style="font-family: Arial, sans-serif; padding: 20px; color: #333;">
      <h2>Restablecer Contraseña</h2>
      <p>Has solicitado restablecer tu contraseña. Usa el siguiente código:</p>
      <h1 style="color: #dc3545; letter-spacing: 2px;">${codigo}</h1>
      <p>Si no solicitaste este cambio, ignora este mensaje.</p>
    </div>
  `;
  return await enviarEmailBrevo({ correo, asunto: 'Recuperación de Contraseña - Cars Wash', html });
};