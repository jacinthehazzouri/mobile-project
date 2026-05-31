class DoseEventModel {
  final String id;
  final String status;
  final String createdAt;
  final String medicineName;

  DoseEventModel({
    required this.id,
    required this.status,
    required this.createdAt,
    required this.medicineName,
  });

  factory DoseEventModel.fromMap(Map<String, dynamic> map) {
    return DoseEventModel(
      id: map['id'],
      status: map['status'] ?? 'unknown',
      createdAt: map['created_at'] ?? '',
      medicineName: map['dose']?['label'] ?? 'Unknown',
    );
  }
}