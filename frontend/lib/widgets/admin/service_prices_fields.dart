import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../models/service_model.dart';
import '../../../models/vehicle_types.dart';
import '../../../theme/app_theme.dart';

/// Crea un controlador por cada tipo de vehículo, con el precio actual del
/// servicio (si se está editando) o vacío.
Map<String, TextEditingController> crearControladoresPrecios(ServiceModel? servicio) {
  return {
    for (final t in tiposVehiculo)
      t.valor: TextEditingController(
        text: () {
          final precio = servicio?.precioPara(t.valor);
          return precio == null ? '' : precio.round().toString();
        }(),
      ),
  };
}

/// Lee solo los campos rellenados (mayores a cero).
List<PrecioVehiculo> leerPrecios(Map<String, TextEditingController> controladores) {
  final lista = <PrecioVehiculo>[];
  for (final t in tiposVehiculo) {
    final valor = double.tryParse(controladores[t.valor]?.text.trim() ?? '');
    if (valor != null && valor > 0) {
      lista.add(PrecioVehiculo(tipoVehiculo: t.valor, precio: valor));
    }
  }
  return lista;
}

/// Un campo de precio por cada tipo de vehículo; el admin llena solo los que apliquen.
class ServicePricesFields extends StatelessWidget {
  final Map<String, TextEditingController> controladores;
  final bool enabled;

  const ServicePricesFields({
    super.key,
    required this.controladores,
    required this.enabled,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Precios por tipo de vehículo', style: AppTextStyles.bodyStrong),
        const SizedBox(height: 4),
        const Text(
          'Llena solo los tipos a los que aplica este servicio.',
          style: AppTextStyles.body,
        ),
        const SizedBox(height: 8),
        for (final t in tiposVehiculo)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: TextField(
              controller: controladores[t.valor],
              enabled: enabled,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(
                labelText: t.etiqueta,
                prefixText: '\$ ',
                prefixIcon: Icon(t.icono, color: AppColors.secondary),
              ),
            ),
          ),
      ],
    );
  }
}
