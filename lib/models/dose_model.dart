class DoseModel {
  final String id;
  final String label;
  final String? dosage;
  final String scheduledTime;
  final String days;
  final String? instructions;
  final bool active;

  DoseModel({
    required this.id,
    required this.label,
    this.dosage,
    required this.scheduledTime,
    required this.days,
    this.instructions,
    required this.active,
  });

  factory DoseModel.fromMap(Map<String, dynamic> map) {
    return DoseModel(
      id: map['id'],
      label: map['label'] ?? '',
      dosage: map['dosage'],
      scheduledTime: map['scheduled_time']?.toString() ?? '',
      days: map['days'] ?? '',
      instructions: map['instructions'],
      active: map['active'] ?? true,
    );
  }
}