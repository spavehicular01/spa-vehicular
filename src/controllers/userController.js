import User from '../models/User.js';
import Vehicle from '../models/Vehicle.js';
import bcrypt from 'bcryptjs';

// Id del usuario autenticado (lo pone verifyToken en req.user)
const idDelToken = (req) =>
  req.user?.id || req.user?._id || req.user?.userId || req.userId;

// Forma única en que se devuelve un usuario al frontend
const formatearUsuario = (u) => ({
  id: u._id,
  _id: u._id,
  nombres: u.nombres || u.Nombre,
  apellidos: u.apellidos || u.Apellido,
  correo: u.correo || u.Correo_Electronico,
  celular: u.celular || u.telefono,
  telefono: u.celular || u.telefono,
  rol: u.rol,
  documentoIdentidad: u.documentoIdentidad,
  documento: u.documentoIdentidad,
  avatar: u.avatar
});

// Obtener el perfil actual del usuario autenticado (lo usa la app para saber
// si ya tiene documento y teléfono guardados)
export const obtenerMiPerfil = async (req, res) => {
  try {
    const userId = idDelToken(req);
    const user = userId ? await User.findById(userId) : null;

    if (!user) {
      return res.status(404).json({ ok: false, mensaje: 'Usuario no encontrado' });
    }

    return res.status(200).json({ ok: true, usuario: formatearUsuario(user) });
  } catch (error) {
    console.error('Error al obtener mi perfil:', error);
    return res.status(500).json({ ok: false, mensaje: 'Error interno al obtener el perfil' });
  }
};

// Actualizar perfil de usuario
export const actualizarPerfil = async (req, res) => {
  const responderError = (status, texto) =>
    res.status(status).json({ ok: false, success: false, message: texto, mensaje: texto });

  try {
    const { id } = req.params;
    const { nombres, apellidos, celular, documentoIdentidad } = req.body;

    const usuario = await User.findById(id);
    if (!usuario) {
      return responderError(404, 'Usuario no encontrado');
    }

    // Solo se actualizan los campos que realmente llegaron con valor
    const datosActualizar = {};

    if (nombres !== undefined && String(nombres).trim()) {
      datosActualizar.nombres = String(nombres).trim();
    }
    if (apellidos !== undefined && String(apellidos).trim()) {
      datosActualizar.apellidos = String(apellidos).trim();
    }
    if (celular !== undefined && String(celular).trim()) {
      datosActualizar.celular = String(celular).trim();
      datosActualizar.telefono = String(celular).trim();
    }

    // El documento se puede guardar UNA sola vez: si la cuenta ya tiene uno, no se cambia.
    if (documentoIdentidad !== undefined && String(documentoIdentidad).trim()) {
      const doc = String(documentoIdentidad).trim();

      if (usuario.documentoIdentidad) {
        if (usuario.documentoIdentidad !== doc) {
          return responderError(400, 'El documento de identidad no se puede modificar');
        }
      } else {
        const repetido = await User.findOne({ documentoIdentidad: doc, _id: { $ne: usuario._id } });
        if (repetido) {
          return responderError(400, 'Ese documento ya está registrado en otra cuenta');
        }
        datosActualizar.documentoIdentidad = doc;
      }
    }

    // Si la imagen viene procesada por Multer / Cloudinary
    if (req.file) {
      datosActualizar.avatar = req.file.path || req.file.secure_url;
    } else if (req.body.avatar) {
      datosActualizar.avatar = req.body.avatar;
    }

    const usuarioActualizado = await User.findByIdAndUpdate(
      id,
      datosActualizar,
      { returnDocument: 'after' }
    );

    return res.status(200).json({
      ok: true,
      success: true,
      message: 'Perfil actualizado correctamente',
      mensaje: 'Perfil actualizado correctamente',
      usuario: formatearUsuario(usuarioActualizado)
    });
  } catch (error) {
    console.error('Error al actualizar el perfil:', error);
    return responderError(500, 'Error interno al actualizar el perfil');
  }
};

// Cambiar contraseña del usuario autenticado
export const cambiarPassword = async (req, res) => {
  // Se responde con ambos estilos de claves (success/message y ok/mensaje)
  const responder = (status, exito, texto) =>
    res.status(status).json({ success: exito, ok: exito, message: texto, mensaje: texto });

  try {
    const { currentPassword, newPassword } = req.body;

    if (!currentPassword || !newPassword || newPassword.length < 6) {
      return responder(400, false, 'La nueva contraseña debe tener mínimo 6 caracteres');
    }

    const userId = req.user?.id || req.user?._id || req.user?.userId || req.userId;
    const user = userId ? await User.findById(userId) : null;

    if (!user) {
      return responder(404, false, 'Usuario no encontrado');
    }

    const passActual = user.password || user.passwords;
    const coincide = await bcrypt.compare(currentPassword, passActual);
    if (!coincide) {
      return responder(400, false, 'La contraseña actual es incorrecta');
    }

    // Hash explícito en ambos campos; updateOne no dispara hooks de save,
    // así que no se hashea dos veces.
    const hash = await bcrypt.hash(newPassword, 10);
    await User.updateOne({ _id: user._id }, { $set: { password: hash, passwords: hash } });

    return responder(200, true, 'Contraseña actualizada');
  } catch (error) {
    console.error('Error al cambiar contraseña:', error);
    return responder(500, false, 'Error interno al cambiar la contraseña');
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
  obtenerMiPerfil,
  actualizarPerfil,
  cambiarPassword,
  obtenerClientes
};