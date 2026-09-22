import express from 'express';
<<<<<<< HEAD
import {
  registrarUsers,
  verificarCuenta,
  reenviarCodigoVerificacion,
  login,
  cambiarPassword,
  solicitarRecuperacionPassword,
  restablecerPassword,
  actualizarPerfil // 🟢 Se importa desde el mismo controlador User.js
} from "../controllers/User.js";
=======
import { actualizarPerfil, obtenerClientes } from '../controllers/userController.js';
import { verifyToken, esAdmin } from '../middlewares/authMiddleware.js';
>>>>>>> origin/main

// Middleware de subida de imágenes
import upload from "../middlewares/upload.js";

const router = express.Router();

<<<<<<< HEAD
// ----------------------------------------------------
// Rutas de autenticación
// ----------------------------------------------------
router.post("/registrar", registrarUsers);
router.post("/verificar-codigo", verificarCuenta);
router.post("/reenviar-codigo", reenviarCodigoVerificacion);
router.post("/login", login);
=======
router.put('/perfil/:id', verifyToken, actualizarPerfil);
router.get('/clientes', verifyToken, esAdmin, obtenerClientes);
>>>>>>> origin/main

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