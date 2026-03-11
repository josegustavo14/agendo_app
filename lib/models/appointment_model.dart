class AppointmentModel {
  final int id;
  final String professionalName;
  final String clientName;
  final String serviceType;
  final int value;
  final DateTime scheduleDate;
  final DateTime requestDate;

  AppointmentModel({
    required this.id,
    required this.professionalName,
    required this.clientName,
    required this.serviceType,
    required this.value,
    required this.scheduleDate,
    required this.requestDate,
  });

  factory AppointmentModel.fromJson(Map<String, dynamic> json) {
    return AppointmentModel(
      id: json['id'] as int,
      professionalName: json['professional']['name'] as String,
      clientName: json['client']['name'] as String,
      serviceType: json['serviceType']['name'] as String,
      value: json['valueInCents'] as int,
      scheduleDate: DateTime.parse(json['scheduleDate'] as String),
      requestDate: DateTime.parse(json['requestDate'] as String),
    );
  }

  String get formattedValue {
    return 'R\$ ${(value / 100).toStringAsFixed(2).replaceAll('.', ',')}';
  }
}
