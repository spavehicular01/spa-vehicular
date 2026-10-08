import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../extras/ui_extras.dart';

/// Título de cada sección del Inicio.
class SeccionTitulo extends StatelessWidget {
  final String texto;

  const SeccionTitulo(this.texto, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 10),
      child: Text(
        texto,
        style: AppTextStyles.h2.copyWith(color: textoFuerte(context)),
      ),
    );
  }
}
