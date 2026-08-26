const nodemailer = require('nodemailer');

// Configuración del servicio de correo (Gmail)
const transporter = nodemailer.createTransport({
  service: 'gmail',
  auth: {
    user: 'spavehicular01@gmail.com', // Tu correo de administrador SPA
    pass: 'xxxx xxxx xxxx xxxx'       // Contraseña de aplicación generada en tu cuenta de Google
  }
});

exports.enviarCodigoCorreo = async (destino, codigo) => {
  const mailOptions = {
    from: '"SPA Vehicular" <spavehicular01@gmail.com>',
    to: destino,
    subject: 'Código de Recuperación de Contraseña - SPA Vehicular',
    html: `
      <div style="font-family: Arial, sans-serif; padding: 20px; color: #333;">
        <h2>Recuperación de Contraseña</h2>
        <p>Has solicitado restablecer tu contraseña en <strong>SPA Vehicular</strong>.</p>
        <p>Tu código de verificación de 6 dígitos es:</p>
        <h1 style="color: #0011ff; letter-spacing: 5px;">${codigo}</h1>
        <p>Este código expira en 15 minutos.</p>
        <p>Si no solicitaste este cambio, puedes ignorar este mensaje.</p>
      </div>
    `
  };

  return await transporter.sendMail(mailOptions);
};