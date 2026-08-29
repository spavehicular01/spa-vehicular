require('dotenv').config();

const express = require('express');
const http = require('http'); // 1. Importante para integrar Socket.io
const { Server } = require('socket.io');
const mongoose = require('mongoose');
const cors = require('cors');

// Importación de Rutas
const authRoutes = require('./src/routes/authRoutes');
const userRoutes = require('./src/routes/userRoutes'); // <-- Agregado para usuarios
const vehicleRoutes = require('./src/routes/vehicleRoutes');
const appointmentRoutes = require('./src/routes/appointmentRoutes');
const serviceRoutes = require('./src/routes/serviceRoutes');
const chatbotRoutes = require('./src/routes/chatbotRoutes');
const uploadRoutes = require('./src/routes/uploadRoutes'); // <-- Agregado para subir imágenes

const app = express();

// 2. Creación del Servidor HTTP y Socket.io
const server = http.createServer(app);
const io = new Server(server, {
  cors: {
    origin: '*', // Permite conexiones desde Flutter (emulador y dispositivos físicos)
    methods: ['GET', 'POST', 'PUT', 'DELETE']
  }
});

// Middlewares Globales
app.use(express.json());
app.use(cors());

// 3. Adjuntar `io` a `req` para usarlo dentro de tus controladores/rutas
app.use((req, res, next) => {
  req.io = io;
  next();
});

// Conexión a MongoDB usando las variables de entorno del archivo .env
console.log('URI leída desde .env:', process.env.MONGO_URI);

mongoose.connect(process.env.MONGO_URI)
  .then(() => console.log('✅ Conectado exitosamente a MongoDB Atlas'))
  .catch(err => console.error('❌ Error al conectar a MongoDB:', err));

// Middleware de rastreo de peticiones (Logging)
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

// Rutas base de la API con prefijo /api
app.use('/api/auth', authRoutes);
app.use('/api/users', userRoutes); // <-- Agregada la ruta para gestión de perfil
app.use('/api/vehicles', vehicleRoutes);
app.use('/api/appointments', appointmentRoutes);
app.use('/api/services', serviceRoutes);
app.use('/api/chatbot', chatbotRoutes);
app.use('/api/upload', uploadRoutes); // <-- Agregada la ruta para Cloudinary

// Ruta raíz para verificación del servidor
app.get('/', (req, res) => {
  res.json({ mensaje: 'API Cars-Wash funcionando correctamente 🚀' });
});

// Manejador para rutas no encontradas (404)
app.use((req, res) => {
  res.status(404).json({ mensaje: `La ruta '${req.originalUrl}' no existe en este servidor.` });
});

// Manejador global de errores (500)
app.use((err, req, res, next) => {
  console.error('🔥 Error no controlado:', err.stack);
  res.status(500).json({ mensaje: 'Error interno del servidor', error: err.message });
});

// 4. Inicio del Servidor usando `server.listen` en lugar de `app.listen`
const PORT = process.env.PORT || 3000;
server.listen(PORT, () => {
  console.log(`🚀 Servidor y WebSockets corriendo en http://localhost:${PORT}`);
});