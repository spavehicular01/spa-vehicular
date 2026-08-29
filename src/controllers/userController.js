const User = require('../models/User');

// Actualizar perfil de usuario
exports.actualizarPerfil = async (req, res) => {
  try {
    const { id } = req.params;
    const { nombres, apellidos, celular } = req.body;

    const usuarioActualizado = await User.findByIdAndUpdate(
      id,
      { nombres, apellidos, celular },
      { new: true }
    );

    if (!usuarioActualizado) {
      return res.status(404).json({ ok: false, mensaje: 'Usuario no encontrado' });
    }

    return res.status(200).json({
      ok: true,
      mensaje: 'Perfil actualizado correctamente',
      usuario: {
        id: usuarioActualizado._id,
        nombres: usuarioActualizado.nombres,
        apellidos: usuarioActualizado.apellidos,
        correo: usuarioActualizado.correo,
        celular: usuarioActualizado.celular,
        rol: usuarioActualizado.rol,
        documentoIdentidad: usuarioActualizado.documentoIdentidad
      }
    });
  } catch (error) {
    console.error(error);
    return res.status(500).json({ ok: false, mensaje: 'Error al actualizar el perfil' });
  }
};