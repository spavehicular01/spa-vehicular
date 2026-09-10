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
      precio: (json['precio'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'tipoVehiculo': tipoVehiculo,
      'precio': precio,
    };
  }
}

class WashService {
  final String id;
  final String title;
  final String description;
  final List<PrecioVehiculo> precios;
  final String imageUrl;
  final int duracionMinutos;

  WashService({
    required this.id,
    required this.title,
    required this.description,
    required this.precios,
    required this.imageUrl,
    this.duracionMinutos = 30,
  });

  // Getter para obtener el precio base o el precio antiguo si no hay arreglo
  double get price {
    if (precios.isNotEmpty) {
      return precios.firstWhere(
        (p) => p.tipoVehiculo == 'automovil',
        orElse: () => precios.first,
      ).precio;
    }
    return 0.0;
  }

  // Alias por compatibilidad con el nuevo modelo
  double get precioBase => price;

  factory WashService.fromJson(Map<String, dynamic> json) {
    // Procesa el arreglo 'precios' del backend
    var rawPrecios = json['precios'] as List?;
    List<PrecioVehiculo> listaPrecios = [];

    if (rawPrecios != null && rawPrecios.isNotEmpty) {
      listaPrecios = rawPrecios.map((item) => PrecioVehiculo.fromJson(item)).toList();
    } else if (json['precio'] != null || json['Precio'] != null || json['price'] != null) {
      // Retrocompatibilidad con servicios creados previamente con precio único
      double p = (json['precio'] ?? json['Precio'] ?? json['price'] as num?)?.toDouble() ?? 0.0;
      listaPrecios = [PrecioVehiculo(tipoVehiculo: 'automovil', precio: p)];
    }

    return WashService(
      id: json['_id'] ?? json['id'] ?? json['productId'] ?? '',
      title: json['nombreServicio'] ?? json['nombre'] ?? json['Nombre'] ?? json['title'] ?? 'Servicio sin nombre',
      description: json['descripcion'] ?? json['Descripcion'] ?? json['description'] ?? 'Sin descripción',
      precios: listaPrecios,
      imageUrl: json['image'] ?? json['Image'] ?? json['imageUrl'] ?? '',
      duracionMinutos: json['duracionEstimadaMinutos'] ?? json['duracionMinutos'] ?? 30,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'nombreServicio': title,
      'descripcion': description,
      'precios': precios.map((p) => p.toJson()).toList(),
      'image': imageUrl,
      'duracionEstimadaMinutos': duracionMinutos,
    };
  }
}