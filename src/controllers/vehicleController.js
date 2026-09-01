const Vehicle = require('../models/Vehicle');

// 1. Registrar un vehículo
exports.registrarVehiculo = async (req, res) => {
  try {
    const { usuarioId, placa, marca, referencia, modelo, tipoVehiculo } = req.body;

    // Validación de campos obligatorios
    if (!usuarioId || !placa || !marca || !referencia || !modelo || !tipoVehiculo) {
      return res.status(400).json({ 
        ok: false, 
        mensaje: 'Todos los campos son obligatorios: usuarioId, placa, marca, referencia, modelo y tipoVehiculo' 
      });
    }

    const placaLimpia = placa.trim().toUpperCase();

    // Evitar placas duplicadas
    const existePlaca = await Vehicle.findOne({ placa: placaLimpia });
    if (existePlaca) {
      return res.status(400).json({ 
        ok: false, 
        mensaje: 'Un vehículo con esta placa ya está registrado' 
      });
    }

    const nuevoVehiculo = new Vehicle({
      usuarioId,
      placa: placaLimpia,
      marca: marca.trim(),
      referencia: referencia.trim(),
      modelo,
      tipoVehiculo
    });

    await nuevoVehiculo.save();

    return res.status(201).json({
      ok: true,
      mensaje: 'Vehículo registrado exitosamente',
      vehiculo: nuevoVehiculo
    });

  } catch (error) {
    console.error('Error al registrar vehículo:', error);
    return res.status(500).json({ 
      ok: false, 
      mensaje: 'Error al registrar vehículo', 
      error: error.message 
    });
  }
};

// 2. Obtener vehículos por usuario
exports.obtenerVehiculosPorUsuario = async (req, res) => {
  try {
    const { usuarioId } = req.params;

    // Retorna los más recientes primero
    const vehiculos = await Vehicle.find({ usuarioId }).sort({ createdAt: -1 });

    return res.status(200).json({
      ok: true,
      vehiculos
    });

  } catch (error) {
    console.error('Error al consultar vehículos:', error);
    return res.status(500).json({ 
      ok: false, 
      mensaje: 'Error al consultar vehículos', 
      error: error.message 
    });
  }
};