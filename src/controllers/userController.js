import User from '../models/User.js';
import Vehicle from '../models/Vehicle.js';

// Actualizar perfil de usuario
export const actualizarPerfil = async (req, res) => {
  try {
    const { id } = req.params;
    const { nombres, apellidos, celular } = req.body;

    // Construir objeto con los datos a actualizar
    const datosActualizar = { nombres, apellidos, celular };

    // Si la imagen viene procesada por Multer/Cloudinary
    if (req.file) {
      datosActualizar.avatar = req.file.path;
    } else if (req.body.avatar) {
      datosActualizar.avatar = req.body.avatar;
    }

    const usuarioActualizado = await User.findByIdAndUpdate(
      id,
      datosActualizar,
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
        documentoIdentidad: usuarioActualizado.documentoIdentidad,
        avatar: usuarioActualizado.avatar
      }
    });
  } catch (error) {
    console.error(error);
    return res.status(500).json({ ok: false, mensaje: 'Error al actualizar el perfil' });
  }
};

// Obtener todos los clientes con sus vehículos (Panel Admin)
export const obtenerClientes = async (req, res) => {
  try {
    const clientes = await User.find({
      rol: { $in: ['usuario', 'cliente', 'USUARIO', 'CLIENTE'] }
    })
      .select('nombres Nombre apellidos Apellido correo Correo_Electronico celular telefono documentoIdentidad avatar')
      .lean();

    const clienteIds = clientes.map(c => c._id);
    const vehiculos = await Vehicle.find({ usuarioId: { $in: clienteIds } }).lean();

    const vehiculosPorUsuario = {};
    vehiculos.forEach(v => {
      const key = v.usuarioId.toString();
      if (!vehiculosPorUsuario[key]) vehiculosPorUsuario[key] = [];
      vehiculosPorUsuario[key].push(v);
    });

    const clientesConVehiculos = clientes.map(c => ({
      ...c,
      nombreCompleto: `${c.nombres || c.Nombre || ''} ${c.apellidos || c.Apellido || ''}`.trim(),
      correoNormalizado: c.correo || c.Correo_Electronico || '',
      telefonoNormalizado: c.celular || c.telefono || '',
      vehiculos: vehiculosPorUsuario[c._id.toString()] || []
    }));

    res.status(200).json(clientesConVehiculos);
  } catch (error) {
    console.error('Error en obtenerClientes:', error);
    res.status(500).json({ mensaje: 'Error al obtener clientes', error: error.message });
  }
};

export default {
  actualizarPerfil,
  obtenerClientes
};