class Appointment {
  final String id;
  final String serviceName;
  final DateTime dateTime;
  final int durationMinutes;

  Appointment({
    required this.id,
    required this.serviceName,
    required this.dateTime,
    required this.durationMinutes,
  });
}