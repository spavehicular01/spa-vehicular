import 'dotenv/config';
import dns from 'dns';
import express from 'express';
import http from 'http';
import { Server } from 'socket.io';
import mongoose from 'mongoose';
import cors from 'cors';
import jwt from 'jsonwebtoken';

// Importación de Rutas (con extensión .js obligatoria en ES Modules)
import authRoutes from './src/routes/authRoutes.js';
import vehicleRoutes from './src/routes/vehicleRoutes.js';
import appointmentRoutes from './src/routes/appointmentRoutes.js';
import serviceRoutes from './src/routes/serviceRoutes.js';
import chatbotRoutes from './src/routes/chatbotRoutes.js'; 
import uploadRoutes from './src/routes/uploadRoutes.js';
import { crearAdminSemilla } from './src/utils/seedAdmin.js';
import userRoutes from './src/routes/userRoutes.js';
import reviewRoutes from './src/routes/reviewRoutes.js';
import paymentRoutes from './src/routes/paymentRoutes.js';
import notificationRoutes from './src/routes/notificationRoutes.js';

// Forzar DNS de Google (fix para SRV lookup fallando contra DNS link-local IPv6 fe80::1)
dns.setServers(['8.8.8.8', '8.8.4.4']);

const app = express();

// Creación del Servidor HTTP y Socket.io
const server = http.createServer(app);
const io = new Server(server, {
  cors: {
    origin: '*',
    methods: ['GET', 'POST', 'PUT', 'PATCH', 'DELETE', 'OPTIONS']
  }
});

// Middlewares Globales
app.use(express.json());
app.use(express.urlencoded({ extended: true }));
app.use(cors());

// Adjuntar `io` a `req`
app.use((req, res, next) => {
  req.io = io;
  next();
});

// Middleware de rastreo de peticiones (debe ir antes de las rutas)
app.use((req, res, next) => {
  console.log(`📩 [${new Date().toLocaleTimeString()}] Petición recibida: ${req.method} ${req.originalUrl}`);
  next();
});

// Conexión a MongoDB
// (ya no se imprime la URI: contiene la contraseña de la base de datos)
mongoose.connect(process.env.MONGO_URI, { dbName: 'spa_vehicular' })
  .then(async () => {
    console.log('✅ Conectado a MongoDB Atlas, base:', mongoose.connection.name);
    await crearAdminSemilla();
  })
  .catch(err => console.error('❌ Error al conectar a MongoDB:', err));

// Eventos de conexión de WebSockets
// 🔒 Autenticación de WebSockets: solo se conectan usuarios con un token válido
// (la app lo envía en `auth: { token }`).
io.use((socket, next) => {
  try {
    const token = socket.handshake.auth && socket.handshake.auth.token;
    if (!token) return next(new Error('No autenticado'));
    socket.data.user = jwt.verify(token, process.env.JWT_SECRET);
    next();
  } catch (error) {
    next(new Error('Token inválido o expirado'));
  }
});

io.on('connection', (socket) => {
  // Cada usuario entra a su propia sala; los administradores, además, a la sala "admins".
  // Así los avisos en tiempo real llegan solo a quien corresponde.
  const { id, rol } = socket.data.user || {};
  if (id) socket.join(`usuario:${String(id)}`);
  if (String(rol || '').toLowerCase() === 'admin') socket.join('admins');

  console.log(`⚡ Cliente o Admin conectado a WebSocket ID: ${socket.id}`);

  socket.on('disconnect', () => {
    console.log(`❌ Cliente desconectado ID: ${socket.id}`);
  });
});

// Rutas base de la API (Consolidadas)
app.use('/api/auth', authRoutes);
app.use('/api/vehicles', vehicleRoutes);
app.use('/api/reviews', reviewRoutes);
// Registramos ambas variaciones para evitar fallos por "/" al final
app.use('/api/appointments', appointmentRoutes);
app.use('/api/appointments/', appointmentRoutes);
app.use('/api/payments', paymentRoutes);
app.use('/api/notifications', notificationRoutes);
app.use('/api/services', serviceRoutes);
app.use('/api/chat', chatbotRoutes);
app.use('/api/upload', uploadRoutes);
app.use('/api/users', userRoutes);

// Ruta raíz
app.get('/', (req, res) => {
  res.json({ mensaje: 'API Cars-Wash funcionando correctamente 🚀' });
});

// Función para listar rutas de un router específico con su prefijo conocido
function extraerRutasRouter(router, prefijo) {
  const rutas = [];
  const stack = router.stack || router?.router?.stack || [];
  stack.forEach((capa) => {
    if (capa.route) {
      const metodos = Object.keys(capa.route.methods)
        .filter((m) => capa.route.methods[m])
        .map((m) => m.toUpperCase())
        .join(', ');
      const path = capa.route.path === '/' ? '' : capa.route.path;
      rutas.push({ metodo: metodos, ruta: prefijo + path });
    }
  });
  return rutas;
}

const todasLasRutas = [
  ...extraerRutasRouter(authRoutes, '/api/auth'),
  ...extraerRutasRouter(vehicleRoutes, '/api/vehicles'),
  ...extraerRutasRouter(appointmentRoutes, '/api/appointments'),
  ...extraerRutasRouter(paymentRoutes, '/api/payments'),
  ...extraerRutasRouter(notificationRoutes, '/api/notifications'),
  ...extraerRutasRouter(serviceRoutes, '/api/services'),
  ...extraerRutasRouter(chatbotRoutes, '/api/chat'),
  ...extraerRutasRouter(uploadRoutes, '/api/upload'),
  ...extraerRutasRouter(userRoutes, '/api/users'),
  { metodo: 'GET', ruta: '/' }, // ruta raíz
];

console.log('\n📋 Rutas disponibles en la API:\n');
console.table(todasLasRutas);

// Manejador 404
app.use((req, res) => {
  res.status(404).json({ mensaje: `La ruta '${req.originalUrl}' no existe en este servidor.` });
});

// Manejador global de errores (500)
app.use((err, req, res, next) => {
  console.error('🔥 Error no controlado:', err.stack);
  res.status(500).json({ mensaje: 'Error interno del servidor', error: err.message });
});

// Inicio del Servidor
const PORT = process.env.PORT || 3000;
server.listen(PORT, () => {
  console.log(`🚀 Servidor y WebSockets corriendo en http://localhost:${PORT}`);
});