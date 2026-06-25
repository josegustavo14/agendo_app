class ProfessionalModel {
  final int id;
  final String name;
  final String? phone;
  final String professionName;
  final String? bio;
  final double hourlyRate;
  final double ratingAverage;
  final bool isAvailable;

  ProfessionalModel({
    required this.id,
    required this.name,
    this.phone,
    required this.professionName,
    this.bio,
    required this.hourlyRate,
    required this.ratingAverage,
    required this.isAvailable,
  });

  factory ProfessionalModel.fromJson(Map<String, dynamic> json) {
    return ProfessionalModel(
      id: json['id'] as int,
      name: json['name'] as String,
      phone: json['phone'] as String?,
      professionName: json['professionName'] as String,
      bio: json['bio'] as String?,
      hourlyRate: (json['hourlyRate'] as num?)?.toDouble() ?? 0.0,
      ratingAverage: (json['ratingAverage'] as num?)?.toDouble() ?? 0.0,
      isAvailable: json['isAvailable'] as bool,
    );
  }
}
