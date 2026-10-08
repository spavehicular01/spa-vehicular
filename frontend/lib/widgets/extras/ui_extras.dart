import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
// ─────────────────────────────────────────────────────────────
// Helpers de color que respetan el modo oscuro.
// Úsalos en lugar de AppTextStyles.* directo cuando el texto
// vaya sobre tarjetas o fondos que cambian con el tema.
// ─────────────────────────────────────────────────────────────
bool esOscuro(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark;

Color textoFuerte(BuildContext context) =>
    esOscuro(context) ? Colors.white : AppColors.primary;

Color textoSuave(BuildContext context) =>
    esOscuro(context) ? Colors.white70 : const Color(0xFF4A5568);

Color colorAcento(BuildContext context) =>
    esOscuro(context) ? AppColors.accent : AppColors.secondary;

// ─────────────────────────────────────────────────────────────
// Pressable: efecto de escala al tocar (respuesta a la acción).
// ─────────────────────────────────────────────────────────────
class Pressable extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;

  const Pressable({super.key, required this.child, this.onTap});

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  bool _presionado = false;

  void _set(bool valor) {
    if (_presionado != valor) setState(() => _presionado = valor);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => _set(true),
      onTapUp: (_) => _set(false),
      onTapCancel: () => _set(false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _presionado ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 110),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// SkeletonBox: bloque gris con brillo animado (shimmer) para
// mostrar mientras cargan los datos. Sin paquetes externos.
// ─────────────────────────────────────────────────────────────
class SkeletonBox extends StatefulWidget {
  final double? width;
  final double height;
  final double radius;

  const SkeletonBox({
    super.key,
    this.width,
    required this.height,
    this.radius = 8,
  });

  @override
  State<SkeletonBox> createState() => _SkeletonBoxState();
}

class _SkeletonBoxState extends State<SkeletonBox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1300),
  )..repeat();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Respeta "reducir animaciones" del sistema.
    if (MediaQuery.of(context).disableAnimations) {
      _controller.stop();
    } else if (!_controller.isAnimating) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final oscuro = esOscuro(context);
    final base =
        oscuro ? Colors.white.withValues(alpha: 0.06) : Colors.grey.shade200;
    final brillo =
        oscuro ? Colors.white.withValues(alpha: 0.14) : Colors.grey.shade100;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final t = _controller.value;
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.radius),
            gradient: LinearGradient(
              begin: Alignment(-2 + 4 * t, 0),
              end: Alignment(-1 + 4 * t, 0),
              colors: [base, brillo, base],
              stops: const [0.0, 0.5, 1.0],
            ),
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────
// EmptyState: ilustración + mensaje + botón de acción opcional.
// ─────────────────────────────────────────────────────────────
class EmptyState extends StatelessWidget {
  final IconData icono;
  final String titulo;
  final String mensaje;
  final String? textoBoton;
  final VoidCallback? onPressed;

  const EmptyState({
    super.key,
    required this.icono,
    required this.titulo,
    required this.mensaje,
    this.textoBoton,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _Ilustracion(icono: icono),
            const SizedBox(height: 22),
            Text(
              titulo,
              textAlign: TextAlign.center,
              style: AppTextStyles.h2.copyWith(color: textoFuerte(context)),
            ),
            const SizedBox(height: 8),
            Text(
              mensaje,
              textAlign: TextAlign.center,
              style: AppTextStyles.body.copyWith(color: textoSuave(context)),
            ),
            if (textoBoton != null && onPressed != null) ...[
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: onPressed,
                style: ElevatedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                ),
                child: Text(textoBoton!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Círculos concéntricos (como ondas de agua) con el icono al centro.
class _Ilustracion extends StatelessWidget {
  final IconData icono;
  const _Ilustracion({required this.icono});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 132,
      height: 132,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 132,
            height: 132,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.accent.withValues(alpha: 0.08),
            ),
          ),
          Container(
            width: 98,
            height: 98,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.accent.withValues(alpha: 0.16),
            ),
          ),
          Container(
            width: 66,
            height: 66,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.accent,
            ),
            child: Icon(icono, color: AppColors.primary, size: 32),
          ),
          Positioned(
            top: 10,
            right: 18,
            child: _gota(12, 0.35),
          ),
          Positioned(
            bottom: 14,
            left: 12,
            child: _gota(8, 0.30),
          ),
        ],
      ),
    );
  }

  Widget _gota(double d, double alpha) => Container(
        width: d,
        height: d,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.secondary.withValues(alpha: alpha),
        ),
      );
}
