import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
class LoadingButton extends StatelessWidget {
  final String label;
  final bool loading;
  final VoidCallback onPressed;

  const LoadingButton({
    super.key,
    required this.label,
    required this.loading,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    // Toma el cian con texto navy del elevatedButtonTheme
    return ElevatedButton(
      onPressed: loading ? null : onPressed,
      child: loading
          ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                color: AppColors.primary,
                strokeWidth: 2,
              ),
            )
          : Text(label),
    );
  }
}