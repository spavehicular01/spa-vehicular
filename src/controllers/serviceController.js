const Service = require('../models/Service');

exports.obtenerServicios = async (req, res) => {
  try {
    const servicios = await Service.find({ activo: true });
    res.json(servicios);
  } catch (error) {
    res.status(500).json({ mensaje: 'Error al obtener servicios', error: error.message });
  }
};

exports.crearServicio = async (req, res) => {
  try {
    const nuevoServicio = new Service(req.body);
    await nuevoServicio.save();
    res.status(201).json({ mensaje: 'Servicio creado exitosamente', servicio: nuevoServicio });
  } catch (error) {
    res.status(500).json({ mensaje: 'Error al crear servicio', error: error.message });
  }
};