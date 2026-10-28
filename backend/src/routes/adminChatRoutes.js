import express from 'express';
import { chatearConAsistenteAdmin } from '../controllers/adminChatController.js';
import { verifyToken, esAdmin } from '../middlewares/authMiddleware.js';

const router = express.Router();

// POST /api/chat/admin — asistente interno, solo para el administrador
router.post('/', verifyToken, esAdmin, chatearConAsistenteAdmin);

export default router;