import express from 'express';
import {
  registrarUsers,
  verificarCuenta,
  reenviarCodigoVerificacion,
  login
} from "../controllers/User.js";

const router = express.Router();

router.post("/registrar", registrarUsers);
router.post("/verificar-codigo", verificarCuenta);
router.post("/reenviar-codigo", reenviarCodigoVerificacion);
router.post("/login", login);

export default router;