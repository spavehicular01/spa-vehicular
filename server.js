require('dotenv').config();

const express = require('express');
const mongoose = require('mongoose');
const cors = require('cors');

// Importación de Rutas
const authRoutes = require('./src/routes/authRoutes');
const vehicleRoutes = require('./src/routes/vehicleRoutes');
const appointmentRoutes = require('./src/routes/appointmentRoutes');
const serviceRoutes = require('./src/routes/serviceRoutes');

const app = express();

// Middlewares
app.use(express.json());
app.use(cors());

// Conexión a MongoDB usando las variables de entorno del archivo .env
mongoose.connect(process.env.MONGO_URI)
  .then(() => console.log('Conectado exitosamente a MongoDB Atlas'))
  .catch(err => console.error('Error al conectar a MongoDB:', err));

// Rutas base de la API
app.use(authRoutes);
app.use(vehicleRoutes);
app.use(appointmentRoutes);
app.use(serviceRoutes);

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log(`Servidor corriendo en http://localhost:${PORT}`);
});