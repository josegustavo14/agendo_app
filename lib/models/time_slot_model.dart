class TimeSlotModel {
  final String time;
  final bool available;

  const TimeSlotModel({required this.time, required this.available});

  factory TimeSlotModel.fromJson(Map<String, dynamic> json) {
    return TimeSlotModel(
      time: json['time'] as String,
      available: json['available'] as bool,
    );
  }
}
