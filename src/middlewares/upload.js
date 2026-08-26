const multer = require('multer');
const { CloudinaryStorage } = require('multer-storage-cloudinary');
const cloudinary = require('cloudinary').v2;

// Configuración de credenciales de Cloudinary
cloudinary.config({
  cloud_name: process.env.CLOUDINARY_CLOUD_NAME,
  api_key: process.env.CLOUDINARY_API_KEY,
  api_secret: process.env.CLOUDINARY_API_SECRET,
});

// Configuración del almacenamiento con los formatos permitidos
const storage = new CloudinaryStorage({
  cloudinary: cloudinary,
  params: {
    folder: 'lavados',
    allowed_formats: ['jpg', 'jpeg', 'png', 'webp', 'heic'], // Formatos aceptados
  },
});

const upload = multer({ storage });

module.exports = upload;