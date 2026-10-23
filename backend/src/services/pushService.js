import fs from 'fs';
import { initializeApp, cert } from 'firebase-admin/app';
import { getMessaging } from 'firebase-admin/messaging';
import DeviceToken from '../models/DeviceToken.js';

// Notificaciones push con Firebase Cloud Messaging.
// Si no está configurado FIREBASE_SERVICE_ACCOUNT_PATH en el .env, las push quedan
// desactivadas y el resto del servidor funciona igual.

let yaIntento = false;
let habilitado = false;

const iniciar = () => {
  if (yaIntento) return habilitado;
  yaIntento = true;

  const ruta = process.env.FIREBASE_SERVICE_ACCOUNT_PATH;
  if (!ruta) {
    console.log('ℹ️ Push desactivado: falta FIREBASE_SERVICE_ACCOUNT_PATH en el .env');
    return false;
  }

  try {
    const credenciales = JSON.parse(fs.readFileSync(ruta, 'utf8'));
    initializeApp({ credential: cert(credenciales) });
    habilitado = true;
    console.log('🔔 Notificaciones push activadas');
  } catch (error) {
    console.error('⚠️ No se pudo iniciar Firebase (revisa la ruta y el archivo):', error.message);
  }

  return habilitado;
};

const CODIGOS_TOKEN_INVALIDO = [
  'messaging/registration-token-not-registered',
  'messaging/invalid-registration-token'
];

// Envía una notificación push a todos los celulares de un usuario. Nunca lanza error.
export const enviarPush = async (usuarioId, { titulo, mensaje, datos = {} }) => {
  try {
    if (!usuarioId || !iniciar()) return;

    const dispositivos = await DeviceToken.find({ usuarioId }).lean();
    if (dispositivos.length === 0) return;

    const tokens = dispositivos.map((d) => d.token);

    const respuesta = await getMessaging().sendEachForMulticast({
      tokens,
      notification: { title: titulo, body: mensaje },
      // FCM solo acepta texto en "data"
      data: Object.fromEntries(Object.entries(datos).map(([k, v]) => [k, String(v)])),
      android: {
        priority: 'high',
        notification: { channelId: 'notificaciones_spa' }
      }
    });

    // Se borran los celulares que ya no existen (app desinstalada, token vencido)
    const invalidos = [];
    respuesta.responses.forEach((r, i) => {
      if (!r.success && CODIGOS_TOKEN_INVALIDO.includes(r.error && r.error.code)) {
        invalidos.push(tokens[i]);
      }
    });
    if (invalidos.length > 0) {
      await DeviceToken.deleteMany({ token: { $in: invalidos } });
    }
  } catch (error) {
    console.error('⚠️ No se pudo enviar la notificación push:', error.message);
  }
};

export default { enviarPush };