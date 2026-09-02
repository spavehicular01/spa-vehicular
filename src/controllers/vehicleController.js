import Vehicle from '../models/Vehicle.js';

// 1. Obtener vehículos de un usuario
export const getVehiclesByUser = async (req, res) => {
  try {
    const { userId } = req.params;
    const vehicles = await Vehicle.find({ usuarioId: userId });
    return res.status(200).json({ ok: true, vehicles });
  } catch (error) {
    console.error('Error al obtener vehículos:', error);
    return res.status(500).json({ ok: false, mensaje: 'Error al obtener los vehículos', error: error.message });
  }
};

// 2. Registrar un nuevo vehículo
export const registerVehicle = async (req, res) => {
  try {
    const { usuarioId, placa, marca, referencia, modelo, tipoVehiculo } = req.body;

    if (!usuarioId || !placa || !marca || !referencia || !modelo || !tipoVehiculo) {
      return res.status(400).json({ 
        ok: false, 
        mensaje: 'Todos los campos son obligatorios: usuarioId, placa, marca, referencia, modelo y tipoVehiculo' 
      });
    }

    const existePlaca = await Vehicle.findOne({ placa: placa.toUpperCase() });
    if (existePlaca) {
      return res.status(400).json({ ok: false, mensaje: 'Un vehículo con esta placa ya está registrado' });
    }

    const nuevoVehiculo = new Vehicle({
      usuarioId,
      placa: placa.toUpperCase(),
      marca,
      referencia,
      modelo,
      tipoVehiculo
    });

    await nuevoVehiculo.save();

    return res.status(201).json({
      ok: true,
      mensaje: 'Vehículo registrado exitosamente',
      vehicle: nuevoVehiculo
    });
  } catch (error) {
    console.error('Error al registrar vehículo:', error);
    return res.status(500).json({ ok: false, mensaje: 'Error al registrar el vehículo', error: error.message });
  }
};

// 3. Eliminar un vehículo
export const deleteVehicle = async (req, res) => {
  try {
    const { id } = req.params;
    const vehiculoEliminado = await Vehicle.findByIdAndDelete(id);

    if (!vehiculoEliminado) {
      return res.status(404).json({ ok: false, mensaje: 'Vehículo no encontrado' });
    }

    return res.status(200).json({ ok: true, mensaje: 'Vehículo eliminado correctamente' });
  } catch (error) {
    console.error('Error al eliminar vehículo:', error);
    return res.status(500).json({ ok: false, mensaje: 'Error al eliminar el vehículo', error: error.message });
  }
};

export default {
  getVehiclesByUser,
  registerVehicle,
  deleteVehicle
};

