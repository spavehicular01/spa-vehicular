const Vehicle = require('../models/Vehicle');

// Obtener vehículos del usuario logueado
exports.obtenerVehiculosPorUsuario = async (req, res) => {
  try {
    const { usuarioId } = req.params;
    const vehiculos = await Vehicle.find({ usuario: usuarioId });
    res.status(200).json(vehiculos);
  } catch (error) {
    res.status(500).json({ error: 'Error al obtener vehículos' });
  }
};

// Registrar un nuevo vehículo (con foto opcional de Cloudinary)
exports.crearVehiculo = async (req, res) => {
  try {
    const { usuario, placa, marca, modelo, imagenUrl } = req.body;
    const nuevoVehiculo = new Vehicle({
      usuario,
      placa,
      marca,
      modelo,
      imagenUrl
    });
    await nuevoVehiculo.save();
    res.status(201).json(nuevoVehiculo);
  } catch (error) {
    res.status(500).json({ error: 'Error al registrar vehículo: ' + error.message });
  }
};