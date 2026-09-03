import 'dotenv/config';
import express from 'express';
import http from 'http';
import { Server } from 'socket.io';
import mongoose from 'mongoose';
import cors from 'cors';

// Importación de Rutas
// ✅ AHORA (Correcto desde server.js):
import authRoutes from './routes/authRoutes.js';
import userRoutes from './routes/userRoutes.js';
import vehicleRoutes from './routes/vehicleRoutes.js';
import appointmentRoutes from './routes/appointmentRoutes.js';
import serviceRoutes from './routes/serviceRoutes.js';
import chatbotRoutes from './routes/chatbotRoutes.js';
import uploadRoutes from './routes/uploadRoutes.js';

const app = express();

// Creación del Servidor HTTP y Socket.io
const server = http.createServer(app);
const io = new Server(server, {
  cors: {
    origin: '*',
    methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS']
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
console.log('URI leída desde .env:', process.env.MONGO_URI);

mongoose.connect(process.env.MONGO_URI)
  .then(() => console.log('✅ Conectado exitosamente a MongoDB Atlas'))
  .catch(err => console.error('❌ Error al conectar a MongoDB:', err));

// Eventos de conexión de WebSockets
io.on('connection', (socket) => {
  console.log(`⚡ Cliente o Admin conectado a WebSocket ID: ${socket.id}`);

  socket.on('disconnect', () => {
    console.log(`❌ Cliente desconectado ID: ${socket.id}`);
  });
});

// Rutas base de la API
app.use('/api/auth', authRoutes);
app.use('/api/users', userRoutes);
app.use('/api/vehicles', vehicleRoutes);

// Registramos ambas variaciones para evitar fallos por "/" al final
app.use('/api/appointments', appointmentRoutes);
app.use('/api/appointments/', appointmentRoutes);

app.use('/api/services', serviceRoutes);
app.use('/api/chatbot', chatbotRoutes);
app.use('/api/upload', uploadRoutes);

// Ruta raíz
app.get('/', (req, res) => {
  res.json({ mensaje: 'API Cars-Wash funcionando correctamente 🚀' });
});

// Manejador 404 para rutas no encontradas
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