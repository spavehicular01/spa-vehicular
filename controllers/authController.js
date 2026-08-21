import User from "../models/user.js"; // Asegúrate de ajustar la ruta según tu modelo de usuarios

export const loginAdmin = async (req, res) => {
  try {
    const { email, password } = req.body;

    if (!email || !password) {
      return res.status(400).json({ message: "Por favor ingresa correo y contraseña" });
    }

    const usuario = await User.findOne({ email });
    if (!usuario) {
      return res.status(404).json({ message: "El usuario no existe" });
    }

    // Compara la contraseña directa o mediante el hash de tu proyecto
    if (usuario.password !== password) {
      return res.status(401).json({ message: "Contraseña incorrecta" });
    }

    res.status(200).json({
      message: "Inicio de sesión exitoso",
      user: {
        id: usuario._id,
        email: usuario.email,
        nombre: usuario.nombre,
      },
    });
  } catch (error) {
    console.error("Error en el login:", error);
    res.status(500).json({ message: "Error al iniciar sesión", error: error.message });
  }
};