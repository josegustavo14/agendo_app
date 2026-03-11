class ProfessionModel {
  final int id;
  final String name;

  ProfessionModel({required this.id, required this.name});

  factory ProfessionModel.fromJson(Map<String, dynamic> json) {
    return ProfessionModel(
      id: json['id'] as int,
      name: json['name'] as String,
    );
  }
}
