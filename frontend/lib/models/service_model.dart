class PrecioVehiculo {
  final String tipoVehiculo;
  final double precio;

  PrecioVehiculo({
    required this.tipoVehiculo,
    required this.precio,
  });

  factory PrecioVehiculo.fromJson(Map<String, dynamic> json) {
    return PrecioVehiculo(
      tipoVehiculo: json['tipoVehiculo'] ?? 'automovil',
      precio: double.tryParse(json['precio']?.toString() ?? '0') ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'tipoVehiculo': tipoVehiculo,
      'precio': precio,
    };
  }
}

class ServiceModel {
  final String id;
  final String nombre;
  final String descripcion;
  final List<PrecioVehiculo> precios;
  final int duracionMinutos;

  ServiceModel({
    required this.id,
    required this.nombre,
    required this.descripcion,
    required this.precios,
    required this.duracionMinutos,
  });

  // Retorna el precio base de 'automovil' o la primera tarifa disponible
  double get precioBase {
    if (precios.isEmpty) return 0.0;
    return precios.firstWhere(
      (p) => p.tipoVehiculo == 'automovil',
      orElse: () => precios.first,
    ).precio;
  }

  factory ServiceModel.fromJson(Map<String, dynamic> json) {
    var rawPrecios = json['precios'] as List?;
    List<PrecioVehiculo> listaPrecios = rawPrecios != null
        ? rawPrecios.map((item) => PrecioVehiculo.fromJson(item)).toList()
        : [];

    return ServiceModel(
      id: json['_id'] ?? json['id'] ?? '',
      nombre: json['nombreServicio'] ?? json['nombre'] ?? 'Sin nombre',
      descripcion: json['descripcion'] ?? 'Sin descripción',
      precios: listaPrecios,
      duracionMinutos: json['duracionEstimadaMinutos'] ?? json['duracionMinutos'] ?? 30,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombreServicio': nombre,
      'descripcion': descripcion,
      'precios': precios.map((p) => p.toJson()).toList(),
      'duracionEstimadaMinutos': duracionMinutos,
    };
  }
}