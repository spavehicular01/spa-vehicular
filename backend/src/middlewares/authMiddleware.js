import jwt from 'jsonwebtoken';

// La clave se lee solo del entorno: sin JWT_SECRET el servidor no arranca,
// en lugar de firmar con una clave conocida escrita en el código.
const JWT_SECRET = process.env.JWT_SECRET;
if (!JWT_SECRET) {
  throw new Error('Falta la variable de entorno JWT_SECRET. Agrégala al archivo .env antes de iniciar el servidor.');
}

export const verifyToken = (req, res, next) => {
  const authHeader = req.headers['authorization'];
  const token = authHeader && authHeader.split(' ')[1];

  if (!token || token === 'null' || token === 'undefined') {
    return res.status(401).json({ 
      error: 'Acceso denegado. No te has autenticado.' 
    });
  }

  try {
    const verified = jwt.verify(token, JWT_SECRET);
    req.user = verified;
    next();
  } catch (error) {
    // Solo se registra el motivo; nunca el token ni el header completo
    console.log('🚫 Token inválido:', error.message);
    return res.status(403).json({ error: 'Token inválido o expirado.' });
  }
};

// Solo permite continuar si el usuario autenticado tiene rol de administrador.
// Debe usarse siempre DESPUÉS de verifyToken en la cadena de middlewares.
export const esAdmin = (req, res, next) => {
  const rol = (req.user?.rol || '').toLowerCase();
  if (rol !== 'admin') {
    return res.status(403).json({ error: 'Acceso restringido a administradores' });
  }
  next();
};

// Deja pasar al administrador o al dueño del recurso: compara el id del token
// con el parámetro de la URL (por ejemplo :usuarioId). Va DESPUÉS de verifyToken.
export const propioOAdmin = (nombreParametro = 'id') => (req, res, next) => {
  const rol = (req.user?.rol || '').toLowerCase();
  if (rol === 'admin') return next();

  const idToken = String(req.user?.id || req.user?._id || '');
  if (!idToken || idToken !== String(req.params[nombreParametro])) {
    return res.status(403).json({ error: 'No tienes permiso para ver esta información' });
  }
  next();
};

export default verifyToken;