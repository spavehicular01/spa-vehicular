const Service = require('../models/Service');

// Obtener todos los servicios activos
exports.obtenerServicios = async (req, res) => {
  try {
    const servicios = await Service.find({ activo: true });
    res.json(servicios);
  } catch (error) {
    res.status(500).json({ mensaje: 'Error al obtener servicios', error: error.message });
  }
};

// Crear un nuevo servicio mapeando los datos recibidos desde Flutter
exports.crearServicio = async (req, res) => {
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
      nombreServicio: nombreServicio || nombre,
      descripcion: descripcion || '',
      precio: precio || 0,
      imagenUrl: image || imagenUrl || '',
      duracionEstimadaMinutos: duracionEstimadaMinutos || 30
    });

    await nuevoServicio.save();
    res.status(201).json({ mensaje: 'Servicio creado exitosamente', servicio: nuevoServicio });
  } catch (error) {
    res.status(500).json({ mensaje: 'Error al crear servicio', error: error.message });
  }
};

// Actualizar un servicio existente por ID
exports.actualizarServicio = async (req, res) => {
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
      ...(precio !== undefined && { precio }),
      ...(image || imagenUrl ? { imagenUrl: image || imagenUrl } : {}),
      ...(duracionEstimadaMinutos !== undefined && { duracionEstimadaMinutos })
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
    res.status(500).json({ mensaje: 'Error al actualizar servicio', error: error.message });
  }
};

// Eliminar un servicio (o desactivarlo si manejas borrado lógico)
exports.eliminarServicio = async (req, res) => {
  try {
    const servicioEliminado = await Service.findByIdAndDelete(req.params.id);

    if (!servicioEliminado) {
      return res.status(404).json({ mensaje: 'Servicio no encontrado' });
    }

    res.json({ mensaje: 'Servicio eliminado correctamente' });
  } catch (error) {
    res.status(500).json({ mensaje: 'Error al eliminar servicio', error: error.message });
  }
};