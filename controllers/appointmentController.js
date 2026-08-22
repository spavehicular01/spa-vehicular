const Appointment = require('../models/Appointment');

// 1. Crear Cita
exports.crearCita = async (req, res) => {
  try {
    const nuevaCita = new Appointment(req.body);
    await nuevaCita.save();

    // Notificar por WebSockets
    const io = req.app.get('socketio');
    if (io) {
      io.emit('cambio_estado_cita', {
        citaId: nuevaCita._id,
        nuevoEstado: nuevaCita.estado,
        usuarioId: nuevaCita.usuario
      });
    }

    res.status(201).json(nuevaCita);
  } catch (error) {
    res.status(500).json({ error: 'Error al crear la cita: ' + error.message });
  }
};

// 2. Obtener Citas de un Usuario Específico
exports.obtenerCitasPorUsuario = async (req, res) => {
  try {
    const { usuarioId } = req.params;
    // Buscar citas asociadas a ese ObjectId de MongoDB
    const citas = await Appointment.find({ usuario: usuarioId }).sort({ createdAt: -1 });
    res.status(200).json(citas);
  } catch (error) {
    res.status(500).json({ error: 'Error al obtener citas del usuario' });
  }
};

// 3. Actualizar Estado (Admin)
exports.actualizarEstado = async (req, res) => {
  try {
    const { id } = req.params;
    const { estado } = req.body;

    const citaActualizada = await Appointment.findByIdAndUpdate(
      id,
      { estado },
      { new: true }
    );

    if (!citaActualizada) {
      return res.status(404).json({ error: 'Cita no encontrada' });
    }

    // Emitir Socket en tiempo real
    const io = req.app.get('socketio');
    if (io) {
      io.emit('cambio_estado_cita', {
        citaId: citaActualizada._id,
        nuevoEstado: citaActualizada.estado,
        usuarioId: citaActualizada.usuario
      });
    }

    res.status(200).json(citaActualizada);
  } catch (error) {
    res.status(500).json({ error: 'Error al actualizar el estado' });
  }
};