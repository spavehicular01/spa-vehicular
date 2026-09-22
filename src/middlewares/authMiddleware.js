import jwt from 'jsonwebtoken';

export const verifyToken = (req, res, next) => {
  const authHeader = req.headers['authorization'];
  const token = authHeader && authHeader.split(' ')[1];

  console.log('🔑 Authorization header recibido:', authHeader); // 👈 agrega esto

  if (!token || token === 'null' || token === 'undefined') {
    console.log('🚫 Token ausente o inválido'); // 👈 y esto
    return res.status(401).json({ 
      error: 'Acceso denegado. No te has autenticado.' 
    });
  }

  try {
    const verified = jwt.verify(token, process.env.JWT_SECRET || 'mi_clave_secreta_cars_wash');
    req.user = verified;
    next();
  } catch (error) {
    console.log('🚫 Token inválido:', error.message); // 👈 y esto
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

export default verifyToken;