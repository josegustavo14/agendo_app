class DayScheduleModel {
  final String dayOfWeek;
  final String startTime;
  final String endTime;
  final int slotDurationMinutes;

  const DayScheduleModel({
    required this.dayOfWeek,
    required this.startTime,
    required this.endTime,
    required this.slotDurationMinutes,
  });

  factory DayScheduleModel.fromJson(Map<String, dynamic> json) {
    return DayScheduleModel(
      dayOfWeek: json['dayOfWeek'] as String,
      startTime: json['startTime'] as String,
      endTime: json['endTime'] as String,
      slotDurationMinutes: json['slotDurationMinutes'] as int,
    );
  }

  Map<String, dynamic> toJson() => {
        'dayOfWeek': dayOfWeek,
        'startTime': startTime,
        'endTime': endTime,
        'slotDurationMinutes': slotDurationMinutes,
      };

  static const List<String> orderedDays = [
    'MONDAY', 'TUESDAY', 'WEDNESDAY', 'THURSDAY', 'FRIDAY', 'SATURDAY', 'SUNDAY',
  ];

  static const Map<String, String> dayLabels = {
    'MONDAY': 'Segunda',
    'TUESDAY': 'Terça',
    'WEDNESDAY': 'Quarta',
    'THURSDAY': 'Quinta',
    'FRIDAY': 'Sexta',
    'SATURDAY': 'Sábado',
    'SUNDAY': 'Domingo',
  };

  String get label => dayLabels[dayOfWeek] ?? dayOfWeek;
}
