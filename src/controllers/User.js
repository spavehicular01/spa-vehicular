import User from "../models/User.js";
import bcrypt from "bcryptjs";
import { enviarCodigoVerificacion } from "../utils/mailer.js";

// 1. REGISTRO Y ENVÍO DEL CÓDIGO
export const registrarUsers = async (req, res) => {
  try {
    const { nombre, apellidos, documentoIdentidad, Correo_Electronico, celular, password } = req.body;

    if (!nombre || !apellidos || !documentoIdentidad || !Correo_Electronico || !celular || !password) {
      return res.status(400).json({ message: "Todos los campos son obligatorios" });
    }

    const existeUser = await User.findOne({ Correo_Electronico });
    if (existeUser) {
      return res.status(400).json({ message: "El correo electrónico ya está registrado" });
    }

    const codigo = Math.floor(100000 + Math.random() * 900000).toString();
    const expiracion = new Date(Date.now() + 15 * 60 * 1000);

    const nuevoUser = new User({
      nombres: nombre,
      apellidos,
      documentoIdentidad,
      correo: Correo_Electronico,
      celular,
      password,
      codigoVerificacion: codigo,
      codigoVerificacionExpiracion: expiracion,
      isVerified: false
    });

    await nuevoUser.save();
    await enviarCodigoVerificacion(Correo_Electronico, nombre, codigo);

    res.status(200).json({
      message: "Hemos enviado un código de 6 dígitos a su correo para completar el registro.",
      correo: Correo_Electronico
    });

  } catch (error) {
    console.error("Error en registro:", error);
    res.status(500).json({ message: "Error interno al registrar el usuario" });
  }
};

// 2. VERIFICACIÓN DEL CÓDIGO EN PANTALLA
export const verificarCuenta = async (req, res) => {
  try {
    const { Correo_Electronico, codigo } = req.body;

    if (!Correo_Electronico || !codigo) {
      return res.status(400).json({ message: "El correo y el código son obligatorios" });
    }

    const user = await User.findOne({ correo: Correo_Electronico });

    if (!user) {
      return res.status(404).json({ message: "Usuario no encontrado" });
    }

    if (user.isVerified) {
      return res.status(400).json({ message: "Esta cuenta ya ha sido verificada" });
    }

    if (user.codigoVerificacion !== codigo.trim()) {
      return res.status(400).json({ message: "El código ingresado es incorrecto" });
    }

    if (user.codigoVerificacionExpiracion < new Date()) {
      return res.status(400).json({ message: "El código ha expirado. Solicite uno nuevo." });
    }

    user.isVerified = true;
    user.codigoVerificacion = undefined;
    user.codigoVerificacionExpiracion = undefined;
    await user.save();

    res.status(200).json({
      message: "¡Su registro fue exitoso! Ya puede iniciar sesión."
    });

  } catch (error) {
    console.error("Error en verificación:", error);
    res.status(500).json({ message: "Error interno al verificar la cuenta" });
  }
};

// 3. REENVIAR CÓDIGO SI EXPIRÓ O NO LLEGÓ
export const reenviarCodigoVerificacion = async (req, res) => {
  try {
    const { Correo_Electronico } = req.body;

    if (!Correo_Electronico) {
      return res.status(400).json({ message: "El correo electrónico es requerido" });
    }

    const user = await User.findOne({ correo: Correo_Electronico });

    if (!user) {
      return res.status(404).json({ message: "No existe una cuenta con este correo" });
    }

    if (user.isVerified) {
      return res.status(400).json({ message: "Esta cuenta ya se encuentra verificada" });
    }

    const nuevoCodigo = Math.floor(100000 + Math.random() * 900000).toString();
    user.codigoVerificacion = nuevoCodigo;
    user.codigoVerificacionExpiracion = new Date(Date.now() + 15 * 60 * 1000);
    await user.save();

    await enviarCodigoVerificacion(user.correo, user.nombres, nuevoCodigo);

    res.status(200).json({
      message: "Se ha enviado un nuevo código de 6 dígitos a su correo."
    });

  } catch (error) {
    console.error("Error al reenviar código:", error);
    res.status(500).json({ message: "Error interno al reenviar el código" });
  }
};

// 4. INICIO DE SESIÓN (LOGIN)
export const login = async (req, res) => {
  try {
    const { Correo_Electronico, passwords } = req.body;

    if (!Correo_Electronico || !passwords) {
      return res.status(400).json({ message: "Correo y contraseña requeridos" });
    }

    // 1. Buscar al usuario
    const user = await User.findOne({ correo: Correo_Electronico });
    if (!user) {
      return res.status(404).json({ message: "Usuario no encontrado" });
    }

    // 2. Verificar contraseña con bcrypt
    const passwordCorrecto = await bcrypt.compare(passwords, user.password);
    if (!passwordCorrecto) {
      return res.status(400).json({ message: "Contraseña incorrecta" });
    }

    // 3. BLOQUEO: Verificar si completó el código de 6 dígitos
    if (!user.isVerified) {
      return res.status(403).json({
        message: "Tu cuenta no está verificada. Por favor ingresa el código enviado a tu correo antes de iniciar sesión."
      });
    }

    // 4. Si está verificado, acceso concedido
    res.status(200).json({
      message: "Inicio de sesión exitoso",
      usuario: {
        id: user._id,
        Nombre: user.nombres,
        Correo_Electronico: user.correo,
        rol: user.rol
      }
    });

  } catch (error) {
    console.error("Error en login:", error);
    res.status(500).json({ message: "Error interno en el inicio de sesión" });
  }
};