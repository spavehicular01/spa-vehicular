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
      id: json['_id'] ?? json['id'] ?? json['productId'] ?? '',
      // Soporta tanto minúsculas (backend típico) como mayúsculas
      title: json['nombre'] ?? json['Nombre'] ?? json['title'] ?? 'Servicio sin nombre',
      description: json['descripcion'] ?? json['Descripcion'] ?? json['description'] ?? 'Sin descripción',
      price: (json['precio'] ?? json['Precio'] ?? json['price'] as num?)?.toDouble() ?? 0.0,
      imageUrl: json['image'] ?? json['Image'] ?? json['imageUrl'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'nombre': title,
      'descripcion': description,
      'precio': price,
      'image': imageUrl,
    };
  }
}