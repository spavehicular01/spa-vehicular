import express from "express";
import jwt from "jsonwebtoken";
import { chatearConAsesor, confirmarCitaChat } from "../controllers/chatbotController.js";
import { verifyToken } from "../middlewares/authMiddleware.js";

const router = express.Router();

// Sesión OPCIONAL: cualquiera puede preguntar por servicios y precios, pero
// solo quien tiene sesión válida puede agendar. Si no hay token (o venció),
// el chat sigue funcionando como invitado.
const sesionOpcional = (req, res, next) => {
  const header = req.headers["authorization"] || "";
  const token = header.split(" ")[1];

  if (token && token !== "null" && token !== "undefined") {
    try {
      req.user = jwt.verify(token, process.env.JWT_SECRET);
    } catch {
      // Token inválido o vencido: se trata como invitado
    }
  }
  next();
};

// POST /api/chat
router.post("/", sesionOpcional, chatearConAsesor);

// POST /api/chat/confirmar-cita  (requiere sesión)
router.post("/confirmar-cita", verifyToken, confirmarCitaChat);

export default router;