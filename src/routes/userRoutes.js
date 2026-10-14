import express from 'express';
import { actualizarPerfil, cambiarPassword, obtenerClientes } from "../controllers/userController.js";
import { verifyToken, esAdmin } from "../middlewares/authMiddleware.js";
// Middleware de Multer + Cloudinary
import upload from "../middlewares/upload.js";

const router = express.Router();

// Solo deja pasar si el id de la URL es el del usuario que inició sesión.
// Va ANTES de subir la imagen para que nadie ajeno gaste espacio en Cloudinary.
const soloPropioPerfil = (req, res, next) => {
  const idToken = String(req.user?.id || req.user?._id || req.user?.userId || '');
  if (!idToken || idToken !== req.params.id) {
    return res.status(403).json({
      ok: false,
      mensaje: 'Solo puedes editar tu propio perfil'
    });
  }
  next();
};

// El registro, la verificación de cuenta y el login viven en /api/auth (authRoutes).

// Panel Admin: lista de clientes con sus vehículos
router.get("/clientes", verifyToken, esAdmin, obtenerClientes);

// Cambiar contraseña del usuario autenticado
router.put("/change-password", verifyToken, cambiarPassword);

// Editar perfil: solo el dueño de la cuenta. La foto viaja en el campo "avatar"
router.put(
  "/perfil/:id",
  verifyToken,
  soloPropioPerfil,
  upload.single('avatar'),
  actualizarPerfil
);

// Cambiar contraseña: solo el dueño de la cuenta
router.put(
  "/perfil/:id/cambiar-password",
  verifyToken,
  soloPropioPerfil,
  cambiarPassword
);

export default router;