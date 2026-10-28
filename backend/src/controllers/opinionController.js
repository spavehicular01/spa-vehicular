const Opinion = require('../models/opinion.js');

// "Carlos Andrés Pérez" -> "Carlos P."
function nombreCorto(nombreCompleto) {
  const partes = String(nombreCompleto || '').trim().split(/\s+/).filter(Boolean);
  if (partes.length === 0) return 'Cliente';
  if (partes.length === 1) return partes[0];
  const ultimo = partes[partes.length - 1];
  return `${partes[0]} ${ultimo[0].toUpperCase()}.`;
}

// GET /api/opiniones?limite=10  (público)
exports.listarOpiniones = async (req, res) => {
  try {
    const limite = Math.min(parseInt(req.query.limite, 10) || 10, 50);

    const opiniones = await Opinion.find({ visible: true })
      .sort({ createdAt: -1 })
      .limit(limite)
      .select('nombre estrellas texto createdAt -_id');

    res.json({ success: true, opiniones });
  } catch (error) {
    console.error('Error al listar opiniones:', error);
    res
      .status(500)
      .json({ success: false, message: 'Error al obtener las opiniones' });
  }
};

// POST /api/opiniones  (requiere sesión)
// Body: { estrellas: 1-5, texto: "..." }
// Si el usuario ya tenía una opinión, la actualiza.
exports.guardarOpinion = async (req, res) => {
  try {
    const { estrellas, texto } = req.body;

    const n = Number(estrellas);
    if (!Number.isInteger(n) || n < 1 || n > 5) {
      return res
        .status(400)
        .json({ success: false, message: 'Las estrellas deben ser de 1 a 5' });
    }

    const textoLimpio = String(texto || '').trim();
    if (textoLimpio.length < 5 || textoLimpio.length > 300) {
      return res.status(400).json({
        success: false,
        message: 'El comentario debe tener entre 5 y 300 caracteres',
      });
    }

    // 🔧 ADAPTAR: según lo que tu middleware de sesión ponga en la petición
    // (req.user o req.usuario) y lo que incluya tu token JWT.
    const u = req.user || req.usuario || {};
    const usuarioId = u.id || u._id;
    if (!usuarioId) {
      return res
        .status(401)
        .json({ success: false, message: 'Sesión no válida' });
    }

    // 🔧 ADAPTAR: si el token no trae el nombre, búscalo en tu modelo de
    // usuarios, por ejemplo:
    //   const usuario = await Usuario.findById(usuarioId).select('nombres apellidos');
    //   const nombre = nombreCorto(`${usuario.nombres} ${usuario.apellidos}`);
    const nombre = nombreCorto(u.nombres || u.nombre);

    const opinion = await Opinion.findOneAndUpdate(
      { usuarioId },
      { usuarioId, nombre, estrellas: n, texto: textoLimpio, visible: true },
      { upsert: true, new: true, runValidators: true, setDefaultsOnInsert: true }
    );

    res.status(201).json({
      success: true,
      message: 'Gracias por tu opinión',
      opinion: {
        nombre: opinion.nombre,
        estrellas: opinion.estrellas,
        texto: opinion.texto,
      },
    });
  } catch (error) {
    console.error('Error al guardar opinión:', error);
    res
      .status(500)
      .json({ success: false, message: 'Error al guardar la opinión' });
  }
};