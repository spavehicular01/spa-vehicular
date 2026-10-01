/// Horarios del spa y festivos de Colombia.
///
/// Atención:
///  • Lunes a sábado: 6:30 AM - 6:00 PM
///  • Domingos y festivos: 7:30 AM - 12:00 PM
class HorariosSpa {
  HorariosSpa._();

  /// Horas para agendar de lunes a sábado (no festivos), sin hora de almuerzo.
  /// El spa abre a las 6:30 AM y cierra a las 6:00 PM, así que la última
  /// hora para iniciar un servicio es la de las 5:00 PM.
  static const List<String> horasEntreSemana = [
    '07:00 AM',
    '08:00 AM',
    '09:00 AM',
    '10:00 AM',
    '11:00 AM',
    '12:00 PM',
    '01:00 PM',
    '02:00 PM',
    '03:00 PM',
    '04:00 PM',
    '05:00 PM',
  ];

  /// Horas para agendar los domingos y festivos. El spa abre a las 7:30 AM y
  /// cierra a las 12:00 PM, así que la última hora para iniciar es la de las 11:00 AM.
  static const List<String> horasDomingoFestivo = [
    '07:30 AM',
    '08:00 AM',
    '09:00 AM',
    '10:00 AM',
    '11:00 AM',
  ];

  /// Horas que se pueden agendar en [fecha].
  static List<String> horasDelDia(DateTime fecha) =>
      esDomingoOFestivo(fecha) ? horasDomingoFestivo : horasEntreSemana;

  static bool esDomingoOFestivo(DateTime fecha) =>
      fecha.weekday == DateTime.sunday || esFestivo(fecha);

  // ───────────── Festivos de Colombia ─────────────
  // Se calculan según la ley (Ley Emiliani + fechas de Semana Santa), así
  // no hay que actualizar una lista cada año.
  static final Map<int, Set<DateTime>> _cache = {};

  static bool esFestivo(DateTime fecha) {
    final dia = DateTime(fecha.year, fecha.month, fecha.day);
    return _festivosDelAnio(dia.year).contains(dia);
  }

  static Set<DateTime> _festivosDelAnio(int anio) {
    return _cache.putIfAbsent(anio, () {
      final pascua = _domingoDePascua(anio);
      DateTime d(int m, int dia) => DateTime(anio, m, dia);

      return {
        // Fijos
        d(1, 1), // Año Nuevo
        d(5, 1), // Día del Trabajo
        d(7, 20), // Independencia
        d(8, 7), // Batalla de Boyacá
        d(12, 8), // Inmaculada Concepción
        d(12, 25), // Navidad

        // Se trasladan al lunes siguiente (Ley Emiliani)
        _aLunes(d(1, 6)), // Reyes Magos
        _aLunes(d(3, 19)), // San José
        _aLunes(d(6, 29)), // San Pedro y San Pablo
        _aLunes(d(8, 15)), // Asunción de la Virgen
        _aLunes(d(10, 12)), // Día de la Raza
        _aLunes(d(11, 1)), // Todos los Santos
        _aLunes(d(11, 11)), // Independencia de Cartagena

        // Según la Semana Santa
        pascua.subtract(const Duration(days: 3)), // Jueves Santo
        pascua.subtract(const Duration(days: 2)), // Viernes Santo
        pascua.add(const Duration(days: 43)), // Ascensión (lunes)
        pascua.add(const Duration(days: 64)), // Corpus Christi (lunes)
        pascua.add(const Duration(days: 71)), // Sagrado Corazón (lunes)
      };
    });
  }

  /// Si la fecha ya es lunes se queda igual; si no, pasa al lunes siguiente.
  static DateTime _aLunes(DateTime fecha) =>
      fecha.add(Duration(days: (8 - fecha.weekday) % 7));

  /// Domingo de Pascua (algoritmo gregoriano).
  static DateTime _domingoDePascua(int anio) {
    final a = anio % 19;
    final b = anio ~/ 100;
    final c = anio % 100;
    final d = b ~/ 4;
    final e = b % 4;
    final f = (b + 8) ~/ 25;
    final g = (b - f + 1) ~/ 3;
    final h = (19 * a + b - d - g + 15) % 30;
    final i = c ~/ 4;
    final k = c % 4;
    final l = (32 + 2 * e + 2 * i - h - k) % 7;
    final m = (a + 11 * h + 22 * l) ~/ 451;
    final mes = (h + l - 7 * m + 114) ~/ 31;
    final dia = ((h + l - 7 * m + 114) % 31) + 1;
    return DateTime(anio, mes, dia);
  }
}