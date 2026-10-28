##  🚗 SPA VEHICULAR - Sistema de Gestión de Servicios y Citas Automotrices

[![Node.js](https://img.shields.io/badge/Node.js-v18%2B-green.svg)](https://nodejs.org/)
[![Express](https://img.shields.io/badge/Express-4.x-blue.svg)](https://expressjs.com/)
[![MongoDB](https://img.shields.io/badge/MongoDB-6.0%2B-green.svg)](https://www.mongodb.com/)
[![License](https://img.shields.io/badge/License-MIT-brightgreen.svg)](LICENSE)

Plataforma integral backend desarrollada en **Node.js**, **Express** y **MongoDB** para la gestión web y móvil de servicios de Spa Vehicular. El sistema permite administrar citas, catálogo de lavado/embellecimiento, registro de vehículos, seguimiento a domicilio, pagos y atención automatizada con IA.

---

## 📋 Tabla de Contenidos

- [📌 Descripción del Proyecto](#-descripción-del-proyecto)
- [✨ Características Principales (SRS)](#-características-principales-srs)
- [🛠️ Tecnologías Utilizadas](#️-tecnologías-utilizadas)
- [📂 Estructura del Proyecto](#-estructura-del-proyecto)
- [⚙️ Requisitos Previos e Instalación](#️-requisitos-previos-e-instalación)
- [🔐 Variables de Entorno](#-variables-de-entorno)
- [🚀 Ejecución del Proyecto](#-ejecución-del-proyecto)
- [📑 Documentación de la API (Endpoints)](#-documentación-de-la-api-endpoints)
- [🤝 Contribución](#-contribución)
- [📄 Licencia](#-licencia)

---

## 📌 Descripción del Proyecto

El proyecto **SPA VEHICULAR** optimiza la programación de servicios de embellecimiento y mantenimiento automotriz. Permite a los clientes agendar citas en sede o a domicilio, seleccionar paquetes de limpieza, registrar sus vehículos, realizar pagos y recibir recordatorios automáticos, facilitando al administrador el control total de agendas y personal.

---

## ✨ Características Principales (SRS)

| Módulo | Requisito (SRS) | Descripción |
| :--- | :--- | :--- |
| **Autenticación** | `RF001 / RF003` | Registro, inicio de sesión seguro mediante JWT y recuperación de contraseñas. |
| **Vehículos** | `RF002` | Gestión CRUD de vehículos asociados al perfil del cliente (placa, marca, modelo, tipo). |
| **Reserva de Citas** | `RF004 / RF007` | Agendamiento, reprogramación y cancelación con validación previa de horarios y disponibilidad. |
| **Notificaciones** | `RF006 / RF011` | Envío automático de confirmaciones y recordatorios por correo electrónico. |
| **Domicilios** | `RF008` | Solicitud y asignación de servicios de spa vehicular a domicilio con dirección exacta. |
| **Catálogo** | `RF009` | Gestión de servicios, precios, tiempos estimados de atención y promociones. |
| **Pagos** | `RF010` | Registro de métodos de pago (Nequi, Daviplata, Efectivo, Tarjeta) y comprobantes. |
| **Asistente IA** | `RF012` | Integración de chatbot para preguntas frecuentes y estado de citas. |

---

## 🛠️ Tecnologías Utilizadas

- **Entorno de Ejecución:** Node.js
- **Framework Web:** Express.js
- **Base de Datos NoSQL:** MongoDB (Mongoose ODM)
- **Autenticación y Seguridad:** JSON Web Tokens (JWT), Bcrypt.js, CORS
- **Envío de Correos:** Nodemailer
- **Documentación / Herramientas:** Postman, Git / GitHub

---

## 📂 Estructura del Proyecto

El backend sigue la arquitectura patrón **MVC (Modelo-Vista-Controlador)**:

```
CARS-BACKEND/
├── src/
│   ├── config/             # Configuración de base de datos (MongoDB/Mongoose)
│   │   └── db.js
│   ├── controllers/        # Lógica de negocio por módulo
│   │   ├── authController.js
│   │   ├── appointmentController.js
│   │   ├── vehicleController.js
│   │   ├── serviceController.js
│   │   ├── paymentController.js
│   │   └── chatbotController.js
│   ├── middlewares/        # Validaciones, autenticación y manejo de errores
│   │   ├── authMiddleware.js
│   │   └── roleMiddleware.js
│   ├── models/             # Esquemas de Mongoose (User, Vehicle, Appointment, etc.)
│   ├── routes/             # Definición de rutas API RESTful
│   ├── services/           # Integraciones (Nodemailer, IA)
│   │   ├── emailService.js
│   │   └── aiService.js
│   └── utils/              # Helper functions y formateadores
├── .env.example
├── .gitignore
├── package.json
├── README.md
└── server.js               # Punto de entrada principal
```
⚙️ Requisitos Previos e Instalación
Requisitos
Node.js (Versión 18 o superior)

MongoDB (Instalación local o cuenta en MongoDB Atlas)

Git

Pasos de Instalación
Clonar el repositorio:

Bash
git clone [https://github.com/tu-usuario/cars-backend.git](https://github.com/tu-usuario/cars-backend.git)
cd cars-backend
Instalar dependencias:

Bash
npm install
Configurar las variables de entorno:
Copia el archivo de ejemplo .env.example a .env y ajusta los valores.

Bash
cp .env.example .env
🔐 Variables de Entorno
Crear un archivo .env en la raíz del proyecto con la siguiente estructura:

Fragmento de código
# Servidor
PORT=3000

# Base de Datos MongoDB (Local o MongoDB Atlas)
MONGO_URI=mongodb://localhost:27017/spa_vehicular_db
# O para MongoDB Atlas:
# MONGO_URI=mongodb+srv://<usuario>:<password>@cluster.mongodb.net/spa_vehicular_db?retryWrites=true&w=m_w

# Autenticación JWT
JWT_SECRET=tu_clave_secreta_super_segura
JWT_EXPIRES_IN=24h

# Configuración Nodemailer (Opcional)
EMAIL_HOST=smtp.gmail.com
EMAIL_PORT=465
EMAIL_USER=tu_correo@gmail.com
EMAIL_PASS=tu_password_de_aplicacion
🚀 Ejecución del Proyecto
Modo Desarrollo (con live reload):
Bash
npm run dev
Modo Producción:
Bash
npm start
El servidor estará corriendo en: http://localhost:3000

📑 Documentación de la API (Endpoints)
🔑 Autenticación
POST /api/auth/register - Registro de nuevos usuarios

POST /api/auth/login - Inicio de sesión (Retorna Token JWT)

POST /api/auth/forgot-password - Solicitud de restablecimiento de clave

🚗 Vehículos
GET /api/vehicles - Listar vehículos del usuario autenticado

POST /api/vehicles - Registrar un nuevo vehículo

PUT /api/vehicles/:id - Actualizar información del vehículo

DELETE /api/vehicles/:id - Eliminar vehículo

📅 Citas y Agenda
GET /api/appointments - Obtener citas agendadas

POST /api/appointments - Crear nueva cita (Sede / Domicilio)

PUT /api/appointments/:id/reschedule - Reprogramar cita

DELETE /api/appointments/:id - Cancelar cita

🧼 Catálogo de Servicios
GET /api/services - Listar todos los servicios y tarifas

POST /api/services - (Admin) Crear nuevo servicio

PUT /api/services/:id - (Admin) Editar servicio

🤝 Contribución
Haz un Fork del proyecto.

Crea una rama para tu nueva característica (git checkout -b feature/NuevaCaracteristica).

Guarda tus cambios (git commit -m 'Añade nueva característica').

Sube la rama (git push origin feature/NuevaCaracteristica).

Abre un Pull Request.

📄 Licencia
Este proyecto está bajo la Licencia MIT.
