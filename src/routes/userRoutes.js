import express from 'express';
import {
  registrarUsers,
  verificarCuenta,
  reenviarCodigoVerificacion,
  login,
  cambiarPassword,
  solicitarRecuperacionPassword,
  restablecerPassword
} from "../controllers/User.js";

// Importar la función del controlador de usuario
import { actualizarPerfil } from "../controllers/userController.js";

// Middleware de subida de imágenes
import upload from "../middlewares/upload.js";

const router = express.Router();

// ----------------------------------------------------
// Rutas de autenticación
// ----------------------------------------------------
router.post("/registrar", registrarUsers);
router.post("/verificar-codigo", verificarCuenta);
router.post("/reenviar-codigo", reenviarCodigoVerificacion);
router.post("/login", login);

// ----------------------------------------------------
// Rutas de gestión de usuario y contraseña
// ----------------------------------------------------
// Actualizar perfil (nombres, apellidos, celular, foto)
router.put("/actualizar-perfil/:id", upload.single('imagen'), actualizarPerfil);

// Cambiar contraseña desde los ajustes (usuario autenticado)
router.put("/cambiar-password/:id", cambiarPassword);

// Recuperar contraseña olvidada (solicitar código al correo)
router.post("/recuperar-password", solicitarRecuperacionPassword);

// Restablecer contraseña ingresando el código de verificación recibido
router.post("/restablecer-password", restablecerPassword);

export default router;