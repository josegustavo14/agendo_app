class ServiceTypeModel {
  final int id;
  final String name;
  final String? description;
  final double? price;

  ServiceTypeModel({
    required this.id,
    required this.name,
    this.description,
    this.price,
  });

  factory ServiceTypeModel.fromJson(Map<String, dynamic> json) {
    return ServiceTypeModel(
      id: json['id'] as int,
      name: json['name'] as String,
      description: json['description'] as String?,
      price: (json['price'] as num?)?.toDouble(),
    );
  }

  String get formattedPrice {
    if (price == null) return '';
    return 'R\$ ${price!.toStringAsFixed(2).replaceAll('.', ',')}';
  }
}
