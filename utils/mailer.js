import nodemailer from "nodemailer";

const transporter = nodemailer.createTransport({
  service: "gmail",
  auth: {
    user: process.env.EMAIL_USER,
    pass: process.env.EMAIL_PASS
  }
});

export const enviarCodigoVerificacion = async (correo, nombre, codigo) => {
  const mailOptions = {
    from: `"Mi tienda de cafe" <${process.env.EMAIL_USER}>`,
    to: correo,
    subject: "¡Gracias por registrarte! Confirma tu cuenta",
    html: `
      <div style="font-family: Arial, sans-serif; line-height: 1.6; color: #333;">
        <h2>¡Hola, ${nombre}!</h2>
        <p>Gracias por registrarte en nuestra plataforma.</p>
        <p>Para completar tu registro y activar tu cuenta, ingresa el siguiente código de 6 dígitos:</p>
        <div style="background-color: #d41010; color: #ffffff; padding: 15px; font-size: 24px; font-weight: bold; letter-spacing: 5px; text-align: center; border-radius: 8px; margin: 20px 0;">
          ${codigo}
        </div>
        <p>Este código vencerá en <strong>15 minutos</strong>.</p>
        <p>Si no creaste esta cuenta, puedes ignorar este mensaje.</p>
      </div>
    `
  };

  await transporter.sendMail(mailOptions);
};