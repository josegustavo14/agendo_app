class ProfessionalProfile {
  final int? professionId;
  final String? professionName;
  final String? bio;
  final bool? isAvailable;

  ProfessionalProfile({this.professionId, this.professionName, this.bio, this.isAvailable});

  factory ProfessionalProfile.fromJson(Map<String, dynamic> json) {
    return ProfessionalProfile(
      professionId: json['professionId'] as int?,
      professionName: json['professionName'] as String?,
      bio: json['bio'] as String?,
      isAvailable: json['isAvailable'] as bool?,
    );
  }
}

class ClientProfile {
  final String? taxId;
  final String? preferredPaymentMethod;

  ClientProfile({this.taxId, this.preferredPaymentMethod});

  factory ClientProfile.fromJson(Map<String, dynamic> json) {
    return ClientProfile(
      taxId: json['taxId'] as String?,
      preferredPaymentMethod: json['preferredPaymentMethod'] as String?,
    );
  }
}

class UserModel {
  final int id;
  final String name;
  final String email;
  final String? phone;
  final String? role;
  final String? token;
  final ProfessionalProfile? professionalProfile;
  final ClientProfile? clientProfile;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    this.role,
    this.token,
    this.professionalProfile,
    this.clientProfile,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as int,
      name: json['name'] as String,
      email: json['email'] as String,
      phone: json['phone'] as String?,
      role: json['role'] as String?,
      token: json['token'] as String?,
      professionalProfile: json['professionalProfile'] != null
          ? ProfessionalProfile.fromJson(json['professionalProfile'])
          : null,
      clientProfile: json['clientProfile'] != null
          ? ClientProfile.fromJson(json['clientProfile'])
          : null,
    );
  }
}
