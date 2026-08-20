const Appointment = require('../models/Appointment');
const { sendEmail } = require('../services/emailService');

exports.crearCita = async (req, res) => {
  try {
    const nuevaCita = new Appointment(req.body);
    await nuevaCita.save();

    // Enviar correo de confirmación si viene el correo en la petición o usuario autenticado
    const correoDestino = req.body.correo || (req.user && req.user.correo);

    if (correoDestino) {
      // Formatear la fecha para que se vea amigable en el correo
      const fechaFormateada = new Date(nuevaCita.fechaHoraCita).toLocaleString('es-CO', {
        dateStyle: 'long',
        timeStyle: 'short'
      });

      sendEmail({
        to: correoDestino,
        subject: '🚗 Confirmación de Cita - SPA Vehicular',
        html: `
          <div style="font-family: Arial, sans-serif; padding: 20px; border: 1px solid #e2e8f0; border-radius: 8px;">
            <h2 style="color: #2b6cb0;">¡Tu cita ha sido agendada con éxito!</h2>
            <p>Hola, hemos registrado tu solicitud de servicio en <b>SPA Vehicular</b>.</p>
            <hr style="border: 0; border-top: 1px solid #eee;" />
            <p><b>📅 Fecha y Hora:</b> ${fechaFormateada}</p>
            <p><b>📌 Estado:</b> ${nuevaCita.estado || 'Pendiente'}</p>
            <br/>
            <p>¡Gracias por confiar en nosotros! Te esperamos a tiempo.</p>
          </div>
        `
      }).catch(err => console.error('⚠️ No se pudo enviar el correo de creación:', err.message));
    }

    res.status(201).json({ mensaje: 'Cita agendada con éxito', cita: nuevaCita });
  } catch (error) {
    res.status(500).json({ mensaje: 'Error al agendar cita', error: error.message });
  }
};

exports.reprogramarCita = async (req, res) => {
  try {
    const { citaId } = req.params;
    const { nuevaFecha, motivo } = req.body;

    const cita = await Appointment.findById(citaId);
    if (!cita) return res.status(404).json({ mensaje: 'Cita no encontrada' });

    cita.historialReprogramaciones.push({
      motivo,
      fechaAnterior: cita.fechaHoraCita,
      fechaNueva: nuevaFecha
    });

    cita.fechaHoraCita = nuevaFecha;
    cita.estado = 'reprogramada';
    await cita.save();

    // Enviar correo de notificación de reprogramación
    const correoDestino = req.body.correo || (req.user && req.user.correo);

    if (correoDestino) {
      const fechaFormateada = new Date(nuevaFecha).toLocaleString('es-CO', {
        dateStyle: 'long',
        timeStyle: 'short'
      });

      sendEmail({
        to: correoDestino,
        subject: '🔄 Cita Reprogramada - SPA Vehicular',
        html: `
          <div style="font-family: Arial, sans-serif; padding: 20px; border: 1px solid #e2e8f0; border-radius: 8px;">
            <h2 style="color: #d69e2e;">Tu cita ha sido reprogramada</h2>
            <p>Te informamos que tu cita en <b>SPA Vehicular</b> ha cambiado de horario.</p>
            <hr style="border: 0; border-top: 1px solid #eee;" />
            <p><b>📅 Nueva Fecha y Hora:</b> ${fechaFormateada}</p>
            ${motivo ? `<p><b>💬 Motivo:</b> ${motivo}</p>` : ''}
            <br/>
            <p>Si tienes alguna duda sobre este cambio, puedes responder a este correo o contactarnos por el chatbot.</p>
          </div>
        `
      }).catch(err => console.error('⚠️ No se pudo enviar el correo de reprogramación:', err.message));
    }

    res.json({ mensaje: 'Cita reprogramada correctamente', cita });
  } catch (error) {
    res.status(500).json({ mensaje: 'Error al reprogramar cita', error: error.message });
  }
};