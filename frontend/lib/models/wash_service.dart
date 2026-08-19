class WashService {
  final String id;
  final String title;
  final String description;
  final double price;
  final String imageUrl;

  WashService({
    required this.id,
    required this.title,
    required this.description,
    required this.price,
    required this.imageUrl,
  });

  factory WashService.fromJson(Map<String, dynamic> json) {
    return WashService(
      id: json['productId'] ?? json['_id'] ?? '',
      title: json['Nombre'] ?? 'Servicio sin nombre',
      description: json['Descripcion'] ?? 'Sin descripción',
      price: (json['Precio'] as num?)?.toDouble() ?? 0.0,
      imageUrl: json['Image'] ?? '',
    );
  }
}