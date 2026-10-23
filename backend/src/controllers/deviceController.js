import DeviceToken from '../models/DeviceToken.js';

const idDeSesion = (req) => String((req.user && (req.user.id || req.user._id)) || '');

// POST /api/devices — la app registra el token de su celular al iniciar sesión.
// El usuario sale del token JWT, nunca del cuerpo de la petición.
export const registrarDispositivo = async (req, res) => {
  try {
    const usuarioId = idDeSesion(req);
    const token = String(req.body.token || '').trim();
    const plataforma = ['android', 'ios'].includes(req.body.plataforma) ? req.body.plataforma : 'otro';

    if (!usuarioId) {
      return res.status(403).json({ mensaje: 'No se pudo identificar al usuario' });
    }
    if (!token || token.length > 4096) {
      return res.status(400).json({ mensaje: 'El token del dispositivo no es válido' });
    }

    // Si el celular ya estaba registrado con otro usuario, pasa al usuario actual
    await DeviceToken.findOneAndUpdate(
      { token },
      { usuarioId, plataforma, actualizadoEn: new Date() },
      { upsert: true, returnDocument: 'after', setDefaultsOnInsert: true }
    );

    res.status(200).json({ mensaje: 'Dispositivo registrado' });
  } catch (error) {
    console.error('Error en registrarDispositivo:', error);
    res.status(500).json({ mensaje: 'Error al registrar el dispositivo' });
  }
};

// POST /api/devices/baja — la app quita el token al cerrar sesión (deja de recibir avisos de esa cuenta).
export const eliminarDispositivo = async (req, res) => {
  try {
    const token = String(req.body.token || '').trim();
    if (!token) {
      return res.status(400).json({ mensaje: 'El token del dispositivo no es válido' });
    }

    // Solo puede quitar tokens que estén a su nombre
    await DeviceToken.deleteOne({ token, usuarioId: idDeSesion(req) });

    res.status(200).json({ mensaje: 'Dispositivo eliminado' });
  } catch (error) {
    console.error('Error en eliminarDispositivo:', error);
    res.status(500).json({ mensaje: 'Error al eliminar el dispositivo' });
  }
};

export default { registrarDispositivo, eliminarDispositivo };