// src/seed.js
const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');
require('dotenv').config();

// Importar Modelos
const User = require('./models/User'); 
const Service = require('./models/Service');

const seedData = async () => {
  try {
    // 1. Conectar a MongoDB Atlas
    await mongoose.connect(process.env.MONGO_URI);
    console.log('🔌 Conectado a MongoDB Atlas para la carga inicial...');

    // 2. Limpiar colecciones
    await User.deleteMany({});
    await Service.deleteMany({});
    console.log('🧹 Colecciones de usuarios y servicios limpiadas.');

    // 3. Crear contraseñas encriptadas
    const salt = await bcrypt.genSalt(10);
    const adminPassword = await bcrypt.hash('Admin123*', salt);
    const clientPassword = await bcrypt.hash('Cliente123*', salt);

    // 4. Insertar Usuarios
    const users = await User.insertMany([
      {
        nombres: 'Administrador',
        apellidos: 'SPA',
        documentoIdentidad: '1000000001',
        correo: 'admin@spavehicular.com',
        celular: '3001234567',
        password: adminPassword,
        role: 'ADMIN'
      },
      {
        nombres: 'Didier',
        apellidos: 'Cliente',
        documentoIdentidad: '1000000002',
        correo: 'cliente@spavehicular.com',
        celular: '3109876543',
        password: clientPassword,
        role: 'CLIENTE'
      }
    ]);

    console.log('👤 Usuarios creados con éxito.');

    // 5. Insertar Servicios ajustados al modelo exacto
    const services = await Service.insertMany([
      {
        nombreServicio: 'Lavado General Básica',
        descripcion: 'Lavado exterior de carrocería, enjuague de chasis y aspirado sencillo del interior.',
        precio: 25000,
        duracionEstimadaMinutos: 45,
        categoria: 'LAVADO',
        estado: true
      },
      {
        nombreServicio: 'Lavado Premium + Polichado',
        descripcion: 'Lavado detallado exterior, desmanchado de pintura, polichado a máquina y aspirado profundo de cojinería.',
        precio: 60000,
        duracionEstimadaMinutos: 90,
        categoria: 'ESTETICA',
        estado: true
      },
      {
        nombreServicio: 'Limpieza de Cojinería e Interiores',
        descripcion: 'Lavado al seco y desinfección con vapor para asientos, techo, alfombras y paneles de puertas.',
        precio: 80000,
        duracionEstimadaMinutos: 120,
        categoria: 'INTERIORES',
        estado: true
      },
      {
        nombreServicio: 'Servicio de SPA a Domicilio',
        descripcion: 'Atención completa de lavado y embellecimiento en la comodidad de tu hogar o lugar de trabajo.',
        precio: 75000,
        duracionEstimadaMinutos: 90,
        categoria: 'DOMICILIO',
        estado: true
      }
    ]);

    console.log(`🧼 ${services.length} servicios insertados en el catálogo.`);
    console.log('\n✅ Carga inicial (Seed) completada con éxito.');
    process.exit(0);

  } catch (error) {
    console.error('❌ Error realizando el seed de datos:', error);
    process.exit(1);
  }
};

seedData();