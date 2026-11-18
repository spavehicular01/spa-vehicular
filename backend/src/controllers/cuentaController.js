import jwt from 'jsonwebtoken';
import bcrypt from 'bcryptjs';
import mongoose from 'mongoose';
import User from '../models/User.js';
import Appointment from '../models/Appointment.js';
import Vehicle from '../models/Vehicle.js';
import DeviceToken from '../models/DeviceToken.js';
import Notification from '../models/Notification.js';
import Review from '../models/Review.js';

const esAdmin = (rol) => String(rol || '').toLowerCase() === 'admin';

// Borra una cuenta y sus datos personales.
// La usa la app ahora y, más adelante, la página web de eliminación.
export const eliminarCuentaDeUsuario = async (user) => {
  // Protección: no se puede borrar al único administrador del sistema
  if (esAdmin(user.rol)) {
    const otrosAdmins = await User.countDocuments({
      _id: { $ne: user._id },
      rol: { $in: ['admin', 'ADMIN'] },
    });

    if (otrosAdmins === 0) {
      return {
        ok: false,
        status: 403,
        mensaje:
          'No puedes eliminar la cuenta del único administrador. Crea otro administrador antes de eliminar esta cuenta.',
      };
    }
  }

  const usuarioId = user._id;

  // Correo "vacío" pero único para cada cuenta eliminada. La base de datos tiene
  // un índice que no permite dos cuentas sin correo, así que no se puede dejar en blanco.
  // No identifica a nadie: solo lleva el id interno del registro.
  const correoAnonimo = `eliminado-${usuarioId}@cuenta-eliminada.invalid`;

  // 1. La cuenta se anonimiza primero: se quitan todos los datos personales y el acceso.
  //    El registro queda sin nombre real, correo, teléfono ni documento, solo para que
  //    las citas y pagos antiguos sigan funcionando sin mostrar a la persona.
  await User.updateOne(
    { _id: usuarioId },
    {
      $set: {
        nombres: 'Usuario',
        Nombre: 'USUARIO',
        apellidos: 'eliminado',
        Apellido: 'ELIMINADO',
        correo: correoAnonimo,
        Correo_Electronico: correoAnonimo,
        avatar: '',
        rol: 'usuario',
        isVerified: false,
        codigoVerificacion: null,
        codigoVerif: null,
        codigoVerificacionExpiracion: null,
        codigoVerificacionExpira: null,
        resetPasswordCode: null,
        resetPasswordExpires: null,
        codigoRecuperacion: null,
        codigoRecuperacionExpiracion: null,
        eliminado: true,
        fechaEliminacion: new Date(),
      },
      $unset: {
        celular: '',
        telefono: '',
        documentoIdentidad: '',
        password: '',
        passwords: '',
        googleId: '',
      },
    }
  );

  // 2. Se borran por completo los datos que solo sirven a esta persona
  await DeviceToken.deleteMany({ usuarioId });
  await Notification.deleteMany({ usuarioId });
  await Review.deleteMany({ usuarioId });
  // 'opinion.js' es un modelo antiguo que no se puede importar aquí, así que se
  // borra directo de su colección (si no existe o está vacía, no pasa nada).
  await mongoose.connection.collection('opinions').deleteMany({ usuarioId });

  // 3. Vehículos: se borran los que no aparecen en ninguna cita.
  //    Los que sí aparecen se conservan para no dejar el historial de citas roto.
  const vehiculosEnCitas = await Appointment.distinct('vehiculoId', { usuarioId });
  await Vehicle.deleteMany({ usuarioId, _id: { $nin: vehiculosEnCitas } });

  return { ok: true };
};

// POST /api/auth/cuenta/eliminar  (el usuario debe haber iniciado sesión)
export const eliminarMiCuenta = async (req, res) => {
  try {
    // 1. Leer y validar el token de sesión
    const encabezado = req.headers.authorization || '';
    const token = encabezado.startsWith('Bearer ') ? encabezado.slice(7) : null;

    if (!token) {
      return res
        .status(401)
        .json({ ok: false, mensaje: 'Sesión no válida. Inicia sesión de nuevo.' });
    }

    let payload;
    try {
      payload = jwt.verify(token, process.env.JWT_SECRET);
    } catch {
      return res
        .status(401)
        .json({ ok: false, mensaje: 'Tu sesión venció. Inicia sesión de nuevo.' });
    }

    // 2. Buscar al usuario
    const user = await User.findById(payload.id);
    if (!user) {
      return res.status(404).json({ ok: false, mensaje: 'Usuario no encontrado' });
    }

    // 3. Confirmación: debe escribir ELIMINAR
    const { confirmacion, password } = req.body || {};
    if (String(confirmacion || '').trim().toUpperCase() !== 'ELIMINAR') {
      return res
        .status(400)
        .json({ ok: false, mensaje: 'Escribe ELIMINAR para confirmar.' });
    }

    // 4. Si la cuenta tiene contraseña, también se pide (las de Google no tienen)
    const hash = user.password || user.passwords;
    if (hash) {
      if (!password) {
        return res.status(400).json({
          ok: false,
          requierePassword: true,
          mensaje: 'Escribe tu contraseña para confirmar.',
        });
      }
      const passwordValida = await bcrypt.compare(password, hash);
      if (!passwordValida) {
        return res.status(400).json({ ok: false, mensaje: 'Contraseña incorrecta' });
      }
    }

    // 5. Eliminar
    const resultado = await eliminarCuentaDeUsuario(user);
    if (!resultado.ok) {
      return res.status(resultado.status).json({ ok: false, mensaje: resultado.mensaje });
    }

    return res.status(200).json({
      ok: true,
      mensaje: 'Tu cuenta y tus datos personales fueron eliminados.',
    });
  } catch (error) {
    console.error('Error al eliminar la cuenta:', error);
    return res
      .status(500)
      .json({ ok: false, mensaje: 'Error al eliminar la cuenta', error: error.message });
  }
};

export default { eliminarMiCuenta, eliminarCuentaDeUsuario };