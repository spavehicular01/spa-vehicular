import express from 'express';
import {
  listarOpiniones,
  obtenerMiOpinion,
  guardarOpinion,
  eliminarOpinion
} from '../controllers/reviewController.js';
import { verifyToken } from '../middlewares/authMiddleware.js';

const router = express.Router();

router.get('/', listarOpiniones);                 // público
router.get('/mia', verifyToken, obtenerMiOpinion); // antes de '/:id'
router.post('/', verifyToken, guardarOpinion);
router.delete('/:id', verifyToken, eliminarOpinion);

export default router;