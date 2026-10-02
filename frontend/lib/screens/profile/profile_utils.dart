/// Separa un nombre completo en [nombres, apellidos] solo para rellenar el
/// formulario de edición; el usuario puede corregirlo antes de guardar.
List<String> separarNombre(String completo) {
  final partes = completo
      .trim()
      .split(RegExp(r'\s+'))
      .where((p) => p.isNotEmpty)
      .toList();
  if (partes.isEmpty) return ['', ''];
  if (partes.length == 1) return [partes[0], ''];
  if (partes.length == 2) return [partes[0], partes[1]];
  if (partes.length == 3) return [partes[0], partes.sublist(1).join(' ')];
  return [partes.sublist(0, 2).join(' '), partes.sublist(2).join(' ')];
}

/// Deja solo los 10 dígitos del celular (sin espacios ni indicativo +57).
String celularDiezDigitos(String celular) {
  final digitos = celular.replaceAll(RegExp(r'\D'), '');
  return digitos.length > 10 ? digitos.substring(digitos.length - 10) : digitos;
}