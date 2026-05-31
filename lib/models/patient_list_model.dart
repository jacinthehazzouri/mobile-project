class PatientListModel {
  final String id;
  final String name;
  final String? phone;

  PatientListModel({
    required this.id,
    required this.name,
    this.phone,
  });

  factory PatientListModel.fromMap(Map<String, dynamic> map) {
    return PatientListModel(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      phone: map['phone'],
    );
  }
}