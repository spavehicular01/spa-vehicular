import Service from '../models/Service.js';

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

// Crear un nuevo servicio mapeando el arreglo de precios por tipo de vehículo
export const crearServicio = async (req, res) => {
  try {
    const { 
      nombre, 
      nombreServicio, 
      descripcion, 
      precio, 
      precios, 
      duracionEstimadaMinutos 
    } = req.body;

    // Procesa el arreglo 'precios' o construye uno con 'automovil' por defecto
    const listaPrecios = Array.isArray(precios) && precios.length > 0
      ? precios
      : [{ tipoVehiculo: 'automovil', precio: precio ? Number(precio) : 0 }];

    const nuevoServicio = new Service({
      nombreServicio: nombreServicio || nombre || 'Sin nombre',
      descripcion: descripcion || '',
      precios: listaPrecios,
      duracionEstimadaMinutos: duracionEstimadaMinutos ? Number(duracionEstimadaMinutos) : 30,
      activo: true
    });

    await nuevoServicio.save();
    console.log('Servicio guardado exitosamente:', nuevoServicio);
    res.status(201).json({ mensaje: 'Servicio creado exitosamente', servicio: nuevoServicio });
  } catch (error) {
    console.error('Error detallado al crear servicio:', error);
    res.status(500).json({ mensaje: 'Error al crear servicio', error: error.message });
  }
};

// Actualizar un servicio existente por ID
export const actualizarServicio = async (req, res) => {
  try {
    const { 
      nombre, 
      nombreServicio, 
      descripcion, 
      precio, 
      precios, 
      duracionEstimadaMinutos 
    } = req.body;

    const valorNombre = nombreServicio || nombre;

    const listaPrecios = Array.isArray(precios) && precios.length > 0
      ? precios
      : precio !== undefined ? [{ tipoVehiculo: 'automovil', precio: Number(precio) }] : undefined;

    const datosActualizados = {
      ...(valorNombre && { nombreServicio: valorNombre }),
      ...(descripcion !== undefined && { descripcion }),
      ...(listaPrecios && { precios: listaPrecios }),
      ...(duracionEstimadaMinutos !== undefined && { duracionEstimadaMinutos: Number(duracionEstimadaMinutos) })
    };

    const servicioActualizado = await Service.findByIdAndUpdate(
      req.params.id, 
      datosActualizados, 
      { new: true, runValidators: true }
    );

    if (!servicioActualizado) {
      return res.status(404).json({ mensaje: 'Servicio no encontrado' });
    }

    res.json({ mensaje: 'Servicio actualizado exitosamente', servicio: servicioActualizado });
  } catch (error) {
    console.error('Error al actualizar servicio:', error);
    res.status(500).json({ mensaje: 'Error al actualizar servicio', error: error.message });
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