class Appointment {
  final String id;
  final String usuarioId;
  final String serviceName;
  final String vehiculo;
  final DateTime dateTime;
  final int durationMinutes;
  final String estado;

  Appointment({
    required this.id,
    required this.usuarioId,
    required this.serviceName,
    required this.vehiculo,
    required this.dateTime,
    this.durationMinutes = 30,
    this.estado = 'Pendiente',
  });

  // Convertir respuesta JSON de MongoDB a Modelo Dart
  factory Appointment.fromJson(Map<String, dynamic> json) {
    return Appointment(
      id: json['_id'] ?? '',
      usuarioId: json['usuario'] is Map ? json['usuario']['_id'] : (json['usuario'] ?? ''),
      serviceName: json['servicioNombre'] ?? json['serviceName'] ?? 'Lavado General',
      vehiculo: json['vehiculo'] ?? 'Vehículo',
      dateTime: json['fechaHoraCita'] != null
          ? DateTime.tryParse(json['fechaHoraCita'].toString()) ?? DateTime.now()
          : DateTime.now(),
      durationMinutes: json['durationMinutes'] ?? 30,
      estado: json['estado'] ?? 'Pendiente',
    );
  }

  // Convertir Modelo Dart a Map/JSON para enviar al Backend
  Map<String, dynamic> toJson() {
    return {
      'usuario': usuarioId,
      'servicioNombre': serviceName,
      'vehiculo': vehiculo,
      'fechaHoraCita': dateTime.toIso8601String(),
      'durationMinutes': durationMinutes,
      'estado': estado,
    };
  }
}