import 'package:flutter/material.dart';
import '../../services/review_service.dart';
import '../../theme/app_theme.dart';

/// Hoja inferior para dejar (o editar) la opinión.
/// Devuelve true si se guardó.
Future<bool?> mostrarFormularioOpinion(BuildContext context) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => const _OpinionFormSheet(),
  );
}

class _OpinionFormSheet extends StatefulWidget {
  const _OpinionFormSheet();

  @override
  State<_OpinionFormSheet> createState() => _OpinionFormSheetState();
}

class _OpinionFormSheetState extends State<_OpinionFormSheet> {
  final _comentarioCtrl = TextEditingController();
  int _calificacion = 0;
  bool _cargando = true;
  bool _guardando = false;
  bool _yaOpino = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _precargar();
  }

  @override
  void dispose() {
    _comentarioCtrl.dispose();
    super.dispose();
  }

  /// Si el usuario ya opinó, se muestra su opinión para editarla.
  Future<void> _precargar() async {
    final mia = await ReviewService.obtenerMiOpinion();
    if (!mounted) return;
    setState(() {
      if (mia != null) {
        _yaOpino = true;
        _calificacion = (mia['calificacion'] as num?)?.toInt() ?? 0;
        _comentarioCtrl.text = (mia['comentario'] ?? '').toString();
      }
      _cargando = false;
    });
  }

  Future<void> _guardar() async {
    if (_calificacion == 0) {
      setState(() => _error = 'Elige de 1 a 5 estrellas');
      return;
    }
    setState(() {
      _guardando = true;
      _error = null;
    });

    final error = await ReviewService.guardarOpinion(
      calificacion: _calificacion,
      comentario: _comentarioCtrl.text,
    );
    if (!mounted) return;

    if (error == null) {
      Navigator.pop(context, true);
    } else {
      setState(() {
        _guardando = false;
        _error = error;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
      child: _cargando
          ? const SizedBox(
              height: 160, child: Center(child: CircularProgressIndicator()))
          : Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  _yaOpino ? 'Editar mi opinión' : 'Cuéntanos tu experiencia',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (i) {
                    final activa = i < _calificacion;
                    return IconButton(
                      onPressed: () => setState(() => _calificacion = i + 1),
                      iconSize: 38,
                      icon: Icon(
                        activa ? Icons.star_rounded : Icons.star_outline_rounded,
                        color: const Color(0xFFFFB400),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _comentarioCtrl,
                  maxLength: 300,
                  maxLines: 4,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: InputDecoration(
                    hintText: 'Escribe tu comentario (opcional)',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(_error!,
                        style: const TextStyle(color: Colors.red, fontSize: 13)),
                  ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: _guardando ? null : _guardar,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _guardando
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : Text(_yaOpino ? 'Actualizar opinión' : 'Publicar opinión'),
                ),
              ],
            ),
    );
  }
}