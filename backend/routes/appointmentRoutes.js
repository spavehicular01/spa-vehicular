const Appointment = require('../models/Appointment');

// 1. Obtener todas las citas (Admin)
exports.obtenerTodasLasCitas = async (req, res) => {
  try {
    const citas = await Appointment.find().sort({ createdAt: -1 });
    res.status(200).json(citas);
  } catch (error) {
    res.status(500).json({ error: 'Error al obtener todas las citas' });
  }
};

// 2. Obtener citas por cliente (App Móvil Flutter)
exports.obtenerCitasPorUsuario = async (req, res) => {
  try {
    const { usuarioId } = req.params;
    const citas = await Appointment.find({ usuario: usuarioId }).sort({ createdAt: -1 });
    res.status(200).json(citas);
  } catch (error) {
    res.status(500).json({ error: 'Error al obtener las citas del usuario' });
  }
};

// 3. Crear cita
exports.crearCita = async (req, res) => {
  try {
    const nuevaCita = new Appointment(req.body);
    await nuevaCita.save();

    // Notificar por Socket.io
    const io = req.app.get('socketio');
    if (io) {
      io.emit('cambio_estado_cita', {
        citaId: nuevaCita._id,
        nuevoEstado: nuevaCita.estado,
        usuarioId: nuevaCita.usuario,
      });
    }

    res.status(201).json(nuevaCita);
  } catch (error) {
    res.status(500).json({ error: 'Error al crear la cita: ' + error.message });
  }
};

// 4. Cambiar estado
exports.cambiarEstadoCita = async (req, res) => {
  try {
    const { citaId } = req.params;
    const { estado } = req.body;

    const citaActualizada = await Appointment.findByIdAndUpdate(
      citaId,
      { estado },
      { new: true }
    );

    if (!citaActualizada) {
      return res.status(404).json({ error: 'Cita no encontrada' });
    }

    // Emitir Socket en tiempo real al cliente
    const io = req.app.get('socketio');
    if (io) {
      io.emit('cambio_estado_cita', {
        citaId: citaActualizada._id,
        nuevoEstado: citaActualizada.estado,
        usuarioId: citaActualizada.usuario,
      });
    }

    res.status(200).json(citaActualizada);
  } catch (error) {
    res.status(500).json({ error: 'Error al actualizar el estado de la cita' });
  }
};

// 5. Reprogramar cita
exports.reprogramarCita = async (req, res) => {
  try {
    const { citaId } = req.params;
    const { fechaHoraCita } = req.body;

    const citaReprogramada = await Appointment.findByIdAndUpdate(
      citaId,
      { fechaHoraCita },
      { new: true }
    );

    res.status(200).json(citaReprogramada);
  } catch (error) {
    res.status(500).json({ error: 'Error al reprogramar la cita' });
  }
};