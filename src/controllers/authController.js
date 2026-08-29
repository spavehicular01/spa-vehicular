const User = require('../models/User');
const emailService = require('../services/emailService');

// 1. Iniciar Sesión (Login)
exports.login = async (req, res) => {
  try {
    const { email, password } = req.body;

    const user = await User.findOne({ correo: email });
    if (!user) {
      return res.status(404).json({ ok: false, mensaje: 'Usuario no encontrado' });
    }

    if (user.password !== password) {
      return res.status(400).json({ ok: false, mensaje: 'Contraseña incorrecta' });
    }

    return res.status(200).json({
      ok: true,
      mensaje: 'Inicio de sesión exitoso',
      usuario: {
        id: user._id,
        nombres: user.nombres,
        apellidos: user.apellidos,
        correo: user.correo,
        rol: user.rol,
        documentoIdentidad: user.documentoIdentidad,
        celular: user.celular
      }
    });
  } catch (error) {
    return res.status(500).json({ ok: false, mensaje: 'Error al iniciar sesión' });
  }
};

// 2. Registrar usuario
exports.registro = async (req, res) => {
  try {
    const { nombres, apellidos, documentoIdentidad, correo, celular, password } = req.body;

    const existeUsuario = await User.findOne({ 
      $or: [{ correo }, { documentoIdentidad }] 
    });

    if (existeUsuario) {
      return res.status(400).json({ 
        ok: false, 
        mensaje: 'El correo o documento de identidad ya están registrados' 
      });
    }

    const nuevoUsuario = new User({
      nombres,
      apellidos,
      documentoIdentidad,
      correo,
      celular,
      password
    });

    await nuevoUsuario.save();

    return res.status(201).json({
      ok: true,
      mensaje: 'Usuario registrado con éxito',
      usuario: nuevoUsuario
    });
  } catch (error) {
    return res.status(500).json({ ok: false, mensaje: 'Error al registrar el usuario' });
  }
};

// 3. Solicitar código de recuperación
exports.solicitarCodigoRecuperacion = async (req, res) => {
  try {
    const { email } = req.body;
    const user = await User.findOne({ correo: email });

    if (!user) {
      return res.status(404).json({ ok: false, mensaje: 'El correo no se encuentra registrado' });
    }

    // Generar código aleatorio de 6 dígitos
    const codigo = Math.floor(100000 + Math.random() * 900000).toString();

    user.resetPasswordCode = codigo;
    user.resetPasswordExpires = new Date(Date.now() + 15 * 60 * 1000);
    await user.save();

    console.log(`[CÓDIGO REPORTE FORGOT PASSWORD PARA ${email}]: ${codigo}`);

    // Envío de correo usando tu servicio existente en src/services/emailService.js
    if (emailService && typeof emailService.enviarCorreo === 'function') {
      await emailService.enviarCorreo(
        email,
        'Código de Recuperación de Contraseña - SPA Vehicular',
        `Tu código de verificación de 6 dígitos para restablecer tu contraseña es: ${codigo}`
      );
    }

    return res.status(200).json({ ok: true, mensaje: 'Código enviado correctamente' });
  } catch (error) {
    console.error(error);
    return res.status(500).json({ ok: false, mensaje: 'Error interno en el servidor' });
  }
};

// 4. Restablecer la contraseña
exports.restablecerPassword = async (req, res) => {
  try {
    const { email, codigo, nuevaPassword } = req.body;
    const user = await User.findOne({ correo: email });

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
    user.resetPasswordCode = null;
    user.resetPasswordExpires = null;
    await user.save();

    return res.status(200).json({ ok: true, mensaje: 'Contraseña actualizada con éxito' });
  } catch (error) {
    return res.status(500).json({ ok: false, mensaje: 'Error al cambiar la contraseña' });
  }
};