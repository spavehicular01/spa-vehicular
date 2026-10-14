import bcrypt from 'bcrypt';
import User from '../models/User.js';
import Vehicle from '../models/Vehicle.js';
import bcrypt from 'bcryptjs';

// Actualizar perfil de usuario
export const actualizarPerfil = async (req, res) => {
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
      { returnDocument: 'after' }
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

// Cambiar la contraseña del usuario (pide la actual para confirmar que es él)
export const cambiarPassword = async (req, res) => {
  try {
    const { id } = req.params;
    const { passwordActual, nuevaPassword } = req.body;

    if (!passwordActual || !nuevaPassword) {
      return res.status(400).json({
        ok: false,
        mensaje: 'Debes enviar la contraseña actual y la nueva'
      });
    }

    if (String(nuevaPassword).length < 6) {
      return res.status(400).json({
        ok: false,
        mensaje: 'La nueva contraseña debe tener al menos 6 caracteres'
      });
    }

    const user = await User.findById(id);
    if (!user) {
      return res.status(404).json({ ok: false, mensaje: 'Usuario no encontrado' });
    }

    // Se usa 400 (y no 401) para que la app no lo confunda con una sesión vencida
    const hashActual = user.password || user.passwords;
    const coincide = hashActual ? await bcrypt.compare(String(passwordActual), hashActual) : false;
    if (!coincide) {
      return res.status(400).json({ ok: false, mensaje: 'La contraseña actual es incorrecta' });
    }

    const passwordHasheada = await bcrypt.hash(String(nuevaPassword), 10);
    user.password = passwordHasheada;
    if (user.passwords !== undefined) user.passwords = passwordHasheada;
    await user.save();

    return res.status(200).json({ ok: true, mensaje: 'Contraseña actualizada correctamente' });
  } catch (error) {
    console.error('Error en cambiarPassword:', error);
    return res.status(500).json({ ok: false, mensaje: 'Error al cambiar la contraseña' });
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
  cambiarPassword,
  obtenerClientes
};