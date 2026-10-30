import 'package:flutter/material.dart';

/// Reglas de contraseña de la app. Si algún día cambian, se editan SOLO aquí.
/// Guardar en: lib/utils/password_validator.dart
class PasswordRule {
  final String texto;
  final bool Function(String) cumple;
  const PasswordRule(this.texto, this.cumple);
}

class PasswordValidator {
  static const int minLength = 8;

  static final List<PasswordRule> reglas = [
    PasswordRule('Mínimo $minLength caracteres', (p) => p.length >= minLength),
    PasswordRule('Una letra mayúscula', (p) => RegExp(r'[A-Z]').hasMatch(p)),
    PasswordRule('Un número', (p) => RegExp(r'[0-9]').hasMatch(p)),
    PasswordRule(
      'Un caracter especial (!@#\$%&*...)',
      (p) => RegExp(r'[^A-Za-z0-9\s]').hasMatch(p),
    ),
  ];

  /// Devuelve null si la contraseña es válida, o el mensaje de error.
  static String? validar(String? password) {
    final p = password ?? '';
    if (p.isEmpty) return 'Ingresa una contraseña';
    if (p.length < minLength) return 'Mínimo $minLength caracteres';
    if (!RegExp(r'[A-Z]').hasMatch(p)) return 'Debe incluir al menos una mayúscula';
    if (!RegExp(r'[0-9]').hasMatch(p)) return 'Debe incluir al menos un número';
    if (!RegExp(r'[^A-Za-z0-9\s]').hasMatch(p)) {
      return 'Debe incluir al menos un caracter especial';
    }
    return null;
  }
}

/// Lista de requisitos que se marca en verde mientras el usuario escribe.
/// Uso: PasswordChecklist(password: _passwordController.text)
class PasswordChecklist extends StatelessWidget {
  final String password;
  const PasswordChecklist({super.key, required this.password});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, left: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: PasswordValidator.reglas.map((regla) {
          final ok = regla.cumple(password);
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
              children: [
                Icon(
                  ok ? Icons.check_circle : Icons.radio_button_unchecked,
                  size: 16,
                  color: ok ? Colors.green : Colors.grey,
                ),
                const SizedBox(width: 8),
                Text(
                  regla.texto,
                  style: TextStyle(
                    fontSize: 12,
                    color: ok ? Colors.green : Colors.grey,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}