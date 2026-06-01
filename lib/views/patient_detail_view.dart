import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';

import '../controllers/patient_controller.dart';
import '../models/dose_event_model.dart';
import '../models/dose_model.dart';
import '../models/medical_info_model.dart';
import '../theme/app_theme.dart';
import 'package:url_launcher/url_launcher.dart';

class PatientDetailView extends StatefulWidget {
  final String patientId;
  final String patientName;

  const PatientDetailView({
    super.key,
    required this.patientId,
    required this.patientName,
  });

  @override
  State<PatientDetailView> createState() => _PatientDetailViewState();
}

class _PatientDetailViewState extends State<PatientDetailView>
    with SingleTickerProviderStateMixin {
  final PatientController patientController = PatientController();

  late TabController _tabController;

  List<DoseModel> doses = [];
  MedicalInfoModel? medicalInfo;
  List<DoseEventModel> events = [];

  bool dosesLoading = true;
  bool medicalLoading = true;
  bool historyLoading = true;

  final List<String> bloodTypes = const [
    'A+',
    'A-',
    'B+',
    'B-',
    'AB+',
    'AB-',
    'O+',
    'O-',
  ];

  @override
  void initState() {
    super.initState();

    _tabController = TabController(length: 3, vsync: this);

    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        if (_tabController.index == 0) {
          loadDoses();
        } else if (_tabController.index == 1) {
          loadMedicalInfo();
        } else {
          loadHistory();
        }
      }
    });

    loadDoses();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void showToast(String message) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      fontSize: 16,
    );
  }

  bool isValidLebanesePhone(String phone) {
    return RegExp(r'^(03|70|71|76|78|79|81)\d{6}$').hasMatch(phone);
  }

  Future<void> callEmergencyContact(String phone) async {
    final Uri uri = Uri(scheme: 'tel', path: phone.trim());

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      showToast('Could not open phone dialer');
    }
  }

  Future<void> loadDoses() async {
    setState(() => dosesLoading = true);

    try {
      final result = await patientController.getDoses(widget.patientId);

      if (!mounted) return;

      setState(() {
        doses = result;
        dosesLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => dosesLoading = false);
      showToast('Failed to load doses');
    }
  }

  Future<void> loadMedicalInfo() async {
    setState(() => medicalLoading = true);

    try {
      final result = await patientController.getMedicalInfo(widget.patientId);

      if (!mounted) return;

      setState(() {
        medicalInfo = result;
        medicalLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => medicalLoading = false);
      showToast('Failed to load medical info');
    }
  }

  Future<void> loadHistory() async {
    setState(() => historyLoading = true);

    try {
      final result = await patientController.getHistory(widget.patientId);

      if (!mounted) return;

      setState(() {
        events = result;
        historyLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => historyLoading = false);
      showToast('Failed to load history');
    }
  }

  void showDoseDialog({DoseModel? existing}) {
    final labelController = TextEditingController(text: existing?.label ?? '');
    final dosageController = TextEditingController(text: existing?.dosage ?? '');
    final instructionsController = TextEditingController(
      text: existing?.instructions ?? '',
    );

    TimeOfDay selectedTime = TimeOfDay.now();

    if (existing != null && existing.scheduledTime.isNotEmpty) {
      final parts = existing.scheduledTime.split(':');

      selectedTime = TimeOfDay(
        hour: int.parse(parts[0]),
        minute: int.parse(parts[1]),
      );
    }

    final List<String> allDays = [
      'Mon',
      'Tue',
      'Wed',
      'Thu',
      'Fri',
      'Sat',
      'Sun',
    ];

    final Set<String> selectedDays = existing != null
        ? Set<String>.from(existing.days.split(','))
        : {'Mon', 'Tue', 'Wed', 'Thu', 'Fri'};

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (bottomSheetContext) {
        return StatefulBuilder(
          builder: (context, setBottomSheetState) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(28),
                ),
              ),
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 24,
                bottom:
                MediaQuery.of(bottomSheetContext).viewInsets.bottom + 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Text(
                          existing == null ? 'Add Dose' : 'Edit Dose',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textDark,
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(bottomSheetContext),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: labelController,
                      decoration: const InputDecoration(
                        labelText: 'Medicine name',
                        hintText: 'e.g. Metformin',
                        prefixIcon: Icon(Icons.medication_outlined),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: dosageController,
                      decoration: const InputDecoration(
                        labelText: 'Dosage',
                        hintText: 'e.g. 500mg, 10ml',
                        prefixIcon: Icon(Icons.science_outlined),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: instructionsController,
                      decoration: const InputDecoration(
                        labelText: 'Instructions',
                        hintText: 'e.g. Take with food',
                        prefixIcon: Icon(Icons.notes_outlined),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Scheduled time',
                      style: TextStyle(
                        color: AppTheme.textLight,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 6),
                    GestureDetector(
                      onTap: () async {
                        final pickedTime = await showTimePicker(
                          context: bottomSheetContext,
                          initialTime: selectedTime,
                        );

                        if (pickedTime != null) {
                          setBottomSheetState(() {
                            selectedTime = pickedTime;
                          });
                        }
                      },
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: const Color(0xFFDDE5F0),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.access_time,
                              color: AppTheme.textLight,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              selectedTime.format(bottomSheetContext),
                              style: const TextStyle(
                                fontSize: 15,
                                color: AppTheme.textDark,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Days',
                      style: TextStyle(
                        color: AppTheme.textLight,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: allDays.map((day) {
                        final selected = selectedDays.contains(day);

                        return GestureDetector(
                          onTap: () {
                            setBottomSheetState(() {
                              if (selected) {
                                selectedDays.remove(day);
                              } else {
                                selectedDays.add(day);
                              }
                            });
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: selected
                                  ? AppTheme.primary
                                  : AppTheme.primary.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              day,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: selected
                                    ? Colors.white
                                    : AppTheme.primary,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 22),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: () async {
                          if (labelController.text.trim().isEmpty) {
                            showToast('Please enter medicine name');
                            return;
                          }

                          if (selectedDays.isEmpty) {
                            showToast('Please select at least one day');
                            return;
                          }

                          final time =
                              '${selectedTime.hour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')}';

                          final days = allDays
                              .where((day) => selectedDays.contains(day))
                              .join(',');

                          Navigator.pop(bottomSheetContext);

                          if (existing == null) {
                            await addDose(
                              label: labelController.text.trim(),
                              dosage: dosageController.text.trim(),
                              time: time,
                              days: days,
                              instructions:
                              instructionsController.text.trim(),
                            );
                          } else {
                            await updateDose(
                              doseId: existing.id,
                              label: labelController.text.trim(),
                              dosage: dosageController.text.trim(),
                              time: time,
                              days: days,
                              instructions:
                              instructionsController.text.trim(),
                            );
                          }
                        },
                        child: Text(
                          existing == null ? 'Add Dose' : 'Save Changes',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> addDose({
    required String label,
    required String dosage,
    required String time,
    required String days,
    required String instructions,
  }) async {
    try {
      await patientController.addDose(
        patientId: widget.patientId,
        label: label,
        dosage: dosage,
        time: time,
        days: days,
        instructions: instructions,
      );

      await loadDoses();
      showToast('Dose added successfully');
    } catch (e) {
      showToast('Failed to add dose');
    }
  }

  Future<void> updateDose({
    required String doseId,
    required String label,
    required String dosage,
    required String time,
    required String days,
    required String instructions,
  }) async {
    try {
      await patientController.updateDose(
        doseId: doseId,
        label: label,
        dosage: dosage,
        time: time,
        days: days,
        instructions: instructions,
      );

      await loadDoses();
      showToast('Dose updated');
    } catch (e) {
      showToast('Failed to update dose');
    }
  }

  Future<void> deleteDose(String doseId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text('Delete Dose'),
          content: const Text('Are you sure you want to delete this dose?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      try {
        await patientController.deleteDose(doseId);
        await loadDoses();
        showToast('Dose deleted');
      } catch (e) {
        showToast('Failed to delete dose');
      }
    }
  }

  void showMedicalDialog() {
    final ageController = TextEditingController(
      text: medicalInfo?.age?.toString() ?? '',
    );
    final allergiesController = TextEditingController(
      text: medicalInfo?.allergies ?? '',
    );
    final conditionsController = TextEditingController(
      text: medicalInfo?.conditions ?? '',
    );
    final emergencyNameController = TextEditingController(
      text: medicalInfo?.emergencyName ?? '',
    );
    final emergencyPhoneController = TextEditingController(
      text: medicalInfo?.emergencyPhone ?? '',
    );
    final notesController = TextEditingController(
      text: medicalInfo?.notes ?? '',
    );

    String? selectedBloodType =
    medicalInfo?.bloodType == null || medicalInfo!.bloodType!.isEmpty
        ? null
        : medicalInfo!.bloodType;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (bottomSheetContext) {
        return StatefulBuilder(
          builder: (context, setBottomSheetState) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(28),
                ),
              ),
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 24,
                bottom:
                MediaQuery.of(bottomSheetContext).viewInsets.bottom + 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        const Text(
                          'Medical Info',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textDark,
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(bottomSheetContext),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'This information is used for the patient medical profile.',
                      style: TextStyle(
                        color: AppTheme.textLight,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: ageController,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            decoration: const InputDecoration(
                              labelText: 'Age',
                              prefixIcon: Icon(Icons.cake_outlined),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: selectedBloodType,
                            isExpanded: true,
                            dropdownColor: Colors.white,
                            icon: const Icon(
                              Icons.keyboard_arrow_down_rounded,
                              color: AppTheme.primary,
                            ),
                            decoration: const InputDecoration(
                              labelText: 'Blood Type',
                              prefixIcon: Icon(Icons.bloodtype_outlined),
                            ),
                            style: const TextStyle(
                              color: AppTheme.textDark,
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                            ),
                            items: bloodTypes.map((type) {
                              return DropdownMenuItem<String>(
                                value: type,
                                child: Text(type),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setBottomSheetState(() {
                                selectedBloodType = value;
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: allergiesController,
                      decoration: const InputDecoration(
                        labelText: 'Allergies',
                        hintText: 'Comma separated',
                        prefixIcon: Icon(Icons.warning_amber_outlined),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: conditionsController,
                      decoration: const InputDecoration(
                        labelText: 'Medical conditions',
                        hintText: 'Comma separated',
                        prefixIcon: Icon(Icons.medical_information_outlined),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: emergencyNameController,
                      decoration: const InputDecoration(
                        labelText: 'Emergency contact name',
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: emergencyPhoneController,
                      keyboardType: TextInputType.number,
                      maxLength: 8,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                      decoration: const InputDecoration(
                        labelText: 'Emergency contact phone',
                        helperText: 'Example: 03123456 or 70123456',
                        prefixIcon: Icon(Icons.phone_outlined),
                        counterText: '',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: notesController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Notes',
                        prefixIcon: Icon(Icons.notes_outlined),
                      ),
                    ),
                    const SizedBox(height: 22),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: () async {
                          final emergencyPhone =
                          emergencyPhoneController.text.trim();

                          if (emergencyPhone.isNotEmpty &&
                              !isValidLebanesePhone(emergencyPhone)) {
                            showToast('Enter a valid Lebanese phone number');
                            return;
                          }

                          Navigator.pop(bottomSheetContext);

                          await saveMedicalInfo(
                            age: int.tryParse(ageController.text.trim()),
                            bloodType: selectedBloodType ?? '',
                            allergies: allergiesController.text.trim(),
                            conditions: conditionsController.text.trim(),
                            emergencyName:
                            emergencyNameController.text.trim(),
                            emergencyPhone: emergencyPhone,
                            notes: notesController.text.trim(),
                          );
                        },
                        child: const Text('Save Medical Info'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> saveMedicalInfo({
    int? age,
    required String bloodType,
    required String allergies,
    required String conditions,
    required String emergencyName,
    required String emergencyPhone,
    required String notes,
  }) async {
    try {
      await patientController.saveMedicalInfo(
        patientId: widget.patientId,
        age: age,
        bloodType: bloodType,
        allergies: allergies,
        conditions: conditions,
        emergencyName: emergencyName,
        emergencyPhone: emergencyPhone,
        notes: notes,
      );

      await loadMedicalInfo();
      showToast('Medical info saved');
    } catch (e) {
      showToast('Failed to save medical info');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text(widget.patientName),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppTheme.primary,
          unselectedLabelColor: AppTheme.textLight,
          indicatorColor: AppTheme.primary,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold),
          tabs: const [
            Tab(icon: Icon(Icons.medication_outlined), text: 'Doses'),
            Tab(
              icon: Icon(Icons.medical_information_outlined),
              text: 'Medical',
            ),
            Tab(icon: Icon(Icons.history), text: 'History'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          buildDosesTab(),
          buildMedicalTab(),
          buildHistoryTab(),
        ],
      ),
      floatingActionButton: AnimatedBuilder(
        animation: _tabController,
        builder: (_, __) {
          if (_tabController.index == 0) {
            return FloatingActionButton.extended(
              onPressed: () => showDoseDialog(),
              backgroundColor: AppTheme.primary,
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text(
                'Add Dose',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            );
          }

          if (_tabController.index == 1) {
            return FloatingActionButton.extended(
              onPressed: showMedicalDialog,
              backgroundColor: AppTheme.primary,
              icon: const Icon(Icons.edit_outlined, color: Colors.white),
              label: const Text(
                'Edit Info',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget buildDosesTab() {
    if (dosesLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (doses.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.medication_outlined,
              size: 64,
              color: AppTheme.textLight.withOpacity(0.4),
            ),
            const SizedBox(height: 16),
            const Text(
              'No doses added yet.',
              style: TextStyle(fontSize: 16, color: AppTheme.textLight),
            ),
            const SizedBox(height: 6),
            const Text(
              'Tap "Add Dose" to create the first one.',
              style: TextStyle(fontSize: 13, color: AppTheme.textLight),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
      itemCount: doses.length,
      itemBuilder: (_, index) => doseCard(doses[index]),
    );
  }

  Widget doseCard(DoseModel dose) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE8EEF4)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.medication_outlined,
                    color: AppTheme.primary,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    dose.dosage != null && dose.dosage!.isNotEmpty
                        ? '${dose.label} · ${dose.dosage}'
                        : dose.label,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textDark,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit_outlined),
                  color: AppTheme.primary,
                  onPressed: () => showDoseDialog(existing: dose),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  color: Colors.red,
                  onPressed: () => deleteDose(dose.id),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Time: ${dose.scheduledTime}',
              style: const TextStyle(color: AppTheme.textLight),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 5,
              children: dose.days.split(',').map((day) {
                return Chip(label: Text(day));
              }).toList(),
            ),
            if (dose.instructions != null &&
                dose.instructions!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                dose.instructions!,
                style: const TextStyle(color: AppTheme.textLight),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget buildMedicalTab() {
    if (medicalLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (medicalInfo == null) {
      return const Center(
        child: Text(
          'No medical info yet. Tap "Edit Info" to add medical details.',
          style: TextStyle(color: AppTheme.textLight),
        ),
      );
    }

    final info = medicalInfo!;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
      child: Column(
        children: [
          infoCard('Basic Info', [
            if (info.age != null) infoRow('Age', '${info.age} years'),
            if (info.bloodType != null) infoRow('Blood type', info.bloodType!),
          ]),
          if (info.allergies != null && info.allergies!.isNotEmpty)
            chipCard('Allergies', info.allergies!.split(',')),
          if (info.conditions != null && info.conditions!.isNotEmpty)
            chipCard('Conditions', info.conditions!.split(',')),
          emergencyContactCard(info),
          if (info.notes != null && info.notes!.isNotEmpty)
            infoCard('Notes', [
              Text(
                info.notes!,
                style: const TextStyle(color: AppTheme.textDark),
              ),
            ]),
        ],
      ),
    );
  }

  Widget emergencyContactCard(MedicalInfoModel info) {
    final hasName =
        info.emergencyName != null && info.emergencyName!.trim().isNotEmpty;
    final hasPhone =
        info.emergencyPhone != null && info.emergencyPhone!.trim().isNotEmpty;

    if (!hasName && !hasPhone) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8EEF4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'EMERGENCY CONTACT',
            style: TextStyle(
              fontSize: 11,
              color: AppTheme.textLight,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),

          if (hasName) infoRow('Name', info.emergencyName!),

          if (hasPhone) ...[
            infoRow('Phone', info.emergencyPhone!),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 46,
              child: ElevatedButton.icon(
                onPressed: () => callEmergencyContact(info.emergencyPhone!),
                icon: const Icon(Icons.call, color: Colors.white),
                label: const Text(
                  'Call Emergency Contact',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget infoCard(String title, List<Widget> rows) {
    if (rows.isEmpty) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8EEF4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.toUpperCase(),
            style: const TextStyle(
              fontSize: 11,
              color: AppTheme.textLight,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          ...rows,
        ],
      ),
    );
  }

  Widget infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Text(label, style: const TextStyle(color: AppTheme.textLight)),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              color: AppTheme.textDark,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget chipCard(String title, List<String> items) {
    return infoCard(
      title,
      [
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: items.map((item) {
            return Chip(label: Text(item.trim()));
          }).toList(),
        ),
      ],
    );
  }

  Widget buildHistoryTab() {
    if (historyLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final weekPercent = patientController.adherencePercent(events, 7);
    final monthPercent = patientController.adherencePercent(events, 30);
    final streak = patientController.streak(events);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            children: [
              statCard('${weekPercent.toStringAsFixed(0)}%', 'This week'),
              const SizedBox(width: 10),
              statCard('${monthPercent.toStringAsFixed(0)}%', 'This month'),
              const SizedBox(width: 10),
              statCard('$streak', 'Day streak'),
            ],
          ),
          const SizedBox(height: 16),
          if (events.isEmpty)
            const Padding(
              padding: EdgeInsets.all(40),
              child: Text(
                'No dose events yet.',
                style: TextStyle(color: AppTheme.textLight),
              ),
            )
          else
            Column(
              children: events.map((event) => historyItem(event)).toList(),
            ),
        ],
      ),
    );
  }

  Widget historyItem(DoseEventModel event) {
    final time = DateTime.tryParse(event.createdAt);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE8EEF4)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              event.medicineName,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Text(event.status),
          if (time != null) Text('  ${time.day}/${time.month}/${time.year}'),
        ],
      ),
    );
  }

  Widget statCard(String value, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE8EEF4)),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppTheme.primary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                color: AppTheme.textLight,
              ),
            ),
          ],
        ),
      ),
    );
  }
}