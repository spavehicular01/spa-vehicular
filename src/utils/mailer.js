import nodemailer from 'nodemailer';

const transporter = nodemailer.createTransport({
  service: 'gmail',
  auth: {
    user: process.env.EMAIL_USER,
    pass: process.env.EMAIL_PASS
  }
});

// Enviar código para verificar registro de cuenta
export const enviarCodigoVerificacion = async (correo, nombre, codigo) => {
  const mailOptions = {
    from: `"Cars Wash" <${process.env.EMAIL_USER}>`,
    to: correo,
    subject: '¡Gracias por registrarte! Confirma tu cuenta',
    html: `
      <div style="font-family: Arial, sans-serif; line-height: 1.6; color: #333; padding: 20px;">
        <h2>¡Hola, ${nombre}!</h2>
        <p>Gracias por registrarte en nuestra plataforma.</p>
        <p>Para completar tu registro y activar tu cuenta, ingresa el siguiente código de 6 dígitos:</p>
        <div style="background-color: #007bff; color: #ffffff; padding: 15px; font-size: 24px; font-weight: bold; letter-spacing: 5px; text-align: center; border-radius: 8px; margin: 20px 0;">
          ${codigo}
        </div>
        <p>Este código vencerá en <strong>15 minutos</strong>.</p>
        <p>Si no creaste esta cuenta, puedes ignorar este mensaje.</p>
      </div>
    `
  };

  return await transporter.sendMail(mailOptions);
};

// Enviar código para recuperar contraseña
export const enviarCodigoRecuperacion = async (correo, codigo) => {
  const mailOptions = {
    from: `"Cars Wash" <${process.env.EMAIL_USER}>`,
    to: correo,
    subject: 'Recuperación de Contraseña - Cars Wash',
    html: `
      <div style="font-family: Arial, sans-serif; padding: 20px; color: #333;">
        <h2>Restablecer Contraseña</h2>
        <p>Has solicitado restablecer tu contraseña. Usa el siguiente código:</p>
        <h1 style="color: #dc3545; letter-spacing: 2px;">${codigo}</h1>
        <p>Este código expira en 15 minutos.</p>
        <p>Si no solicitaste este cambio, ignora este mensaje.</p>
      </div>
    `
  };

  return await transporter.sendMail(mailOptions);
};