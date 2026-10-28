import cloudinary from "../config/cloudinary.js";

export const extraerPublicId = (urlImagen) => {
  if (!urlImagen) return null;
  const match = urlImagen.match(/\/upload\/(?:v\d+\/)?(.+)\.[a-zA-Z0-9]+$/);
  return match ? match[1] : null;
};

export const borrarImagenCloudinary = async (urlImagen) => {
  const publicId = extraerPublicId(urlImagen);
  if (!publicId) return;

  try {
    await cloudinary.uploader.destroy(publicId);
  } catch (error) {
    console.error("Error al borrar imagen de Cloudinary:", error.message);
  }
};