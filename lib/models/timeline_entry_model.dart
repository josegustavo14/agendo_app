class TimelineEntryModel {
  final String? previousStatus;
  final String newStatus;
  final int changedById;
  final String changedByName;
  final DateTime changedAt;

  TimelineEntryModel({
    this.previousStatus,
    required this.newStatus,
    required this.changedById,
    required this.changedByName,
    required this.changedAt,
  });

  factory TimelineEntryModel.fromJson(Map<String, dynamic> json) {
    return TimelineEntryModel(
      previousStatus: json['previousStatus'] as String?,
      newStatus: json['newStatus'] as String,
      changedById: json['changedBy']['id'] as int,
      changedByName: json['changedBy']['name'] as String,
      changedAt: DateTime.parse(json['changedAt'] as String),
    );
  }

  bool get isCreation => previousStatus == null;
}
