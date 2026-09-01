import User from '../models/User.js';
import { enviarCodigoRecuperacion } from '../utils/mailer.js';

// 1. Iniciar Sesión (Login)
export const login = async (req, res) => {
  try {
    const { email, password } = req.body;

    const user = await User.findOne({ 
      $or: [{ correo: email }, { Correo_Electronico: email }] 
    });

    if (!user) {
      return res.status(404).json({ ok: false, mensaje: 'Usuario no encontrado' });
    }

    const passUser = user.password || user.passwords;
    if (passUser !== password) {
      return res.status(400).json({ ok: false, mensaje: 'Contraseña incorrecta' });
    }

    return res.status(200).json({
      ok: true,
      mensaje: 'Inicio de sesión exitoso',
      usuario: {
        id: user._id,
        nombres: user.nombres || user.Nombre,
        apellidos: user.apellidos || user.Apellido,
        correo: user.correo || user.Correo_Electronico,
        rol: user.rol,
        documentoIdentidad: user.documentoIdentidad,
        celular: user.celular || user.telefono
      }
    });
  } catch (error) {
    return res.status(500).json({ ok: false, mensaje: 'Error al iniciar sesión', error: error.message });
  }
};

// 2. Registrar usuario (Rol normalizado en mayúsculas)
export const registro = async (req, res) => {
  try {
    const { 
      nombres, Nombre, 
      apellidos, Apellido, 
      documentoIdentidad, 
      correo, Correo_Electronico, 
      celular, telefono, 
      password, passwords, 
      rol 
    } = req.body;

    const emailVal = correo || Correo_Electronico;
    const docVal = documentoIdentidad;

    if (!emailVal || (!password && !passwords)) {
      return res.status(400).json({ 
        ok: false, 
        mensaje: 'El correo y la contraseña son campos obligatorios.' 
      });
    }

    const existeUsuario = await User.findOne({ 
      $or: [
        { correo: emailVal }, 
        { Correo_Electronico: emailVal }, 
        ...(docVal ? [{ documentoIdentidad: docVal }] : [])
      ] 
    });

    if (existeUsuario) {
      return res.status(400).json({ 
        ok: false, 
        mensaje: 'El correo o documento de identidad ya están registrados' 
      });
    }

    // Normaliza el rol asignado a MAYÚSCULAS para cumplir el enum del Schema ('CLIENTE')
    const rolDefinido = rol ? rol.toUpperCase() : 'CLIENTE';

    // Remueve o ajusta la línea del rol y deja que Mongoose use el default del Schema:
    const nuevoUsuario = new User({
      nombres: nombres || Nombre,
      Nombre: Nombre || nombres,
      apellidos: apellidos || Apellido,
      Apellido: Apellido || apellidos,
      documentoIdentidad: docVal,
      correo: emailVal,
      Correo_Electronico: emailVal,
      celular: celular || telefono,
      telefono: telefono || celular,
      password: password || passwords,
      passwords: passwords || password,
      // Si el modelo requiere rol obligatoriamente, prueba mandando 'user' o 'Admin' según lo que veas en tu User.js
    });

    await nuevoUsuario.save();

    return res.status(201).json({
      ok: true,
      mensaje: 'Usuario registrado con éxito',
      usuario: nuevoUsuario
    });
  } catch (error) {
    console.error('🔥 Error exacto en registro:', error);
    return res.status(500).json({ 
      ok: false, 
      mensaje: 'Error al registrar el usuario', 
      error: error.message 
    });
  }
};

// 3. Solicitar código de recuperación
export const solicitarCodigoRecuperacion = async (req, res) => {
  try {
    const { email } = req.body;

    if (!email) {
      return res.status(400).json({ ok: false, mensaje: 'El correo electrónico es requerido' });
    }

    const emailNormalizado = email.toLowerCase().trim();

    const user = await User.findOne({ 
      $or: [{ correo: emailNormalizado }, { Correo_Electronico: emailNormalizado }] 
    });

    if (!user) {
      return res.status(404).json({ ok: false, mensaje: 'El correo no se encuentra registrado' });
    }

    const codigo = Math.floor(100000 + Math.random() * 900000).toString();

    user.resetPasswordCode = codigo;
    user.resetPasswordExpires = new Date(Date.now() + 15 * 60 * 1000);
    await user.save();

    console.log(`[CÓDIGO REPORTE FORGOT PASSWORD PARA ${emailNormalizado}]: ${codigo}`);

    await enviarCodigoRecuperacion(emailNormalizado, codigo);

    return res.status(200).json({ ok: true, mensaje: 'Código enviado correctamente al correo' });
  } catch (error) {
    console.error('Error en solicitarCodigoRecuperacion:', error);
    return res.status(500).json({ ok: false, mensaje: 'Error interno en el servidor', error: error.message });
  }
};

// 4. Restablecer la contraseña
export const restablecerPassword = async (req, res) => {
  try {
    const { email, codigo, nuevaPassword } = req.body;

    if (!email || !codigo || !nuevaPassword) {
      return res.status(400).json({ ok: false, mensaje: 'Todos los campos son requeridos' });
    }

    const emailNormalizado = email.toLowerCase().trim();

    const user = await User.findOne({ 
      $or: [{ correo: emailNormalizado }, { Correo_Electronico: emailNormalizado }] 
    });

    if (!user || !user.resetPasswordCode) {
      return res.status(400).json({ ok: false, mensaje: 'Solicitud inválida o no encontrada' });
    }

    if (user.resetPasswordCode !== codigo) {
      return res.status(400).json({ ok: false, mensaje: 'El código de 6 dígitos es incorrecto' });
    }

    if (new Date() > new Date(user.resetPasswordExpires)) {
      return res.status(400).json({ ok: false, mensaje: 'El código ha expirado' });
    }

    user.password = nuevaPassword;
    if (user.passwords !== undefined) user.passwords = nuevaPassword;
    user.resetPasswordCode = null;
    user.resetPasswordExpires = null;
    await user.save();

    return res.status(200).json({ ok: true, mensaje: 'Contraseña actualizada con éxito' });
  } catch (error) {
    return res.status(500).json({ ok: false, mensaje: 'Error al cambiar la contraseña', error: error.message });
  }
};

export default {
  login,
  registro,
  solicitarCodigoRecuperacion,
  restablecerPassword
};