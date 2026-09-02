import nodemailer from 'nodemailer';

const transporter = nodemailer.createTransport({
  service: 'gmail', // O configura tu SMTP en variables de entorno
  auth: {
    user: process.env.EMAIL_USER,
    pass: process.env.EMAIL_PASS
  }
});

export const sendEmail = async ({ to, subject, html }) => {
  try {
    const mailOptions = {
      from: `"SPA VEHICULAR" <${process.env.EMAIL_USER}>`,
      to,
      subject,
      html
    };

    const info = await transporter.sendMail(mailOptions);
    console.log('✉️ Correo enviado:', info.messageId);
    return info;
  } catch (error) {
    console.error('❌ Error enviando correo:', error);
    throw error;
  }
};

export default sendEmail;