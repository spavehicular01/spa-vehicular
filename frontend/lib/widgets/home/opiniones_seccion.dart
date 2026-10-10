import 'package:flutter/material.dart';
import '../../services/review_service.dart';
import 'opinion_card.dart';
import 'opinion_form_sheet.dart';

/// Sección "Opiniones de clientes": lista las opiniones reales y deja
/// escribir la propia. [conSesion] ejecuta la acción solo si hay sesión
/// (si no, la pantalla de inicio muestra el diálogo de iniciar sesión).
class OpinionesSeccion extends StatefulWidget {
  final void Function(VoidCallback accion) conSesion;

  const OpinionesSeccion({super.key, required this.conSesion});

  @override
  State<OpinionesSeccion> createState() => _OpinionesSeccionState();
}

class _OpinionesSeccionState extends State<OpinionesSeccion> {
  ResumenOpiniones _resumen = const ResumenOpiniones();
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    final resumen = await ReviewService.obtenerOpiniones();
    if (!mounted) return;
    setState(() {
      _resumen = resumen;
      _cargando = false;
    });
  }

  Future<void> _abrirFormulario() async {
    final guardada = await mostrarFormularioOpinion(context);
    if (guardada == true) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gracias por tu opinión')),
      );
      _cargar();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_resumen.total > 0)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                const Icon(Icons.star_rounded, color: Color(0xFFFFB400), size: 20),
                const SizedBox(width: 4),
                Text(
                  '${_resumen.promedio}',
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                ),
                const SizedBox(width: 6),
                Text('(${_resumen.total} opiniones)',
                    style: const TextStyle(color: Colors.black54, fontSize: 13)),
              ],
            ),
          ),
        if (_cargando)
          const SizedBox(
              height: 140, child: Center(child: CircularProgressIndicator()))
        else if (_resumen.opiniones.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Text(
              'Aún no hay opiniones. ¡Sé el primero en opinar!',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.black54),
            ),
          )
        else
          SizedBox(
            height: 150,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _resumen.opiniones.length,
              itemBuilder: (_, i) => OpinionCard(opinion: _resumen.opiniones[i]),
            ),
          ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: () => widget.conSesion(_abrirFormulario),
          icon: const Icon(Icons.rate_review_outlined),
          label: const Text('Dejar mi opinión'),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ],
    );
  }
}