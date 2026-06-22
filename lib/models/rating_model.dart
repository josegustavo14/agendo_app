class RatingModel {
  final int id;
  final int score;
  final String? comment;
  final int clientId;
  final String clientName;
  final int professionalId;
  final String professionalName;
  final DateTime createdAt;

  RatingModel({
    required this.id,
    required this.score,
    this.comment,
    required this.clientId,
    required this.clientName,
    required this.professionalId,
    required this.professionalName,
    required this.createdAt,
  });

  factory RatingModel.fromJson(Map<String, dynamic> json) {
    return RatingModel(
      id: json['id'] as int,
      score: json['score'] as int,
      comment: json['comment'] as String?,
      clientId: json['clientId'] as int,
      clientName: json['clientName'] as String,
      professionalId: json['professionalId'] as int,
      professionalName: json['professionalName'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}
