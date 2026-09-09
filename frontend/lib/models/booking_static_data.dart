class BookingStaticData {
  // Lista de vehículos registrados (dinámicos / fallback)
  static const List<Map<String, String>> misVehiculos = [
    {'id': '64b0f1a23c8e4d001234567a', 'nombre': 'Mazda 3 - ABC-123'},
    {'id': '64b0f1a23c8e4d001234567b', 'nombre': 'Toyota Hilux - XYZ-789'},
    {'id': '64b0f1a23c8e4d001234567c', 'nombre': 'Chevrolet Onix - FGH-456'},
  ];

  // Lista de servicios registrados (dinámicos / fallback)
  // 'minutos' es obligatorio porque el backend requiere tiempoEstimadoMinutos
  static const List<Map<String, dynamic>> servicios = [
    {'id': '64b0f2a23c8e4d001234568a', 'nombre': 'Lavado Básico (30 min)', 'minutos': 30},
    {'id': '64b0f2a23c8e4d001234568b', 'nombre': 'Lavado Especial (45 min)', 'minutos': 45},
    {'id': '64b0f2a23c8e4d001234568c', 'nombre': 'Lavado General / Chasis (60 min)', 'minutos': 60},
    {'id': '64b0f2a23c8e4d001234568d', 'nombre': 'Polichado y Encerado (90 min)', 'minutos': 90},
    {'id': '64b0f2a23c8e4d001234568e', 'nombre': 'Coctel / Tapicería Profunda (120 min)', 'minutos': 120},
  ];
}