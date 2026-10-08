import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Colores semánticos por estado (de estatus, no de marca).
Color obtenerColorEstado(String? estado) {
  switch ((estado ?? '').toLowerCase()) {
    case 'pendiente':
      return Colors.orange;
    case 'confirmada':
      return Colors.indigo;
    case 'en_proceso':
      return AppColors.secondary;
    case 'finalizada':
      return Colors.green;
    case 'cancelada':
      return Colors.red;
    case 'reprogramada':
      return Colors.purple;
    default:
      return AppColors.muted;
  }
}

/// Etiquetas iguales a las que ve el administrador.
String obtenerEtiquetaEstado(String? estado) {
  switch ((estado ?? '').toLowerCase()) {
    case 'pendiente':
      return 'Pendiente';
    case 'confirmada':
      return 'Confirmada';
    case 'en_proceso':
      return 'En Proceso';
    case 'finalizada':
      return 'Completado';
    case 'cancelada':
      return 'Cancelada';
    case 'reprogramada':
      return 'Reprogramada';
    default:
      return estado ?? 'Pendiente';
  }
}

String obtenerNombreServicio(Map<String, dynamic> cita) {
  if (cita['servicioNombre'] != null &&
      cita['servicioNombre'].toString().isNotEmpty) {
    return cita['servicioNombre'];
  }
  if (cita['servicio'] is Map) {
    return cita['servicio']['nombreServicio'] ??
        cita['servicio']['nombre'] ??
        'Servicio de Lavado';
  }
  if (cita['servicioId'] is Map) {
    return cita['servicioId']['nombreServicio'] ??
        cita['servicioId']['nombre'] ??
        'Servicio de Lavado';
  }
  return 'Servicio de Lavado';
}

String obtenerDescripcionServicio(Map<String, dynamic> cita) {
  if (cita['servicioDescripcion'] != null &&
      cita['servicioDescripcion'].toString().isNotEmpty) {
    return cita['servicioDescripcion'];
  }
  if (cita['servicio'] is Map && cita['servicio']['descripcion'] != null) {
    return cita['servicio']['descripcion'];
  }
  if (cita['servicioId'] is Map && cita['servicioId']['descripcion'] != null) {
    return cita['servicioId']['descripcion'];
  }
  return 'Sin descripción registrada';
}
