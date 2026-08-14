const Appointment = require('../models/Appointment');

exports.crearCita = async (req, res) => {
  try {
    const nuevaCita = new Appointment(req.body);
    await nuevaCita.save();
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

    res.json({ mensaje: 'Cita reprogramada correctamente', cita });
  } catch (error) {
    res.status(500).json({ mensaje: 'Error al reprogramar cita', error: error.message });
  }
};