// Envío de correos por la API de Brevo (el mismo proveedor que usa mailer.js).
// Ya no depende de Gmail ni de contraseñas de aplicación.

export const sendEmail = async ({ to, subject, html }) => {
  try {
    const apiKey = process.env.BREVO_API_KEY;
    const senderEmail = (process.env.EMAIL_USER || '').trim();

    if (!apiKey) {
      throw new Error('No se ha configurado la variable de entorno BREVO_API_KEY');
    }
    if (!senderEmail) {
      throw new Error('No se ha configurado la variable de entorno EMAIL_USER (remitente verificado en Brevo)');
    }

    const destino = to ? String(to).trim().toLowerCase() : '';
    if (!destino || !destino.includes('@')) {
      throw new Error(`El email de destino no es válido. Valor recibido: "${to}"`);
    }

    const response = await fetch('https://api.brevo.com/v3/smtp/email', {
      method: 'POST',
      headers: {
        'accept': 'application/json',
        'api-key': apiKey,
        'content-type': 'application/json'
      },
      body: JSON.stringify({
        sender: { name: 'SPA VEHICULAR', email: senderEmail },
        to: [{ email: destino }],
        subject,
        htmlContent: html
      })
    });

    const data = await response.json();

    if (!response.ok) {
      throw new Error(`Error Brevo API: ${data.message || JSON.stringify(data)}`);
    }

    console.log('✉️ Correo enviado:', data.messageId || '');
    return data;
  } catch (error) {
    console.error('❌ Error enviando correo:', error.message);
    throw error;
  }
};

export default sendEmail;