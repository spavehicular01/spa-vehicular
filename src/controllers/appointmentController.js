const Appointment = require('../models/Appointment');
const { sendEmail } = require('../services/emailService');

<<<<<<< HEAD
// 1. Obtener citas (con opción de filtrar por estado)
exports.obtenerCitas = async (req, res) => {
  try {
    const { estado } = req.query;
    const filtro = estado ? { estado } : {};
    const citas = await Appointment.find(filtro);

    res.status(200).json(citas);
  } catch (error) {
    res.status(500).json({ mensaje: 'Error al obtener citas', error: error.message });
  }
};

// 2. Crear cita
=======
// 1. Obtener todas las citas (Para el Administrador)
exports.obtenerTodasLasCitas = async (req, res) => {
  try {
    const citas = await Appointment.find().sort({ fechaHoraCita: -1 });
    res.json(citas);
  } catch (error) {
    res.status(500).json({ mensaje: 'Error al obtener todas las citas', error: error.message });
  }
};

// 2. Obtener citas de un cliente específico (Para la App Móvil Flutter)
exports.obtenerCitasPorUsuario = async (req, res) => {
  try {
    const { usuarioId } = req.params;
    
    // Busca las citas asociadas al usuarioId o clienteId según como lo guardes en Mongo
    const citas = await Appointment.find({
      $or: [{ usuarioId }, { clienteId: usuarioId }]
    }).sort({ fechaHoraCita: -1 });

    res.json(citas);
  } catch (error) {
    res.status(500).json({ mensaje: 'Error al obtener las citas del usuario', error: error.message });
  }
};

// 3. Crear Cita
>>>>>>> origin/feature/diego
exports.crearCita = async (req, res) => {
  try {
    const nuevaCita = new Appointment(req.body);
    await nuevaCita.save();

    const correoDestino = req.body.correo || (req.user && req.user.correo);

    if (correoDestino) {
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

<<<<<<< HEAD
// 3. Reprogramar cita
=======
// 4. Reprogramar Cita
>>>>>>> origin/feature/diego
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

<<<<<<< HEAD
// 4. Cambiar estado de la cita
exports.cambiarEstadoCita = async (req, res) => {
  try {
    const { citaId } = req.params;
    const { estado } = req.body; // 'confirmada', 'completado', 'cancelado'

    const cita = await Appointment.findByIdAndUpdate(
=======
// 5. Cambiar Estado de Cita y emitir WebSockets + Email
exports.cambiarEstadoCita = async (req, res) => {
  try {
    const { citaId } = req.params;
    const { estado } = req.body;

    const citaActualizada = await Appointment.findByIdAndUpdate(
>>>>>>> origin/feature/diego
      citaId,
      { estado },
      { new: true }
    );

<<<<<<< HEAD
    res.json({ mensaje: 'Estado actualizado con éxito', cita });
  } catch (error) {
    res.status(500).json({ mensaje: 'Error al actualizar estado', error: error.message });
=======
    if (!citaActualizada) {
      return res.status(404).json({ mensaje: 'Cita no encontrada' });
    }

    if (req.io) {
      req.io.emit('cambio_estado_cita', {
        citaId: citaActualizada._id,
        nuevoEstado: citaActualizada.estado,
        cita: citaActualizada
      });
    }

    const correoDestino = citaActualizada.correo || (req.user && req.user.correo);

    if (correoDestino) {
      let titulo = 'Actualización de tu Servicio';
      let mensajeColor = '#2b6cb0';
      let contenido = `El estado de tu cita ha cambiado a: <b>${estado}</b>.`;

      if (estado === 'En Proceso') {
        titulo = '🧼 ¡Tu vehículo ha entrado a lavado!';
        mensajeColor = '#3182ce';
        contenido = 'Hemos comenzado a trabajar en tu vehículo. ¡Te avisaremos en cuanto esté impecable!';
      } else if (estado === 'Completado') {
        titulo = '✅ ¡Tu vehículo está listo!';
        mensajeColor = '#38a169';
        contenido = 'El servicio ha finalizado con éxito. Ya puedes pasar a recoger tu vehículo.';
      }

      sendEmail({
        to: correoDestino,
        subject: `${titulo} - SPA Vehicular`,
        html: `
          <div style="font-family: Arial, sans-serif; padding: 20px; border: 1px solid #e2e8f0; border-radius: 8px;">
            <h2 style="color: ${mensajeColor};">${titulo}</h2>
            <p>${contenido}</p>
            <hr style="border: 0; border-top: 1px solid #eee;" />
            <p><b>📌 Estado Actual:</b> ${estado}</p>
            <br/>
            <p>Gracias por confiar en <b>SPA Vehicular</b>.</p>
          </div>
        `
      }).catch(err => console.error('⚠️ No se pudo enviar el correo de actualización de estado:', err.message));
    }

    res.json({
      mensaje: `Estado de la cita actualizado a '${estado}'`,
      cita: citaActualizada
    });

  } catch (error) {
    res.status(500).json({ mensaje: 'Error al cambiar estado de la cita', error: error.message });
>>>>>>> origin/feature/diego
  }
};