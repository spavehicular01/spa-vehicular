import { OAuth2Client } from "google-auth-library";
import jwt from "jsonwebtoken";
import User from "../models/User.js";

// Client ID cargado limpiamente desde variables de entorno
const client = new OAuth2Client(process.env.GOOGLE_CLIENT_ID);

// "DIDIER" -> "Didier" (el esquema guarda Nombre/Apellido en mayúsculas)
const capitalizar = (texto = "") =>
  String(texto)
    .toLowerCase()
    .replace(/(^|\s)\S/g, (letra) => letra.toUpperCase())
    .trim();

// Misma forma en que el login normal devuelve al usuario,
// incluyendo documento y teléfono para que la app sepa si faltan.
const formatearUsuario = (u) => {
  const documento = u.documentoIdentidad || "";
  const celular = u.celular || u.telefono || "";
  const correo = u.correo || u.Correo_Electronico || "";

  return {
    id: u._id,
    _id: u._id,
    nombres: u.nombres || capitalizar(u.Nombre),
    apellidos: u.apellidos || capitalizar(u.Apellido),
    correo,
    email: correo,
    celular,
    telefono: celular,
    documentoIdentidad: documento,
    documento,
    rol: u.rol,
    avatar: u.avatar || "",
  };
};

export const loginWithGoogle = async (req, res) => {
  try {
    const { idToken } = req.body;

    if (!idToken) {
      return res.status(400).json({ message: "El token de Google es requerido" });
    }

    let googleId, email, given_name, family_name, picture, emailVerificado;

    // Regla de detección: Un JWT tiene 3 partes separadas por punto y no inicia por ya29.
    const esJwt = idToken.split(".").length === 3 && !idToken.startsWith("ya29.");

    if (esJwt) {
      // 1. Caso Android / iOS: Verificación formal mediante biblioteca oficial
      const ticket = await client.verifyIdToken({
        idToken,
        audience: process.env.GOOGLE_CLIENT_ID,
      });

      const payload = ticket.getPayload();
      googleId = payload.sub;
      email = payload.email;
      given_name = payload.given_name;
      family_name = payload.family_name;
      picture = payload.picture;
      emailVerificado = payload.email_verified;
    } else {
      // 2. Caso Flutter Web: Consulta a la API UserInfo oficial de Google
      const userInfoResponse = await fetch(
        "https://www.googleapis.com/oauth2/v3/userinfo",
        {
          headers: { Authorization: `Bearer ${idToken}` },
        }
      );

      if (!userInfoResponse.ok) {
        throw new Error("El token de acceso de Google no es válido o expiró");
      }

      const userData = await userInfoResponse.json();
      googleId = userData.sub;
      email = userData.email;
      given_name = userData.given_name || userData.name || "Usuario";
      family_name = userData.family_name || "";
      picture = userData.picture;
      emailVerificado = userData.email_verified;
    }

    if (!email) {
      return res.status(400).json({ message: "Google no proporcionó un email válido" });
    }

    // Solo se vincula por correo si Google confirma que el correo es del usuario
    if (emailVerificado === false) {
      return res.status(401).json({ message: "El correo de Google no está verificado" });
    }

    const correoLimpio = email.toLowerCase().trim();

    // Busca por cualquiera de los dos campos de correo: así una cuenta creada
    // con el registro de la app también se reconoce al entrar con Google.
    let usuario = await User.findOne({
      $or: [{ Correo_Electronico: correoLimpio }, { correo: correoLimpio }],
    });

    if (usuario) {
      if (!usuario.googleId) usuario.googleId = googleId;
      if (!usuario.isVerified) {
        usuario.isVerified = true;
        usuario.codigoVerificacion = undefined;
        usuario.codigoVerificacionExpiracion = undefined;
      }
      if (!usuario.avatar && picture) usuario.avatar = picture;

      // Completa los campos "nuevos" si la cuenta solo tenía los antiguos
      // (así el nombre ya no sale como "DIDIER" en mayúsculas).
      if (!usuario.nombres && usuario.Nombre) usuario.nombres = capitalizar(usuario.Nombre);
      if (!usuario.apellidos && usuario.Apellido) usuario.apellidos = capitalizar(usuario.Apellido);
      if (!usuario.correo) usuario.correo = correoLimpio;
      if (!usuario.Correo_Electronico) usuario.Correo_Electronico = correoLimpio;

      await usuario.save();
    } else {
      // Crear nuevo usuario verificado por defecto.
      // Documento y teléfono quedan vacíos: la app los pide una sola vez.
      const nombre = capitalizar(given_name) || "Usuario";
      const apellido = capitalizar(family_name);

      usuario = new User({
        nombres: nombre,
        Nombre: nombre,
        apellidos: apellido,
        Apellido: apellido,
        correo: correoLimpio,
        Correo_Electronico: correoLimpio,
        googleId,
        avatar: picture || "",
        isVerified: true,
        rol: "usuario",
      });
      await usuario.save();
    }

    // Firmar el JWT propio de la aplicación
    // Mismo contenido y duración que el token del login normal (authController),
    // para que los middlewares y el WebSocket lean `rol` y `correo` igual.
    const token = jwt.sign(
      {
        id: usuario._id,
        correo: usuario.correo || usuario.Correo_Electronico,
        rol: usuario.rol,
      },
      process.env.JWT_SECRET,
      { expiresIn: "7d" }
    );

    const datosUsuario = formatearUsuario(usuario);

    return res.status(200).json({
      ok: true,
      success: true,
      message: "Inicio de sesión con Google exitoso",
      mensaje: "Inicio de sesión con Google exitoso",
      token,
      // true si todavía faltan documento o teléfono
      requierePerfil: !(datosUsuario.documento && datosUsuario.celular),
      usuario: datosUsuario,
    });
  } catch (error) {
    console.error("Error al autenticar con Google:", error);
    return res.status(401).json({
      message: "Token de Google inválido o expirado",
      error: error.message,
    });
  }
};