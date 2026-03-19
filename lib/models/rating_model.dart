class RatingModel {
  final int id;
  final int score;
  final String? comment;
  final String clientName;
  final DateTime createdAt;

  RatingModel({
    required this.id,
    required this.score,
    this.comment,
    required this.clientName,
    required this.createdAt,
  });

  factory RatingModel.fromJson(Map<String, dynamic> json) {
    return RatingModel(
      id: json['id'] as int,
      score: json['score'] as int,
      comment: json['comment'] as String?,
      clientName: json['clientName'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}
