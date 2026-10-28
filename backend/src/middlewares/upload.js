import multer from 'multer';
import { CloudinaryStorage } from 'multer-storage-cloudinary';
import { v2 as cloudinary } from 'cloudinary';

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

const upload = multer({
  storage,
  // Máximo 8 MB por imagen y un solo archivo por petición
  limits: { fileSize: 8 * 1024 * 1024, files: 1 },
});

export default upload;