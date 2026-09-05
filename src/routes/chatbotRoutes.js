import express from "express";
import { chatearConAsesor } from "../controllers/chatbotController.js";

const router = express.Router();

// Ruta: POST /api/chat
router.post("/", chatearConAsesor);

export default router;