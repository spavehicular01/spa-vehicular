import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// Dirección pública de la política de privacidad (la misma que está en Play Console).
const String kUrlPoliticaPrivacidad =
    'https://spa-vehicular.onrender.com/politica-privacidad';

/// Abre la política de privacidad en el navegador del teléfono.
Future<void> abrirPoliticaPrivacidad(BuildContext context) async {
  var abierto = false;
  try {
    abierto = await launchUrl(
      Uri.parse(kUrlPoliticaPrivacidad),
      mode: LaunchMode.externalApplication,
    );
  } catch (_) {
    abierto = false;
  }

  if (!abierto && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('No se pudo abrir la política de privacidad')),
    );
  }
}

/// Enlace suelto "Política de Privacidad" (para pantallas donde no hace falta aceptarla).
class EnlacePoliticaPrivacidad extends StatelessWidget {
  const EnlacePoliticaPrivacidad({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: TextButton(
        onPressed: () => abrirPoliticaPrivacidad(context),
        child: const Text(
          'Política de Privacidad',
          style: TextStyle(decoration: TextDecoration.underline),
        ),
      ),
    );
  }
}