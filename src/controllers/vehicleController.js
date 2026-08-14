const Vehicle = require('../models/Vehicle');

exports.registrarVehiculo = async (req, res) => {
  try {
    const nuevoVehiculo = new Vehicle(req.body);
    await nuevoVehiculo.save();
    res.status(201).json({ mensaje: 'Vehículo registrado', vehiculo: nuevoVehiculo });
  } catch (error) {
    res.status(500).json({ mensaje: 'Error al registrar vehículo', error: error.message });
  }
};

exports.obtenerVehiculosPorUsuario = async (req, res) => {
  try {
    const vehiculos = await Vehicle.find({ usuarioId: req.params.usuarioId });
    res.json(vehiculos);
  } catch (error) {
    res.status(500).json({ mensaje: 'Error al consultar vehículos', error: error.message });
  }
};