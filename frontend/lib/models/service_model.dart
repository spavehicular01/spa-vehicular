class ServiceModel {
  final String id;
  final String nombre;
  final String descripcion;
  final double precio;
  final int duracionMinutos;

  ServiceModel({
    required this.id,
    required this.nombre,
    required this.descripcion,
    required this.precio,
    required this.duracionMinutos,
  });

  // Mapea el JSON que responderá tu backend
  factory ServiceModel.fromJson(Map<String, dynamic> json) {
    return ServiceModel(
      id: json['_id'] ?? '',
      nombre: json['nombre'] ?? 'Sin nombre',
      descripcion: json['descripcion'] ?? 'Sin descripción',
      precio: (json['precio'] as num?)?.toDouble() ?? 0.0,
      duracionMinutos: json['duracionMinutos'] ?? 30,
    );
  }
}