import 'package:flutter/material.dart';

/// Tipos de vehículo. Los valores deben coincidir con src/utils/vehicleTypes.js
/// en el backend.
class TipoVehiculo {
  final String valor;
  final String etiqueta;
  final IconData icono;

  const TipoVehiculo(this.valor, this.etiqueta, this.icono);
}

const List<TipoVehiculo> tiposVehiculo = [
  TipoVehiculo('automovil', 'Automóvil', Icons.directions_car),
  TipoVehiculo('camioneta_pequena', 'Camioneta pequeña', Icons.airport_shuttle),
  TipoVehiculo('camioneta_grande', 'Camioneta grande', Icons.airport_shuttle),
  TipoVehiculo('motocicleta', 'Motocicleta', Icons.two_wheeler),
  TipoVehiculo('turbo_pequena', 'Turbo pequeña', Icons.local_shipping),
  TipoVehiculo('turbo_grande', 'Turbo grande', Icons.local_shipping),
];

/// Nombre para mostrar de un tipo (si no se reconoce, devuelve el valor tal cual).
String etiquetaTipoVehiculo(String valor) {
  for (final t in tiposVehiculo) {
    if (t.valor == valor) return t.etiqueta;
  }
  return valor;
}

IconData iconoTipoVehiculo(String valor) {
  for (final t in tiposVehiculo) {
    if (t.valor == valor) return t.icono;
  }
  return Icons.directions_car;
}
