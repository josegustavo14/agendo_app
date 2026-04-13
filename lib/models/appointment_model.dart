class AppointmentModel {
  final int id;
  final int professionalId;
  final String professionalName;
  final int clientId;
  final String clientName;
  final List<String> services;
  final double totalAmount;
  final DateTime scheduleDate;
  final DateTime requestDate;
  final String status;

  AppointmentModel({
    required this.id,
    required this.professionalId,
    required this.professionalName,
    required this.clientId,
    required this.clientName,
    required this.services,
    required this.totalAmount,
    required this.scheduleDate,
    required this.requestDate,
    required this.status,
  });

  factory AppointmentModel.fromJson(Map<String, dynamic> json) {
    final servicesList = (json['services'] as List<dynamic>)
        .map((s) => s['name'] as String)
        .toList();

    return AppointmentModel(
      id: json['id'] as int,
      professionalId: json['professional']['id'] as int,
      professionalName: json['professional']['name'] as String,
      clientId: json['client']['id'] as int,
      clientName: json['client']['name'] as String,
      services: servicesList,
      totalAmount: (json['totalAmount'] as num).toDouble(),
      scheduleDate: DateTime.parse(json['scheduleDate'] as String),
      requestDate: DateTime.parse(json['requestDate'] as String),
      status: json['status'] as String,
    );
  }

  bool get isPending => status == 'PENDING';
  bool get isApproved => status == 'APPROVED';
  bool get isCompleted => status == 'COMPLETED';
  bool get isCancelled => status == 'CANCELLED';
  bool get isRejected => status == 'REJECTED';

  String get formattedValue =>
      'R\$ ${totalAmount.toStringAsFixed(2).replaceAll('.', ',')}';

  String get servicesLabel => services.join(' • ');
}
