import { OAuth2Client } from "google-auth-library";
import jwt from "jsonwebtoken";
import User from "../models/User.js";

// Client ID cargado desde variables de entorno
const client = new OAuth2Client(process.env.GOOGLE_CLIENT_ID);

// Flujo web: el "idToken" es en realidad un access token de Google. Antes de creerle,
// se comprueba que Google lo haya emitido PARA ESTA APP (si no, cualquier token de otra
// aplicación serviría para entrar como ese usuario) y se leen los datos de la cuenta.
const leerCuentaConAccessToken = async (accessToken) => {
  const infoRes = await fetch(
    `https://oauth2.googleapis.com/tokeninfo?access_token=${encodeURIComponent(accessToken)}`
  );
  if (!infoRes.ok) {
    throw new Error("El token de acceso de Google no es válido o expiró");
  }

  const info = await infoRes.json();
  const clientId = process.env.GOOGLE_CLIENT_ID;
  if (info.aud !== clientId && info.azp !== clientId) {
    throw new Error("El token de Google no fue emitido para esta aplicación");
  }

  const userInfoRes = await fetch("https://www.googleapis.com/oauth2/v3/userinfo", {
    headers: { Authorization: `Bearer ${accessToken}` },
  });
  if (!userInfoRes.ok) {
    throw new Error("No se pudo leer la cuenta de Google");
  }

  const u = await userInfoRes.json();
  return {
    googleId: u.sub,
    email: u.email,
    emailVerificado: u.email_verified === true || u.email_verified === "true",
    nombre: u.given_name || u.name || "USUARIO",
    apellido: u.family_name || "",
    picture: u.picture,
  };
};

export const loginWithGoogle = async (req, res) => {
  try {
    const { idToken } = req.body;

    if (!idToken) {
      return res.status(400).json({ message: "El token de Google es requerido" });
    }

    let cuenta;

    // Un JWT tiene 3 partes separadas por punto y no inicia por ya29.
    const esJwt = idToken.split(".").length === 3 && !idToken.startsWith("ya29.");

    if (esJwt) {
      // Android / iOS: verificación formal con la biblioteca oficial
      // (firma, vencimiento y que el token sea para esta app)
      const ticket = await client.verifyIdToken({
        idToken,
        audience: process.env.GOOGLE_CLIENT_ID,
      });

      const payload = ticket.getPayload();
      cuenta = {
        googleId: payload.sub,
        email: payload.email,
        emailVerificado: payload.email_verified === true,
        nombre: payload.given_name || payload.name || "USUARIO",
        apellido: payload.family_name || "",
        picture: payload.picture,
      };
    } else {
      // Flutter Web
      cuenta = await leerCuentaConAccessToken(idToken);
    }

    if (!cuenta.email) {
      return res.status(400).json({ message: "Google no proporcionó un email válido" });
    }
    if (!cuenta.emailVerificado) {
      return res.status(401).json({ message: "El correo de tu cuenta de Google no está verificado" });
    }

    const correoLimpio = cuenta.email.toLowerCase().trim();

    // Se busca por los dos campos de correo que existen en la colección
    let usuario = await User.findOne({
      $or: [{ correo: correoLimpio }, { Correo_Electronico: correoLimpio }],
    });

    if (usuario) {
      if (!usuario.googleId) {
        usuario.googleId = cuenta.googleId;
      } else if (usuario.googleId !== cuenta.googleId) {
        return res.status(401).json({ message: "Este correo está vinculado a otra cuenta de Google" });
      }

      if (!usuario.isVerified) {
        // La cuenta se creó con contraseña pero sin verificar el correo: esa contraseña pudo
        // ponerla otra persona. Google ya comprobó que el correo es de quien entra, así que
        // se descarta la contraseña (puede crear otra con "Olvidé mi contraseña").
        usuario.password = undefined;
        usuario.passwords = undefined;
        usuario.isVerified = true;
        usuario.codigoVerificacion = undefined;
        usuario.codigoVerif = undefined;
        usuario.codigoVerificacionExpiracion = undefined;
      }

      if (!usuario.avatar && cuenta.picture) usuario.avatar = cuenta.picture;
      await usuario.save();
    } else {
      // Usuario nuevo, verificado por Google. Siempre con rol "usuario".
      usuario = new User({
        nombres: cuenta.nombre,
        Nombre: cuenta.nombre,
        apellidos: cuenta.apellido,
        Apellido: cuenta.apellido,
        correo: correoLimpio,
        Correo_Electronico: correoLimpio,
        googleId: cuenta.googleId,
        avatar: cuenta.picture || "",
        isVerified: true,
        rol: "usuario",
      });
      await usuario.save();
    }

    // Mismo contenido y misma duración que el token del inicio de sesión normal
    const token = jwt.sign(
      { id: usuario._id, correo: correoLimpio, rol: usuario.rol },
      process.env.JWT_SECRET,
      { expiresIn: "7d" }
    );

    return res.status(200).json({
      message: "Inicio de sesión con Google exitoso",
      token,
      usuario: {
        id: usuario._id,
        _id: usuario._id,
        nombres: usuario.nombres || usuario.Nombre,
        apellidos: usuario.apellidos || usuario.Apellido,
        Nombre: usuario.nombres || usuario.Nombre,
        Apellido: usuario.apellidos || usuario.Apellido,
        correo: usuario.correo || usuario.Correo_Electronico,
        Correo_Electronico: usuario.correo || usuario.Correo_Electronico,
        celular: usuario.celular || usuario.telefono,
        documentoIdentidad: usuario.documentoIdentidad,
        rol: usuario.rol,
        avatar: usuario.avatar,
      },
    });
  } catch (error) {
    console.error("Error al autenticar con Google:", error);
    return res.status(401).json({ message: "Token de Google inválido o expirado" });
  }
};