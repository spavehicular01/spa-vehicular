const User = require('../models/User');

// Registrar usuario (RF001)
exports.registrarUser = async (req, res) => {
  try {
    const { nombres, apellidos, documentoIdentidad, correo, celular, password } = req.body;

    const existeUsuario = await User.findOne({ correo });
    if (existeUsuario) {
      return res.status(400).json({ mensaje: 'El correo ya está registrado' });
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
    res.status(201).json({ mensaje: 'Usuario registrado con éxito', usuario: nuevoUsuario });
  } catch (error) {
    res.status(500).json({ mensaje: 'Error al registrar usuario', error: error.message });
  }
};

// Iniciar sesión (RF003)
exports.loginUser = async (req, res) => {
  try {
    const { correo, password } = req.body;
    const usuario = await User.findOne({ correo, password });

    if (!usuario) {
      return res.status(401).json({ mensaje: 'Credenciales inválidas' });
    }

    res.json({ mensaje: 'Inicio de sesión exitoso', usuario });
  } catch (error) {
    res.status(500).json({ mensaje: 'Error al iniciar sesión', error: error.message });
  }
};