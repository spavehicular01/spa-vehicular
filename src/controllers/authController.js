const User = require('../models/User');
const jwt = require('jsonwebtoken');
const bcrypt = require('bcryptjs');

// Registrar usuario (RF001)
exports.registrarUser = async (req, res) => {
  try {
    const { nombres, apellidos, documentoIdentidad, correo, celular, password, rol } = req.body;

    // 1. Verificar si el usuario ya existe
    const existeUsuario = await User.findOne({ correo });
    if (existeUsuario) {
      return res.status(400).json({ mensaje: 'El correo ya está registrado' });
    }

    // 2. Encriptar la contraseña
    const salt = await bcrypt.genSalt(10);
    const passwordEncriptado = await bcrypt.hash(password, salt);

    // 3. Crear el nuevo usuario
    const nuevoUsuario = new User({
      nombres,
      apellidos,
      documentoIdentidad,
      correo,
      celular,
      password: passwordEncriptado,
      rol: rol || 'cliente'
    });

    await nuevoUsuario.save();

    // 4. Limpiar la respuesta sin exponer el hash
    const usuarioRespuesta = nuevoUsuario.toObject();
    delete usuarioRespuesta.password;

    res.status(201).json({ 
      mensaje: 'Usuario registrado con éxito', 
      usuario: usuarioRespuesta 
    });
  } catch (error) {
    res.status(500).json({ mensaje: 'Error al registrar usuario', error: error.message });
  }
};

// Iniciar sesión (RF003)
exports.loginUser = async (req, res) => {
  console.log('🔥🔥 ¡ENTRÓ AL LOGIN DE AUTHCONTROLLER! 🔥🔥');
  try {
    const { correo, password } = req.body;

    // 1. Buscar usuario por correo únicamente
    const usuario = await User.findOne({ correo });
    if (!usuario) {
      console.log('❌ Usuario no encontrado:', correo);
      return res.status(401).json({ mensaje: 'Credenciales inválidas' });
    }

    // 2. Comparar la contraseña ingresada con el hash o texto de la BD
    let esValido = await bcrypt.compare(password, usuario.password);
    
    // Soporte de compatibilidad si el usuario antiguo tenía contraseña en texto plano
    if (!esValido && password === usuario.password) {
      esValido = true;
    }

    if (!esValido) {
      console.log('❌ Contraseña incorrecta para:', correo);
      return res.status(401).json({ mensaje: 'Credenciales inválidas' });
    }

    // 3. Generar el Token JWT
    const token = jwt.sign(
      { 
        id: usuario._id, 
        correo: usuario.correo, 
        rol: usuario.rol 
      },
      process.env.JWT_SECRET || 'clave_secreta_provisoria',
      { expiresIn: '8h' }
    );

    console.log('✅ Token generado con éxito:', token);

    // 4. Ocultar contraseña en la respuesta
    const usuarioRespuesta = usuario.toObject();
    delete usuarioRespuesta.password;

    res.json({
      mensaje: 'Inicio de sesión exitoso',
      token,
      usuario: usuarioRespuesta
    });
  } catch (error) {
    console.error('🔥 Error en loginUser:', error);
    res.status(500).json({ mensaje: 'Error al iniciar sesión', error: error.message });
  }
};