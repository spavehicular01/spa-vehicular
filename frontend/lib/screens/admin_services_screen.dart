import 'package:flutter/material.dart';

class AdminServicesScreen extends StatefulWidget {
  const AdminServicesScreen({super.key});

  @override
  State<AdminServicesScreen> createState() => _AdminServicesScreenState();
}

class _AdminServicesScreenState extends State<AdminServicesScreen> {
  final List<Map<String, dynamic>> _servicios = [
    {
      'id': '1',
      'nombre': 'Lavado General',
      'descripcion': 'Lavado exterior, aspirado de cojinería y limpieza de vidrios.',
      'precio': 25000,
      'duracion': '45 min',
    },
    {
      'id': '2',
      'nombre': 'Polichado y Encerado',
      'descripcion': 'Protección de pintura con cera de alta densidad y pulido.',
      'precio': 60000,
      'duracion': '90 min',
    },
    {
      'id': '3',
      'nombre': 'Lavado de Cojinería',
      'descripcion': 'Desinfección profunda a vapor e higienización de asientos.',
      'precio': 80000,
      'duracion': '120 min',
    },
  ];

  void _mostrarFormularioServicio({Map<String, dynamic>? servicio, int? index}) {
    final nombreController = TextEditingController(text: servicio?['nombre'] ?? '');
    final descController = TextEditingController(text: servicio?['descripcion'] ?? '');
    final precioController = TextEditingController(
        text: servicio != null ? servicio['precio'].toString() : '');
    final duracionController = TextEditingController(text: servicio?['duracion'] ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(servicio == null ? 'Nuevo Servicio' : 'Editar Servicio'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nombreController,
                decoration: const InputDecoration(labelText: 'Nombre del servicio'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: descController,
                decoration: const InputDecoration(labelText: 'Descripción'),
                maxLines: 2,
              ),
              const SizedBox(height: 8),
              TextField(
                controller: precioController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Precio (\$)'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: duracionController,
                decoration: const InputDecoration(labelText: 'Duración estimada (ej: 45 min)'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              if (nombreController.text.isEmpty || precioController.text.isEmpty) {
                return;
              }

              setState(() {
                final nuevoItem = {
                  'id': servicio?['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
                  'nombre': nombreController.text,
                  'descripcion': descController.text,
                  'precio': int.tryParse(precioController.text) ?? 0,
                  'duracion': duracionController.text,
                };

                if (index != null) {
                  _servicios[index] = nuevoItem;
                } else {
                  _servicios.add(nuevoItem);
                }
              });

              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    index != null ? 'Servicio actualizado' : 'Servicio agregado',
                  ),
                  backgroundColor: Colors.teal,
                ),
              );
            },
            child: Text(servicio == null ? 'Guardar' : 'Actualizar'),
          ),
        ],
      ),
    );
  }

  void _eliminarServicio(int index) {
    setState(() {
      _servicios.removeAt(index);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Servicio eliminado'),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Servicios y Precios'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _mostrarFormularioServicio(),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Nuevo Servicio'),
      ),
      body: _servicios.isEmpty
          ? const Center(child: Text('No hay servicios disponibles.'))
          : ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: _servicios.length,
              itemBuilder: (context, index) {
                final item = _servicios[index];
                return Card(
                  elevation: 2,
                  margin: const EdgeInsets.only(bottom: 12.0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16.0),
                    title: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          item['nombre'],
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          '\$${item['precio']}',
                          style: const TextStyle(
                            color: Colors.teal,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 6),
                        Text(item['descripcion']),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(Icons.timer_outlined, size: 16, color: Colors.grey),
                            const SizedBox(width: 4),
                            Text(
                              item['duracion'],
                              style: const TextStyle(color: Colors.grey, fontSize: 13),
                            ),
                          ],
                        ),
                      ],
                    ),
                    trailing: PopupMenuButton<String>(
                      onSelected: (option) {
                        if (option == 'editar') {
                          _mostrarFormularioServicio(servicio: item, index: index);
                        } else if (option == 'eliminar') {
                          _eliminarServicio(index);
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'editar',
                          child: Row(
                            children: [
                              Icon(Icons.edit, color: Colors.teal, size: 20),
                              SizedBox(width: 8),
                              Text('Editar'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'eliminar',
                          child: Row(
                            children: [
                              Icon(Icons.delete, color: Colors.red, size: 20),
                              SizedBox(width: 8),
                              Text('Eliminar'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}