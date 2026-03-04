class AppointmentModel {
  final int id;
  final String serviceType;
  final String user; 
  final int value; 
  final DateTime scheduleDate;
  final DateTime requestDate; 

  AppointmentModel({
    required this.id,
    required this.serviceType,
    required this.user,
    required this.value,
    required this.scheduleDate,
    required this.requestDate,
  });

  factory AppointmentModel.fromJson(Map<String, dynamic> json) {
    return AppointmentModel(
      id: json['id'] as int,
      serviceType: json['serviceType'] as String,
      user: json['user'] as String,
      value: json['value'] as int,
      // O Spring Boot geralmente envia datas em ISO8601 (Strings)
      scheduleDate: DateTime.parse(json['scheduleDate'] as String),
      requestDate: DateTime.parse(json['requestDate'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'serviceType': serviceType,
      'user': user,
      'value': value,
      'scheduleDate': scheduleDate.toIso8601String(),
      'requestDate': requestDate.toIso8601String(),
    };
  }

  String get formattedValue {
    return 'R\$ ${(value / 100).toStringAsFixed(2).replaceAll('.', ',')}';
  }
}