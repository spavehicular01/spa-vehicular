import 'package:flutter/material.dart';
import 'enlace_politica_privacidad.dart';

/// Casilla "Acepto la Política de Privacidad".
/// Las palabras "Política de Privacidad" son un enlace que abre la página en el navegador.
///
/// Uso:
///   bool _aceptaPolitica = false;
///   AceptarPoliticaPrivacidad(
///     aceptada: _aceptaPolitica,
///     onChanged: (v) => setState(() => _aceptaPolitica = v),
///   )
class AceptarPoliticaPrivacidad extends StatelessWidget {
  final bool aceptada;
  final ValueChanged<bool> onChanged;

  const AceptarPoliticaPrivacidad({
    super.key,
    required this.aceptada,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colorEnlace = Theme.of(context).colorScheme.primary;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Checkbox(
          value: aceptada,
          onChanged: (v) => onChanged(v ?? false),
        ),
        Expanded(
          child: Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              GestureDetector(
                onTap: () => onChanged(!aceptada),
                child: const Text('Acepto la '),
              ),
              GestureDetector(
                onTap: () => abrirPoliticaPrivacidad(context),
                child: Text(
                  'Política de Privacidad',
                  style: TextStyle(
                    color: colorEnlace,
                    decoration: TextDecoration.underline,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}