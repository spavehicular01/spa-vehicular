import 'package:flutter/material.dart';
import '../models/service_model.dart';
import '../services/wash_api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/admin/service_form_dialog.dart';
import '../widgets/service_prices_chips.dart';

class AdminServicesScreen extends StatefulWidget {
  const AdminServicesScreen({super.key});

  @override
  State<AdminServicesScreen> createState() => _AdminServicesScreenState();
}

class _AdminServicesScreenState extends State<AdminServicesScreen> {
  List<ServiceModel> _servicios = [];
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargarServicios();
  }

  Future<void> _cargarServicios() async {
    setState(() => _cargando = true);
    final lista = await WashApiService.getLavadosModel();
    if (!mounted) return;
    setState(() {
      _servicios = lista;
      _cargando = false;
    });
  }

  void _avisar(String texto, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(texto), backgroundColor: color),
    );
  }

  Future<void> _abrirFormulario({ServiceModel? servicio}) async {
    final guardado = await ServiceFormDialog.mostrar(context, servicio: servicio);
    if (guardado != true || !mounted) return;

    _cargarServicios();
    _avisar(
      servicio != null ? 'Servicio actualizado' : 'Servicio agregado',
      AppColors.secondary,
    );
  }

  Future<void> _eliminarServicio(String id) async {
    final exito = await WashApiService.eliminarServicio(id);
    if (!mounted) return;
    if (exito) {
      _cargarServicios();
      _avisar('Servicio eliminado', Colors.red);
    } else {
      _avisar('No se pudo eliminar el servicio', Colors.red);
    }
  }

  Widget _miniatura(ServiceModel s) {
    const iconoPorDefecto = Icon(Icons.local_car_wash, size: 40, color: AppColors.secondary);
    if (s.imagenUrl.isEmpty) return iconoPorDefecto;
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.network(
        s.imagenUrl,
        width: 50,
        height: 50,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => iconoPorDefecto,
      ),
    );
  }

  Widget _tarjetaServicio(ServiceModel item) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12.0),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16.0),
        leading: _miniatura(item),
        title: Text(
          item.nombre.isNotEmpty ? item.nombre : 'Servicio',
          style: AppTextStyles.bodyStrong,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 6),
            Text(item.descripcion, style: AppTextStyles.body),
            const SizedBox(height: 10),
            ServicePricesChips(service: item),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (option) {
            if (option == 'editar') {
              _abrirFormulario(servicio: item);
            } else if (option == 'eliminar' && item.id.isNotEmpty) {
              _eliminarServicio(item.id);
            }
          },
          itemBuilder: (context) => const [
            PopupMenuItem(
              value: 'editar',
              child: Row(
                children: [
                  Icon(Icons.edit, color: AppColors.secondary, size: 20),
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Servicios y Precios'),
        // Sin backgroundColor propio: hereda el AppBarTheme global.
      ),
      backgroundColor: AppColors.background,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _abrirFormulario(),
        backgroundColor: AppColors.accent,
        foregroundColor: AppColors.primary,
        icon: const Icon(Icons.add),
        label: const Text('Nuevo Servicio'),
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator(color: AppColors.secondary))
          : _servicios.isEmpty
              ? Center(
                  child: Text('No hay servicios registrados.', style: AppTextStyles.body),
                )
              : RefreshIndicator(
                  color: AppColors.secondary,
                  onRefresh: _cargarServicios,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16.0),
                    itemCount: _servicios.length,
                    itemBuilder: (context, index) => _tarjetaServicio(_servicios[index]),
                  ),
                ),
    );
  }
}