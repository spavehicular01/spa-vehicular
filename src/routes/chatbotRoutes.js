import express from 'express';
import chatbotController from '../controllers/chatbotController.js';

const router = express.Router();

router.post('/message', chatbotController.handleMessage);

export default router;