import express from 'express';
import {
  registrarUsers,
  verificarCuenta,
  reenviarCodigoVerificacion,
  login
} from "../controllers/User.js";
import {
  obtenerClientes,
  cambiarPassword
} from "../controllers/userController.js";
// AJUSTA estos dos nombres a lo que exportan tus middlewares:
import { verificarToken } from "../middlewares/authMiddleware.js";
import { soloAdmin } from "../middlewares/roleMiddleware.js";

const router = express.Router();

router.post("/registrar", registrarUsers);
router.post("/verificar-codigo", verificarCuenta);
router.post("/reenviar-codigo", reenviarCodigoVerificacion);
router.post("/login", login);
router.get("/clientes", verificarToken, soloAdmin, obtenerClientes);
router.put("/change-password", verificarToken, cambiarPassword);

export default router;