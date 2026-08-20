require('dotenv').config();

const express = require('express');
const mongoose = require('mongoose');
const cors = require('cors');

// Importación de Rutas
const authRoutes = require('./src/routes/authRoutes');
const vehicleRoutes = require('./src/routes/vehicleRoutes');
const appointmentRoutes = require('./src/routes/appointmentRoutes');
const serviceRoutes = require('./src/routes/serviceRoutes');
const chatbotRoutes = require('./src/routes/chatbotRoutes');

const app = express();

// Middlewares Globales
app.use(express.json());
app.use(cors());

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

// Rutas base de la API con prefijo /api
app.use('/api/auth', authRoutes);
app.use('/api/vehicles', vehicleRoutes);
app.use('/api/appointments', appointmentRoutes);
app.use('/api/services', serviceRoutes);
app.use('/api/chatbot', chatbotRoutes);

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

// Inicio del Servidor
const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log(`🚀 Servidor corriendo en http://localhost:${PORT}`);
});