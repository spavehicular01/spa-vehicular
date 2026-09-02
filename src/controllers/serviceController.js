import Service from '../models/Service.js';

// Obtener todos los servicios activos
export const obtenerServicios = async (req, res) => {
  try {
    // Si tus servicios en BD no tienen el campo 'activo', se muestran todos los existentes.
    // Si manejan 'activo', busca los que no estén explícitamente desactivados (false).
    const servicios = await Service.find({ activo: { $ne: false } });
    res.json(servicios);
  } catch (error) {
    console.error('Error en obtenerServicios:', error);
    res.status(500).json({ mensaje: 'Error al obtener servicios', error: error.message });
  }
};

// Crear un nuevo servicio mapeando los datos recibidos desde Flutter
export const crearServicio = async (req, res) => {
  try {
    const { 
      nombre, 
      nombreServicio, 
      descripcion, 
      precio, 
      image, 
      imagenUrl, 
      duracionEstimadaMinutos 
    } = req.body;

    const nuevoServicio = new Service({
      nombreServicio: nombreServicio || nombre || 'Sin nombre',
      descripcion: descripcion || '',
      precio: precio ? Number(precio) : 0, // Garantizar que sea número
      imagenUrl: imagenUrl || image || '',
      duracionEstimadaMinutos: duracionEstimadaMinutos ? Number(duracionEstimadaMinutos) : 30,
      activo: true // Asegurar que el servicio quede visible para los usuarios
    });

    await nuevoServicio.save();
    console.log('Servicio guardado exitosamente:', nuevoServicio);
    res.status(201).json({ mensaje: 'Servicio creado exitosamente', servicio: nuevoServicio });
  } catch (error) {
    console.error('Error detallado al crear servicio:', error); // Esto imprimirá la causa exacta en la terminal de Node
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
      image, 
      imagenUrl, 
      duracionEstimadaMinutos 
    } = req.body;

    const datosActualizados = {
      ...(nombre || nombreServicio ? { nombreServicio: nombreServicio || nombre } : {}),
      ...(descripcion !== undefined && { descripcion }),
      ...(precio !== undefined && { precio: Number(precio) }),
      ...(image || imagenUrl ? { imagenUrl: image || imagenUrl } : {}),
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

// Eliminar un servicio (o desactivarlo si manejas borrado lógico)
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