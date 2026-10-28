/// Formatea un valor en pesos con separador de miles: 25000 -> $25.000
String formatearPesos(num valor) {
  final s = valor.round().toString();
  final buf = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) buf.write('.');
    buf.write(s[i]);
  }
  return '\$$buf';
}
