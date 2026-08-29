import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/wash_api_service.dart';

class AdminServicesScreen extends StatefulWidget {
  const AdminServicesScreen({super.key});

  @override
  State<AdminServicesScreen> createState() => _AdminServicesScreenState();
}

class _AdminServicesScreenState extends State<AdminServicesScreen> {
  List<dynamic> _servicios = [];
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargarServicios();
  }

  Future<void> _cargarServicios() async {
    setState(() => _cargando = true);
    try {
      final lista = await WashApiService.getLavados();
      if (mounted) {
        setState(() {
          _servicios = lista;
          _cargando = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _cargando = false);
      }
    }
  }

  void _mostrarFormularioServicio({dynamic servicio}) {
    // Extracción segura soportando Objetos con propiedades o Mapas JSON
    final String idServicio = _obtenerCampo(servicio, ['id', '_id']);
    final nombreController = TextEditingController(
      text: _obtenerCampo(servicio, ['nombreServicio', 'nombre', 'name']),
    );
    final descController = TextEditingController(
      text: _obtenerCampo(servicio, ['descripcion', 'description']),
    );
    
    final dynamic valPrecio = _obtenerValor(servicio, ['precio', 'price']);
    final precioController = TextEditingController(
      text: valPrecio != null ? valPrecio.toString() : '',
    );

    XFile? imagenSeleccionada;
    bool subiendo = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateModal) {
          Future<void> seleccionarImagen() async {
            final ImagePicker picker = ImagePicker();
            final XFile? image = await picker.pickImage(
              source: ImageSource.gallery,
              imageQuality: 80,
            );
            if (image != null) {
              setStateModal(() {
                imagenSeleccionada = image;
              });
            }
          }

          final String? imageUrl = _obtenerCampo(servicio, ['imagenUrl', 'image', 'imageUrl']);

          return AlertDialog(
            title: Text(servicio == null ? 'Nuevo Servicio' : 'Editar Servicio'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GestureDetector(
                    onTap: subiendo ? null : seleccionarImagen,
                    child: Container(
                      height: 120,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color.fromARGB(255, 0, 30, 255)),
                      ),
                      child: imagenSeleccionada != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Image.file(
                                File(imagenSeleccionada!.path),
                                fit: BoxFit.cover,
                              ),
                            )
                          : (imageUrl != null && imageUrl.isNotEmpty)
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: Image.network(
                                    imageUrl,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) =>
                                        const Icon(Icons.broken_image, size: 40, color: Colors.grey),
                                  ),
                                )
                              : const Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.add_a_photo, color: Color.fromARGB(255, 2, 27, 255), size: 30),
                                    SizedBox(height: 6),
                                    Text('Agregar foto del lavado', style: TextStyle(fontSize: 12)),
                                  ],
                                ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: nombreController,
                    enabled: !subiendo,
                    decoration: const InputDecoration(labelText: 'Nombre del servicio'),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: descController,
                    enabled: !subiendo,
                    decoration: const InputDecoration(labelText: 'Descripción'),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: precioController,
                    enabled: !subiendo,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Precio (\$)'),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: subiendo ? null : () => Navigator.pop(context),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(255, 0, 30, 255),
                  foregroundColor: Colors.white,
                ),
                onPressed: subiendo
                    ? null
                    : () async {
                        if (nombreController.text.trim().isEmpty || precioController.text.trim().isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Por favor completa los campos requeridos')),
                          );
                          return;
                        }

                        setStateModal(() => subiendo = true);

                        String? urlFotoFinal = imageUrl;

                        if (imagenSeleccionada != null) {
                          final String? subida = await WashApiService.subirImagen(imagenSeleccionada!);
                          if (subida != null) {
                            urlFotoFinal = subida;
                          }
                        }

                        bool exito = false;
                        if (servicio == null) {
                          exito = await WashApiService.crearLavado(
                            nombre: nombreController.text.trim(),
                            descripcion: descController.text.trim(),
                            precio: double.tryParse(precioController.text) ?? 0.0,
                            image: urlFotoFinal,
                          );
                        } else {
                          exito = await WashApiService.actualizarServicio(
                            id: idServicio,
                            nombre: nombreController.text.trim(),
                            descripcion: descController.text.trim(),
                            precio: double.tryParse(precioController.text) ?? 0.0,
                            image: urlFotoFinal,
                          );
                        }

                        if (context.mounted) {
                          if (exito) {
                            Navigator.pop(context);
                            _cargarServicios();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(servicio != null ? 'Servicio actualizado' : 'Servicio agregado'),
                                backgroundColor: const Color.fromARGB(255, 0, 30, 255),
                              ),
                            );
                          } else {
                            setStateModal(() => subiendo = false);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Error al guardar en el servidor'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        }
                      },
                child: subiendo
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : Text(servicio == null ? 'Guardar' : 'Actualizar'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _eliminarServicio(String id) async {
    final exito = await WashApiService.eliminarServicio(id);
    if (exito) {
      _cargarServicios();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Servicio eliminado'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Funciones auxiliares para evitar NoSuchMethodError independientemente del tipo que retorne la API
  String _obtenerCampo(dynamic objeto, List<String> llaves) {
    if (objeto == null) return '';
    for (var llave in llaves) {
      try {
        if (objeto is Map && objeto.containsKey(llave) && objeto[llave] != null) {
          return objeto[llave].toString();
        }
      } catch (_) {}
      try {
        var val = (objeto as dynamic);
        switch (llave) {
          case 'id': if (val.id != null) return val.id.toString(); break;
          case '_id': if (val.id != null) return val.id.toString(); break;
          case 'nombreServicio': if (val.nombreServicio != null) return val.nombreServicio.toString(); break;
          case 'nombre': if (val.nombre != null) return val.nombre.toString(); break;
          case 'descripcion': if (val.descripcion != null) return val.descripcion.toString(); break;
          case 'imagenUrl': if (val.imagenUrl != null) return val.imagenUrl.toString(); break;
          case 'image': if (val.image != null) return val.image.toString(); break;
        }
      } catch (_) {}
    }
    return '';
  }

  dynamic _obtenerValor(dynamic objeto, List<String> llaves) {
    if (objeto == null) return null;
    for (var llave in llaves) {
      try {
        if (objeto is Map && objeto.containsKey(llave)) {
          return objeto[llave];
        }
      } catch (_) {}
      try {
        var val = (objeto as dynamic);
        if (llave == 'precio' && val.precio != null) return val.precio;
        if (llave == 'price' && val.price != null) return val.price;
      } catch (_) {}
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Servicios y Precios'),
        backgroundColor: const Color.fromARGB(255, 0, 30, 255),
        foregroundColor: Colors.white,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _mostrarFormularioServicio(),
        backgroundColor: const Color.fromARGB(255, 8, 0, 255),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Nuevo Servicio'),
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : _servicios.isEmpty
              ? const Center(child: Text('No hay servicios registrados.'))
              : RefreshIndicator(
                  onRefresh: _cargarServicios,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16.0),
                    itemCount: _servicios.length,
                    itemBuilder: (context, index) {
                      final item = _servicios[index];
                      final String id = _obtenerCampo(item, ['id', '_id']);
                      final String nombre = _obtenerCampo(item, ['nombreServicio', 'nombre', 'name']);
                      final String descripcion = _obtenerCampo(item, ['descripcion', 'description']);
                      final num precio = _obtenerValor(item, ['precio', 'price']) ?? 0;
                      final String foto = _obtenerCampo(item, ['imagenUrl', 'image', 'imageUrl']);

                      return Card(
                        elevation: 2,
                        margin: const EdgeInsets.only(bottom: 12.0),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(16.0),
                          leading: foto.isNotEmpty
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.network(
                                    foto,
                                    width: 50,
                                    height: 50,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => const Icon(Icons.local_car_wash, size: 40, color: Colors.teal),
                                  ),
                                )
                              : const Icon(Icons.local_car_wash, size: 40, color: Colors.teal),
                          title: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  nombre.isNotEmpty ? nombre : 'Servicio',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Text(
                                '\$${precio.toStringAsFixed(0)}',
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
                              Text(descripcion),
                            ],
                          ),
                          trailing: PopupMenuButton<String>(
                            onSelected: (option) {
                              if (option == 'editar') {
                                _mostrarFormularioServicio(servicio: item);
                              } else if (option == 'eliminar') {
                                if (id.isNotEmpty) {
                                  _eliminarServicio(id);
                                }
                              }
                            },
                            itemBuilder: (context) => const [
                              PopupMenuItem(
                                value: 'editar',
                                child: Row(
                                  children: [
                                    Icon(Icons.edit, color: Colors.teal, size: 20),
                                    SizedBox(width: 8),
                                    Text('Editar'),
                                  ],
                                ),
                              ),
                              PopupMenuItem(
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
                ),
    );
  }
}