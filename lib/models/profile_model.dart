class ProfileModel {
  final String id;
  final String name;
  final String role;
  final String? phone;

  ProfileModel({
    required this.id,
    required this.name,
    required this.role,
    this.phone,
  });

  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    return ProfileModel(
      id: json['id'],
      name: json['name'],
      role: json['role'],
      phone: json['phone'],
    );
  }
}