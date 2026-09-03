import User from '../models/User.js';
import { enviarCodigoRecuperacion, enviarCodigoVerificacion } from '../utils/mailer.js';

// 1. Iniciar Sesión (Login)
export const login = async (req, res) => {
  try {
    const { email, password } = req.body;

    if (!email || !password) {
      return res.status(400).json({ 
        ok: false, 
        mensaje: 'El correo y la contraseña son requeridos' 
      });
    }

    const emailNormalizado = email.toLowerCase().trim();

    const user = await User.findOne({ 
      $or: [{ correo: emailNormalizado }, { Correo_Electronico: emailNormalizado }] 
    });

    if (!user) {
      return res.status(404).json({ ok: false, mensaje: 'Usuario no encontrado' });
    }

    if (user.isVerified === false) {
      return res.status(401).json({
        ok: false,
        mensaje: 'Debes verificar tu cuenta con el código enviado a tu correo antes de iniciar sesión.'
      });
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
    return res.status(500).json({ 
      ok: false, 
      mensaje: 'Error al iniciar sesión', 
      error: error.message 
    });
  }
};

// 2. Registrar usuario
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

    const emailVal = (correo || Correo_Electronico)?.toLowerCase().trim();
    const docVal = documentoIdentidad ? documentoIdentidad.toString().trim() : null;
    const passVal = password || passwords;
    const nombresVal = (nombres || Nombre)?.trim() || 'Usuario';
    const apellidosVal = (apellidos || Apellido)?.trim();
    const celularVal = (celular || telefono)?.trim();

    if (!emailVal || !passVal) {
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

    // Código de activación y expiración de 10 minutos
    const codigoVerif = Math.floor(100000 + Math.random() * 900000).toString();
    const expiracionVerif = new Date(Date.now() + 10 * 60 * 1000);
    const rolDefinido = rol ? rol.toLowerCase() : 'usuario';

    const nuevoUsuario = new User({
      nombres: nombresVal,
      apellidos: apellidosVal,
      correo: emailVal,
      celular: celularVal,
      password: passVal,
      documentoIdentidad: docVal,
      rol: rolDefinido,

      Nombre: nombresVal,
      Apellido: apellidosVal,
      Correo_Electronico: emailVal,
      telefono: celularVal,
      passwords: passVal,

      isVerified: false,
      codigoVerificacion: codigoVerif,
      codigoVerif: codigoVerif,
      codigoVerificacionExpiracion: expiracionVerif
    });

    await nuevoUsuario.save();

    // Envío seguro a mailer (Garantizando el orden correcto de parámetros o fallback)
    try {
      await enviarCodigoVerificacion(emailVal, codigoVerif, nombresVal);
      console.log(`[CÓDIGO DE VERIFICACIÓN ENVIADO A ${emailVal}]: ${codigoVerif}`);
    } catch (emailError) {
      console.error('🔥 Error al despachar el correo Brevo:', emailError.message);
    }

    return res.status(201).json({
      ok: true,
      mensaje: 'Usuario registrado. Revisa tu correo para activar tu cuenta.',
      email: emailVal,
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

// 3. Confirmar / Verificar la cuenta mediante código
export const confirmarCuenta = async (req, res) => {
  try {
    const { email, correo, codigo, codigoVerificacion } = req.body;
    const emailVal = (email || correo)?.toLowerCase().trim();
    const codigoVal = (codigo || codigoVerificacion)?.toString().trim();

    if (!emailVal || !codigoVal) {
      return res.status(400).json({ ok: false, mensaje: 'El correo y el código son requeridos' });
    }

    const user = await User.findOne({
      $or: [{ correo: emailVal }, { Correo_Electronico: emailVal }]
    });

    if (!user) {
      return res.status(404).json({ ok: false, mensaje: 'Usuario no encontrado' });
    }

    const codigoGuardado = user.codigoVerificacion || user.codigoVerif;

    if (codigoGuardado !== codigoVal) {
      return res.status(400).json({ ok: false, mensaje: 'El código de verificación es incorrecto' });
    }

    if (new Date() > new Date(user.codigoVerificacionExpiracion)) {
      return res.status(400).json({ ok: false, mensaje: 'El código ha expirado. Solicita uno nuevo.' });
    }

    user.isVerified = true;
    user.codigoVerificacion = null;
    user.codigoVerif = null;
    user.codigoVerificacionExpiracion = null;
    await user.save();

    return res.status(200).json({
      ok: true,
      mensaje: 'Cuenta verificada exitosamente'
    });
  } catch (error) {
    return res.status(500).json({ ok: false, mensaje: 'Error al verificar la cuenta', error: error.message });
  }
};

// 4. Reenviar Código de Verificación de Cuenta
export const reenviarCodigoVerificacion = async (req, res) => {
  try {
    const { email, correo } = req.body;
    const emailVal = (email || correo)?.toLowerCase().trim();

    if (!emailVal) {
      return res.status(400).json({ ok: false, mensaje: 'El correo electrónico es requerido' });
    }

    const user = await User.findOne({
      $or: [{ correo: emailVal }, { Correo_Electronico: emailVal }]
    });

    if (!user) {
      return res.status(404).json({ ok: false, mensaje: 'Usuario no encontrado' });
    }

    if (user.isVerified) {
      return res.status(400).json({ ok: false, mensaje: 'Esta cuenta ya se encuentra verificada' });
    }

    const nuevoCodigo = Math.floor(100000 + Math.random() * 900000).toString();
    const nuevaExpiracion = new Date(Date.now() + 10 * 60 * 1000);
    const nombreUsuario = user.nombres || user.Nombre || 'Usuario';

    user.codigoVerificacion = nuevoCodigo;
    user.codigoVerif = nuevoCodigo;
    user.codigoVerificacionExpiracion = nuevaExpiracion;
    await user.save();

    await enviarCodigoVerificacion(emailVal, nuevoCodigo, nombreUsuario);
    console.log(`[CÓDIGO REENVIADO A ${emailVal}]: ${nuevoCodigo}`);

    return res.status(200).json({
      ok: true,
      mensaje: 'Nuevo código de verificación enviado al correo'
    });
  } catch (error) {
    console.error('Error al reenviar código:', error);
    return res.status(500).json({ ok: false, mensaje: 'Error al reenviar el código', error: error.message });
  }
};

// 5. Solicitar código de recuperación (Forgot Password)
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
    const nombreUsuario = user.nombres || user.Nombre || 'Usuario';

    user.resetPasswordCode = codigo;
    user.resetPasswordExpires = new Date(Date.now() + 10 * 60 * 1000);
    await user.save();

    console.log(`[CÓDIGO FORGOT PASSWORD PARA ${emailNormalizado}]: ${codigo}`);

    await enviarCodigoRecuperacion(emailNormalizado, codigo, nombreUsuario);

    return res.status(200).json({ ok: true, mensaje: 'Código enviado correctamente al correo' });
  } catch (error) {
    console.error('Error en solicitarCodigoRecuperacion:', error);
    return res.status(500).json({ ok: false, mensaje: 'Error interno en el servidor', error: error.message });
  }
};

// 6. Restablecer la contraseña
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
  confirmarCuenta,
  reenviarCodigoVerificacion,
  solicitarCodigoRecuperacion,
  restablecerPassword
};