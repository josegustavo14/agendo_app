class AppointmentModel {
  final int id;
  final String professionalName;
  final String clientName;
  final List<String> services;
  final double totalAmount;
  final DateTime scheduleDate;
  final DateTime requestDate;
  final String status;

  AppointmentModel({
    required this.id,
    required this.professionalName,
    required this.clientName,
    required this.services,
    required this.totalAmount,
    required this.scheduleDate,
    required this.requestDate,
    required this.status,
  });

  factory AppointmentModel.fromJson(Map<String, dynamic> json) {
    return AppointmentModel(
      id: json['id'] as int,
      professionalName: json['professional']['name'] as String,
      clientName: json['client']['name'] as String,
      services: (json['services'] as List<dynamic>)
          .map((s) => s['name'] as String)
          .toList(),
      totalAmount: (json['totalAmount'] as num).toDouble(),
      scheduleDate: DateTime.parse(json['scheduleDate'] as String),
      requestDate: DateTime.parse(json['requestDate'] as String),
      status: json['status'] as String,
    );
  }

  String get formattedValue {
    return 'R\$ ${totalAmount.toStringAsFixed(2).replaceAll('.', ',')}';
  }
}
