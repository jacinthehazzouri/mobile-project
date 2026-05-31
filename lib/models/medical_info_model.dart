class MedicalInfoModel {
  final int? age;
  final String? bloodType;
  final String? allergies;
  final String? conditions;
  final String? emergencyName;
  final String? emergencyPhone;
  final String? notes;

  MedicalInfoModel({
    this.age,
    this.bloodType,
    this.allergies,
    this.conditions,
    this.emergencyName,
    this.emergencyPhone,
    this.notes,
  });

  factory MedicalInfoModel.fromMap(Map<String, dynamic> map) {
    return MedicalInfoModel(
      age: map['age'],
      bloodType: map['blood_type'],
      allergies: map['allergies'],
      conditions: map['conditions'],
      emergencyName: map['emergency_name'],
      emergencyPhone: map['emergency_phone'],
      notes: map['notes'],
    );
  }
}