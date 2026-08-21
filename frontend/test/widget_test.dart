import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/main.dart';

void main() {
  testWidgets('Verifica la carga inicial de Spa Vehicular', (WidgetTester tester) async {
    // 1. Renderiza la aplicación principal usando su nombre real
    await tester.pumpWidget(const SpaVehicularApp());

    // 2. Procesa un frame inicial
    await tester.pump();

    // 3. Confirma que el widget de la app fue encontrado exitosamente
    expect(find.byType(SpaVehicularApp), findsOneWidget);
  });
}