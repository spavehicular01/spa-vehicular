import 'dotenv/config';
import express from 'express';
import http from 'http';
import { Server } from 'socket.io';
import mongoose from 'mongoose';
import cors from 'cors';

// Importación de Rutas (con extensión .js obligatoria en ES Modules)
import authRoutes from './src/routes/authRoutes.js';
import vehicleRoutes from './src/routes/vehicleRoutes.js';
import appointmentRoutes from './src/routes/appointmentRoutes.js';
import serviceRoutes from './src/routes/serviceRoutes.js';
import chatbotRoutes from './src/routes/chatbotRoutes.js'; 
import uploadRoutes from './src/routes/uploadRoutes.js';
import { crearAdminSemilla } from './src/utils/seedAdmin.js';

const app = express();

// Creación del Servidor HTTP y Socket.io
const server = http.createServer(app);
const io = new Server(server, {
  cors: {
    origin: '*',
    methods: ['GET', 'POST', 'PUT', 'DELETE']
  }
});

// Middlewares Globales
app.use(express.json());
app.use(cors());

// Adjuntar `io` a `req`
app.use((req, res, next) => {
  req.io = io;
  next();
});

// Conexión a MongoDB
console.log('URI leída desde .env:', process.env.MONGO_URI);

mongoose.connect(process.env.MONGO_URI)
  .then(async () => {
    console.log('✅ Conectado exitosamente a MongoDB Atlas');
    await crearAdminSemilla();
  })
  .catch(err => console.error('❌ Error al conectar a MongoDB:', err));

// Middleware de rastreo de peticiones
app.use((req, res, next) => {
  console.log(`📩 [${new Date().toLocaleTimeString()}] Petición recibida: ${req.method} ${req.url}`);
  next();
});

// Eventos de conexión de WebSockets
io.on('connection', (socket) => {
  console.log(`⚡ Cliente o Admin conectado a WebSocket ID: ${socket.id}`);

  socket.on('disconnect', () => {
    console.log(`❌ Cliente desconectado ID: ${socket.id}`);
  });
});

// Rutas base de la API (Consolidadas)
app.use('/api/auth', authRoutes);
app.use('/api/vehicles', vehicleRoutes);
app.use('/api/appointments', appointmentRoutes);
app.use('/api/services', serviceRoutes);
app.use('/api/chat', chatbotRoutes);
app.use('/api/upload', uploadRoutes);

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
  ...extraerRutasRouter(serviceRoutes, '/api/services'),
  ...extraerRutasRouter(chatbotRoutes, '/api/chat'),
  ...extraerRutasRouter(uploadRoutes, '/api/upload'),
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