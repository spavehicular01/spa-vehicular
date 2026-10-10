import 'package:flutter/material.dart';
import '../add_vehicle_screen.dart';
import '../../theme/app_theme.dart';
import 'delete_vehicle_dialog.dart';
import 'vehicle_actions.dart';
import 'vehicles_card.dart';
import 'vehicles_sheet.dart';

/// Tarjeta "Mis Vehículos" con toda su lógica: carga, lista, registrar,
/// editar y eliminar vehículos.
class VehiclesSection extends StatefulWidget {
  final List<Map<String, String>> vehiculosIniciales;
  final Function(List<Map<String, String>>) onVehiculosChanged;

  const VehiclesSection({
    super.key,
    required this.vehiculosIniciales,
    required this.onVehiculosChanged,
  });

  @override
  State<VehiclesSection> createState() => _VehiclesSectionState();
}

class _VehiclesSectionState extends State<VehiclesSection> {
  late List<Map<String, String>> _lista;
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _lista = List.from(widget.vehiculosIniciales);
    _cargarVehiculos();
  }

  /// Fuente de verdad: el backend. Se llama al abrir y después de
  /// registrar o eliminar un vehículo.
  Future<void> _cargarVehiculos({StateSetter? setModalState}) async {
    final lista = await cargarVehiculosUsuario();
    if (!mounted) return;

    setState(() {
      if (lista != null) _lista = lista;
      _cargando = false;
    });

    try {
      setModalState?.call(() {});
    } catch (_) {
      // El bottom sheet ya se cerró; no pasa nada.
    }

    if (lista != null) widget.onVehiculosChanged(lista);
  }

  Future<void> _abrirAgregarEditarVehiculo({
    Map<String, String>? vehiculo,
    StateSetter? setModalState,
  }) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddVehicleScreen(vehicleToEdit: vehiculo),
      ),
    );

    // AddVehicleScreen devuelve `true` cuando el backend confirmó el registro.
    if (result == true) {
      await _cargarVehiculos(setModalState: setModalState);
    }
  }

  Future<void> _eliminarVehiculo(
    Map<String, String> car,
    StateSetter setModalState,
  ) async {
    final confirmado = await confirmarEliminacionVehiculo(context);
    if (confirmado != true) return;

    final ok = await eliminarVehiculoUsuario(car);
    if (!mounted) return;

    if (ok) {
      await _cargarVehiculos(setModalState: setModalState);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudo eliminar el vehículo'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  void _mostrarMisVehiculos() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => VehiclesSheet(
          cargando: _cargando,
          vehiculos: _lista,
          onCerrar: () => Navigator.pop(ctx),
          onAgregar: () => _abrirAgregarEditarVehiculo(setModalState: setModalState),
          onEditar: (car) => _abrirAgregarEditarVehiculo(
            vehiculo: car,
            setModalState: setModalState,
          ),
          onEliminar: (car) => _eliminarVehiculo(car, setModalState),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return VehiclesCard(
      cargando: _cargando,
      cantidad: _lista.length,
      onTap: _mostrarMisVehiculos,
    );
  }
}
