const User = require('../models/User');

// Actualizar perfil de usuario
exports.actualizarPerfil = async (req, res) => {
  try {
    const { id } = req.params;
    const { nombres, apellidos, celular } = req.body;

    // Construir objeto con los datos a actualizar
    const datosActualizar = { nombres, apellidos, celular };

    // Si la imagen viene procesada por Multer / Cloudinary
    if (req.file) {
      datosActualizar.avatar = req.file.path || req.file.secure_url;
    } else if (req.body.avatar) {
      datosActualizar.avatar = req.body.avatar;
    }

    const usuarioActualizado = await User.findByIdAndUpdate(
      id,
      datosActualizar,
      { new: true }
    );

    if (!usuarioActualizado) {
      return res.status(404).json({ 
        ok: false, 
        success: false, 
        message: 'Usuario no encontrado',
        mensaje: 'Usuario no encontrado' 
      });
    }

    return res.status(200).json({
      ok: true,
      success: true,
      message: 'Perfil actualizado correctamente',
      mensaje: 'Perfil actualizado correctamente',
      usuario: {
        id: usuarioActualizado._id,
        _id: usuarioActualizado._id,
        nombres: usuarioActualizado.nombres,
        apellidos: usuarioActualizado.apellidos,
        correo: usuarioActualizado.correo,
        celular: usuarioActualizado.celular,
        telefono: usuarioActualizado.celular,
        rol: usuarioActualizado.rol,
        documentoIdentidad: usuarioActualizado.documentoIdentidad,
        documento: usuarioActualizado.documentoIdentidad,
        avatar: usuarioActualizado.avatar
      }
    });
  } catch (error) {
    console.error('Error al actualizar el perfil:', error);
    return res.status(500).json({ 
      ok: false, 
      success: false, 
      message: 'Error interno al actualizar el perfil',
      mensaje: 'Error interno al actualizar el perfil' 
    });
  }
};