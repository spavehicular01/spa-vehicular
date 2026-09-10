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
    const verified = jwt.verify(token, process.env.SECRET_KEY || 'secreto_super_seguro');
    req.user = verified;
    next();
  } catch (error) {
    console.log('🚫 Token inválido:', error.message); // 👈 y esto
    return res.status(403).json({ error: 'Token inválido o expirado.' });
  }
};

export default verifyToken;