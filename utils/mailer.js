import nodemailer from 'nodemailer';

const transporter = nodemailer.createTransport({
  service: 'gmail',
  auth: {
    user: process.env.EMAIL_USER,
    pass: process.env.EMAIL_PASS
  }
});

// Exportación nombrada para el código de verificación
export const enviarCodigoVerificacion = async (correo, codigo) => {
  const mailOptions = {
    from: process.env.EMAIL_USER,
    to: correo,
    subject: 'Código de Verificación - Cars Wash',
    html: `
      <div style="font-family: Arial, sans-serif; padding: 20px; color: #333;">
        <h2>¡Bienvenido a Cars Wash! 🚗✨</h2>
        <p>Tu código de verificación para activar tu cuenta es:</p>
        <h1 style="color: #007bff; letter-spacing: 2px;">${codigo}</h1>
        <p>Este código expira en 15 minutos.</p>
      </div>
    `
  };

  return await transporter.sendMail(mailOptions);
};

// Exportación nombrada para recuperación de contraseña
export const enviarCodigoRecuperacion = async (correo, codigo) => {
  const mailOptions = {
    from: process.env.EMAIL_USER,
    to: correo,
    subject: 'Recuperación de Contraseña - Cars Wash',
    html: `
      <div style="font-family: Arial, sans-serif; padding: 20px; color: #333;">
        <h2>Restablecer Contraseña</h2>
        <p>Has solicitado restablecer tu contraseña. Usa el siguiente código:</p>
        <h1 style="color: #dc3545; letter-spacing: 2px;">${codigo}</h1>
        <p>Si no solicitaste este cambio, ignora este mensaje.</p>
      </div>
    `
  };

  return await transporter.sendMail(mailOptions);
};