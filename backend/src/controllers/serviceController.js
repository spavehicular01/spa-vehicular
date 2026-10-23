import Service from '../models/Service.js';
import { TIPOS_VEHICULO } from '../utils/vehicleTypes.js';

// Limpia la lista de precios que llega del cliente: descarta tipos inválidos y
// precios vacíos o en cero. Si un tipo viene repetido, gana el último.
const normalizarPrecios = (precios) => {
  if (!Array.isArray(precios)) return [];

  const porTipo = new Map();
  for (const item of precios) {
    const precio = Number(item?.precio);
    if (TIPOS_VEHICULO.includes(item?.tipoVehiculo) && Number.isFinite(precio) && precio > 0) {
      porTipo.set(item.tipoVehiculo, precio);
    }
  }

  return [...porTipo].map(([tipoVehiculo, precio]) => ({ tipoVehiculo, precio }));
};

const MENSAJE_SIN_PRECIOS = 'Debes indicar el precio de al menos un tipo de vehículo';

// Obtener todos los servicios activos
export const obtenerServicios = async (req, res) => {
  try {
    const servicios = await Service.find({ activo: { $ne: false } });
    res.json(servicios);
  } catch (error) {
    console.error('Error en obtenerServicios:', error);
    res.status(500).json({ mensaje: 'Error al obtener servicios', error: error.message });
  }
};

// Crear un nuevo servicio con sus precios por tipo de vehículo
export const crearServicio = async (req, res) => {
  try {
    const {
      nombre,
      nombreServicio,
      descripcion,
      precios,
      duracionEstimadaMinutos,
      image,
      imagenUrl
    } = req.body;

    const nombreFinal = String(nombreServicio || nombre || '').trim();
    if (!nombreFinal) {
      return res.status(400).json({ mensaje: 'El nombre del servicio es obligatorio' });
    }

    const listaPrecios = normalizarPrecios(precios);
    if (listaPrecios.length === 0) {
      return res.status(400).json({ mensaje: MENSAJE_SIN_PRECIOS });
    }

    const nuevoServicio = new Service({
      nombreServicio: nombreFinal,
      descripcion: descripcion || '',
      imagenUrl: imagenUrl || image || '',
      precios: listaPrecios,
      duracionEstimadaMinutos: duracionEstimadaMinutos ? Number(duracionEstimadaMinutos) : 30,
      activo: true
    });

    await nuevoServicio.save();
    console.log('Servicio guardado exitosamente:', nuevoServicio);
    res.status(201).json({ mensaje: 'Servicio creado exitosamente', servicio: nuevoServicio });
  } catch (error) {
    console.error('Error detallado al crear servicio:', error);
    const status = error.name === 'ValidationError' ? 400 : 500;
    res.status(status).json({ mensaje: 'Error al crear servicio', error: error.message });
  }
};

// Actualizar un servicio existente por ID
export const actualizarServicio = async (req, res) => {
  try {
    const {
      nombre,
      nombreServicio,
      descripcion,
      precios,
      duracionEstimadaMinutos,
      image,
      imagenUrl
    } = req.body;

    const valorNombre = String(nombreServicio || nombre || '').trim();
    const valorImagen = imagenUrl !== undefined ? imagenUrl : image;

    let listaPrecios;
    if (precios !== undefined) {
      listaPrecios = normalizarPrecios(precios);
      if (listaPrecios.length === 0) {
        return res.status(400).json({ mensaje: MENSAJE_SIN_PRECIOS });
      }
    }

    const datosActualizados = {
      ...(valorNombre && { nombreServicio: valorNombre }),
      ...(descripcion !== undefined && { descripcion }),
      ...(valorImagen !== undefined && { imagenUrl: valorImagen }),
      ...(listaPrecios && { precios: listaPrecios }),
      ...(duracionEstimadaMinutos !== undefined && { duracionEstimadaMinutos: Number(duracionEstimadaMinutos) })
    };

    const servicioActualizado = await Service.findByIdAndUpdate(
      req.params.id,
      datosActualizados,
      { returnDocument: 'after', runValidators: true }
    );

    if (!servicioActualizado) {
      return res.status(404).json({ mensaje: 'Servicio no encontrado' });
    }

    res.json({ mensaje: 'Servicio actualizado exitosamente', servicio: servicioActualizado });
  } catch (error) {
    console.error('Error al actualizar servicio:', error);
    const status = error.name === 'ValidationError' ? 400 : 500;
    res.status(status).json({ mensaje: 'Error al actualizar servicio', error: error.message });
  }
};

// Eliminar un servicio
export const eliminarServicio = async (req, res) => {
  try {
    const servicioEliminado = await Service.findByIdAndDelete(req.params.id);

    if (!servicioEliminado) {
      return res.status(404).json({ mensaje: 'Servicio no encontrado' });
    }

    res.json({ mensaje: 'Servicio eliminado correctamente' });
  } catch (error) {
    console.error('Error al eliminar servicio:', error);
    res.status(500).json({ mensaje: 'Error al eliminar servicio', error: error.message });
  }
};

export default {
  obtenerServicios,
  crearServicio,
  actualizarServicio,
  eliminarServicio
};