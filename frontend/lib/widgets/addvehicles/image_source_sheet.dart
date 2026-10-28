import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../theme/app_theme.dart';

/// Bottom sheet para elegir entre Galería y Cámara.
Future<void> mostrarOpcionesImagen(
  BuildContext context, {
  required ValueChanged<ImageSource> onSelected,
}) {
  return showModalBottomSheet(
    context: context,
    backgroundColor: context.surfaceColor,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (sheetContext) => SafeArea(
      child: Wrap(
        children: [
          _opcion(sheetContext, Icons.photo_library, 'Galería',
              ImageSource.gallery, onSelected),
          _opcion(sheetContext, Icons.photo_camera, 'Cámara',
              ImageSource.camera, onSelected),
        ],
      ),
    ),
  );
}

Widget _opcion(
  BuildContext context,
  IconData icono,
  String titulo,
  ImageSource source,
  ValueChanged<ImageSource> onSelected,
) {
  return ListTile(
    leading: Icon(icono, color: AppColors.secondary),
    title: Text(titulo),
    onTap: () {
      Navigator.of(context).pop();
      onSelected(source);
    },
  );
}