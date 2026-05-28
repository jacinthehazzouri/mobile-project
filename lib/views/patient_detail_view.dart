import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../theme/app_theme.dart';

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
  final supabase = Supabase.instance.client;
  late TabController _tabController;

  List<Map<String, dynamic>> _doses = [];
  bool _dosesLoading = true;
  Map<String, dynamic>? _medicalInfo;
  bool _medicalLoading = true;
  List<Map<String, dynamic>> _events = [];
  bool _historyLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        switch (_tabController.index) {
          case 0: _loadDoses(); break;
          case 1: _loadMedicalInfo(); break;
          case 2: _loadHistory(); break;
        }
      }
    });
    _loadDoses();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // ── LOAD DOSES ─────────────────────────────────────────────
  Future<void> _loadDoses() async {
    setState(() => _dosesLoading = true);
    try {
      final data = await supabase
          .from('doses')
          .select()
          .eq('patient_id', widget.patientId)
          .eq('active', true)
          .order('scheduled_time', ascending: true);
      setState(() {
        _doses = List<Map<String, dynamic>>.from(data);
        _dosesLoading = false;
      });
    } catch (e) {
      setState(() => _dosesLoading = false);
      _showError('Failed to load doses: $e');
    }
  }

  // ── LOAD MEDICAL INFO ──────────────────────────────────────
  Future<void> _loadMedicalInfo() async {
    setState(() => _medicalLoading = true);
    try {
      final data = await supabase
          .from('medical_info')
          .select()
          .eq('patient_id', widget.patientId)
          .maybeSingle();
      setState(() {
        _medicalInfo = data;
        _medicalLoading = false;
      });
    } catch (e) {
      setState(() => _medicalLoading = false);
    }
  }

  // ── LOAD HISTORY ───────────────────────────────────────────
  Future<void> _loadHistory() async {
    setState(() => _historyLoading = true);
    try {
      final data = await supabase
          .from('dose_events')
          .select('*, dose:doses(label)')
          .eq('patient_id', widget.patientId)
          .order('created_at', ascending: false)
          .limit(30);
      setState(() {
        _events = List<Map<String, dynamic>>.from(data);
        _historyLoading = false;
      });
    } catch (e) {
      setState(() => _historyLoading = false);
    }
  }

  void _showError(String msg) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    }
  }

  void _showSuccess(String msg) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: Colors.green),
      );
    }
  }

  // ════════════════════════════════════════════════════════════
  // DOSES TAB — ADD / EDIT DIALOG
  // ════════════════════════════════════════════════════════════
  void _showDoseDialog({Map<String, dynamic>? existing}) {
    final labelCtrl  = TextEditingController(text: existing?['label'] ?? '');
    final dosageCtrl = TextEditingController(text: existing?['dosage'] ?? '');
    final instrCtrl  = TextEditingController(text: existing?['instructions'] ?? '');

    TimeOfDay selectedTime = TimeOfDay.now();
    if (existing?['scheduled_time'] != null) {
      final parts = (existing!['scheduled_time'] as String).split(':');
      selectedTime = TimeOfDay(
        hour:   int.parse(parts[0]),
        minute: int.parse(parts[1]),
      );
    }

    final List<String> allDays = ['Mon','Tue','Wed','Thu','Fri','Sat','Sun'];
    final Set<String> selectedDays = existing != null
        ? Set<String>.from((existing['days'] as String).split(','))
        : {'Mon','Tue','Wed','Thu','Fri'};

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: EdgeInsets.only(
            left: 24, right: 24, top: 24,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Row(children: [
                  Text(
                    existing == null ? 'Add Dose' : 'Edit Dose',
                    style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.bold,
                      color: AppTheme.textDark,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ]),
                const SizedBox(height: 14),
                TextField(
                  controller: labelCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Medicine name',
                    hintText: 'e.g. Metformin',
                    prefixIcon: Icon(Icons.medication_outlined),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: dosageCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Dosage',
                    hintText: 'e.g. 500mg, 10ml',
                    prefixIcon: Icon(Icons.science_outlined),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: instrCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Instructions (optional)',
                    hintText: 'e.g. Take with food',
                    prefixIcon: Icon(Icons.notes_outlined),
                  ),
                ),
                const SizedBox(height: 12),
                const Text('Scheduled time',
                    style: TextStyle(color: AppTheme.textLight, fontSize: 13)),
                const SizedBox(height: 6),
                GestureDetector(
                  onTap: () async {
                    final picked = await showTimePicker(
                        context: ctx, initialTime: selectedTime);
                    if (picked != null) setS(() => selectedTime = picked);
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 18, vertical: 14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFDDE5F0)),
                    ),
                    child: Row(children: [
                      const Icon(Icons.access_time, color: AppTheme.textLight),
                      const SizedBox(width: 12),
                      Text(
                        selectedTime.format(ctx),
                        style: const TextStyle(
                          fontSize: 15, color: AppTheme.textDark,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ]),
                  ),
                ),
                const SizedBox(height: 12),
                const Text('Days',
                    style: TextStyle(color: AppTheme.textLight, fontSize: 13)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: allDays.map<Widget>((day) {
                    final sel = selectedDays.contains(day);
                    return GestureDetector(
                      onTap: () => setS(() => sel
                          ? selectedDays.remove(day)
                          : selectedDays.add(day)),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: sel
                              ? AppTheme.primary
                              : AppTheme.primary.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(day,
                            style: TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w600,
                              color: sel ? Colors.white : AppTheme.primary,
                            )),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 22),
                SizedBox(
                  width: double.infinity, height: 52,
                  child: ElevatedButton(
                    onPressed: () async {
                      if (labelCtrl.text.trim().isEmpty) {
                        _showError('Please enter medicine name');
                        return;
                      }
                      if (selectedDays.isEmpty) {
                        _showError('Please select at least one day');
                        return;
                      }
                      final timeStr =
                          '${selectedTime.hour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')}';
                      final orderedDays = allDays
                          .where((d) => selectedDays.contains(d))
                          .join(',');
                      Navigator.pop(ctx);
                      if (existing == null) {
                        await _addDose(
                          label:        labelCtrl.text.trim(),
                          dosage:       dosageCtrl.text.trim(),
                          time:         timeStr,
                          days:         orderedDays,
                          instructions: instrCtrl.text.trim(),
                        );
                      } else {
                        await _editDose(
                          id:           existing['id'],
                          label:        labelCtrl.text.trim(),
                          dosage:       dosageCtrl.text.trim(),
                          time:         timeStr,
                          days:         orderedDays,
                          instructions: instrCtrl.text.trim(),
                        );
                      }
                    },
                    child: Text(existing == null ? 'Add Dose' : 'Save Changes'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _addDose({
    required String label,
    required String dosage,
    required String time,
    required String days,
    required String instructions,
  }) async {
    try {
      await supabase.from('doses').insert({
        'patient_id':     widget.patientId,
        'label':          label,
        'dosage':         dosage.isNotEmpty ? dosage : null,
        'scheduled_time': time,
        'days':           days,
        'instructions':   instructions.isNotEmpty ? instructions : null,
        'active':         true,
      });
      await _loadDoses();
      _showSuccess('Dose added successfully');
    } catch (e) {
      _showError('Failed to add dose: $e');
    }
  }

  Future<void> _editDose({
    required String id,
    required String label,
    required String dosage,
    required String time,
    required String days,
    required String instructions,
  }) async {
    try {
      await supabase.from('doses').update({
        'label':          label,
        'dosage':         dosage.isNotEmpty ? dosage : null,
        'scheduled_time': time,
        'days':           days,
        'instructions':   instructions.isNotEmpty ? instructions : null,
      }).eq('id', id);
      await _loadDoses();
      _showSuccess('Dose updated');
    } catch (e) {
      _showError('Failed to update: $e');
    }
  }

  Future<void> _deleteDose(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Dose'),
        content: const Text('Are you sure?'),
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
      ),
    );
    if (confirm == true) {
      try {
        await supabase
            .from('doses')
            .update({'active': false})
            .eq('id', id);
        await _loadDoses();
        _showSuccess('Dose deleted');
      } catch (e) {
        _showError('Failed to delete: $e');
      }
    }
  }

  // ════════════════════════════════════════════════════════════
  // MEDICAL INFO TAB — EDIT DIALOG
  // ════════════════════════════════════════════════════════════
  void _showMedicalDialog() {
    final ageCtrl          = TextEditingController(text: _medicalInfo?['age']?.toString() ?? '');
    final bloodCtrl        = TextEditingController(text: _medicalInfo?['blood_type'] ?? '');
    final allergiesCtrl    = TextEditingController(text: _medicalInfo?['allergies'] ?? '');
    final conditionsCtrl   = TextEditingController(text: _medicalInfo?['conditions'] ?? '');
    final emergNameCtrl    = TextEditingController(text: _medicalInfo?['emergency_name'] ?? '');
    final emergPhoneCtrl   = TextEditingController(text: _medicalInfo?['emergency_phone'] ?? '');
    final notesCtrl        = TextEditingController(text: _medicalInfo?['notes'] ?? '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: EdgeInsets.only(
          left: 24, right: 24, top: 24,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Row(children: [
                const Text('Medical Info',
                    style: TextStyle(
                      fontSize: 20, fontWeight: FontWeight.bold,
                      color: AppTheme.textDark,
                    )),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ]),
              const SizedBox(height: 6),
              const Text(
                'This information is managed by you as the caregiver.',
                style: TextStyle(color: AppTheme.textLight, fontSize: 13),
              ),
              const SizedBox(height: 16),
              Row(children: [
                Expanded(
                  child: TextField(
                    controller: ageCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Age',
                      prefixIcon: Icon(Icons.cake_outlined),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: bloodCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Blood type',
                      hintText: 'e.g. A+',
                      prefixIcon: Icon(Icons.bloodtype_outlined),
                    ),
                  ),
                ),
              ]),
              const SizedBox(height: 12),
              TextField(
                controller: allergiesCtrl,
                decoration: const InputDecoration(
                  labelText: 'Allergies',
                  hintText: 'Comma separated: Penicillin, Aspirin',
                  prefixIcon: Icon(Icons.warning_amber_outlined),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: conditionsCtrl,
                decoration: const InputDecoration(
                  labelText: 'Medical conditions',
                  hintText: 'Comma separated: Diabetes, Hypertension',
                  prefixIcon: Icon(Icons.medical_information_outlined),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: emergNameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Emergency contact name',
                  prefixIcon: Icon(Icons.person_outline),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: emergPhoneCtrl,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Emergency contact phone',
                  prefixIcon: Icon(Icons.phone_outlined),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: notesCtrl,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Notes',
                  hintText: 'Any additional notes for this patient',
                  prefixIcon: Icon(Icons.notes_outlined),
                ),
              ),
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity, height: 52,
                child: ElevatedButton(
                  onPressed: () async {
                    Navigator.pop(ctx);
                    await _saveMedicalInfo(
                      age:           int.tryParse(ageCtrl.text.trim()),
                      bloodType:     bloodCtrl.text.trim(),
                      allergies:     allergiesCtrl.text.trim(),
                      conditions:    conditionsCtrl.text.trim(),
                      emergencyName: emergNameCtrl.text.trim(),
                      emergencyPhone: emergPhoneCtrl.text.trim(),
                      notes:         notesCtrl.text.trim(),
                    );
                  },
                  child: const Text('Save Medical Info'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _saveMedicalInfo({
    int?   age,
    required String bloodType,
    required String allergies,
    required String conditions,
    required String emergencyName,
    required String emergencyPhone,
    required String notes,
  }) async {
    try {
      // onConflict: 'patient_id' — updates existing row instead of inserting duplicate
      await supabase.from('medical_info').upsert(
        {
          'patient_id':      widget.patientId,
          'age':             age,
          'blood_type':      bloodType.isNotEmpty ? bloodType : null,
          'allergies':       allergies.isNotEmpty ? allergies : null,
          'conditions':      conditions.isNotEmpty ? conditions : null,
          'emergency_name':  emergencyName.isNotEmpty ? emergencyName : null,
          'emergency_phone': emergencyPhone.isNotEmpty ? emergencyPhone : null,
          'notes':           notes.isNotEmpty ? notes : null,
          'updated_at':      DateTime.now().toIso8601String(),
        },
        onConflict: 'patient_id', // ← KEY FIX: update if patient_id already exists
      );
      await _loadMedicalInfo();
      _showSuccess('Medical info saved');
    } catch (e) {
      _showError('Failed to save: $e');
    }
  }

  // ════════════════════════════════════════════════════════════
  // ADHERENCE HELPERS
  // ════════════════════════════════════════════════════════════
  double _adherencePercent(int days) {
    if (_events.isEmpty) return 0;
    final from = DateTime.now().subtract(Duration(days: days));
    final recent = _events.where((e) {
      final d = DateTime.tryParse(e['created_at'] ?? '');
      return d != null && d.isAfter(from);
    }).toList();
    if (recent.isEmpty) return 0;
    final taken = recent.where((e) => e['status'] == 'taken').length;
    return (taken / recent.length) * 100;
  }

  int _streak() {
    int streak = 0;
    DateTime day = DateTime.now();
    for (int i = 0; i < 30; i++) {
      final dayEvents = _events.where((e) {
        final d = DateTime.tryParse(e['created_at'] ?? '');
        return d != null &&
            d.year == day.year &&
            d.month == day.month &&
            d.day == day.day;
      }).toList();
      if (dayEvents.isEmpty) break;
      final allTaken = dayEvents.every((e) => e['status'] == 'taken');
      if (!allTaken) break;
      streak++;
      day = day.subtract(const Duration(days: 1));
    }
    return streak;
  }

  // ════════════════════════════════════════════════════════════
  // BUILD
  // ════════════════════════════════════════════════════════════
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
            Tab(icon: Icon(Icons.medication_outlined),          text: 'Doses'),
            Tab(icon: Icon(Icons.medical_information_outlined), text: 'Medical'),
            Tab(icon: Icon(Icons.history),                      text: 'History'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildDosesTab(),
          _buildMedicalTab(),
          _buildHistoryTab(),
        ],
      ),
      floatingActionButton: AnimatedBuilder(
        animation: _tabController,
        builder: (_, __) {
          if (_tabController.index == 0) {
            return FloatingActionButton.extended(
              onPressed: () => _showDoseDialog(),
              backgroundColor: AppTheme.primary,
              icon:  const Icon(Icons.add, color: Colors.white),
              label: const Text('Add Dose',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            );
          } else if (_tabController.index == 1) {
            return FloatingActionButton.extended(
              onPressed: _showMedicalDialog,
              backgroundColor: AppTheme.primary,
              icon:  const Icon(Icons.edit_outlined, color: Colors.white),
              label: const Text('Edit Info',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  // ── DOSES TAB ─────────────────────────────────────────────
  Widget _buildDosesTab() {
    if (_dosesLoading) return const Center(child: CircularProgressIndicator());
    if (_doses.isEmpty) {
      return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.medication_outlined, size: 64,
              color: AppTheme.textLight.withOpacity(0.4)),
          const SizedBox(height: 16),
          const Text('No doses added yet.',
              style: TextStyle(fontSize: 16, color: AppTheme.textLight)),
          const SizedBox(height: 6),
          const Text('Tap "Add Dose" to create the first one.',
              style: TextStyle(fontSize: 13, color: AppTheme.textLight)),
        ]),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
      itemCount: _doses.length,
      itemBuilder: (_, i) => _doseCard(_doses[i]),
    );
  }

  Widget _doseCard(Map<String, dynamic> dose) {
    final label  = dose['label'] ?? 'Unknown';
    final dosage = dose['dosage'];
    final time   = dose['scheduled_time'] ?? '--:--';
    final days   = dose['days'] ?? '';
    final instr  = dose['instructions'];

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE8EEF4)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                color: AppTheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.medication_outlined,
                  color: AppTheme.primary, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      dosage != null ? '$label · $dosage' : label,
                      style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.bold,
                        color: AppTheme.textDark,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Row(children: [
                      const Icon(Icons.access_time,
                          size: 12, color: AppTheme.textLight),
                      const SizedBox(width: 4),
                      Text(time,
                          style: const TextStyle(
                              color: AppTheme.textLight, fontSize: 12)),
                    ]),
                  ]),
            ),
            IconButton(
              icon: const Icon(Icons.edit_outlined,
                  color: AppTheme.primary, size: 20),
              onPressed: () => _showDoseDialog(existing: dose),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline,
                  color: Colors.red, size: 20),
              onPressed: () => _deleteDose(dose['id']),
            ),
          ]),
          if (days.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 5,
              children: days.split(',').map<Widget>((d) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(d,
                    style: const TextStyle(
                      fontSize: 11, fontWeight: FontWeight.w600,
                      color: AppTheme.primary,
                    )),
              )).toList(),
            ),
          ],
          if (instr != null && instr.toString().isNotEmpty) ...[
            const SizedBox(height: 7),
            Row(children: [
              const Icon(Icons.info_outline,
                  size: 12, color: AppTheme.textLight),
              const SizedBox(width: 4),
              Expanded(
                child: Text(instr.toString(),
                    style: const TextStyle(
                        color: AppTheme.textLight, fontSize: 12)),
              ),
            ]),
          ],
        ]),
      ),
    );
  }

  // ── MEDICAL TAB ───────────────────────────────────────────
  Widget _buildMedicalTab() {
    if (_medicalLoading) return const Center(child: CircularProgressIndicator());
    if (_medicalInfo == null) {
      return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.medical_information_outlined, size: 64,
              color: AppTheme.textLight.withOpacity(0.4)),
          const SizedBox(height: 16),
          const Text('No medical info yet.',
              style: TextStyle(fontSize: 16, color: AppTheme.textLight)),
          const SizedBox(height: 6),
          const Text('Tap "Edit Info" to add medical details.',
              style: TextStyle(fontSize: 13, color: AppTheme.textLight)),
        ]),
      );
    }

    final m = _medicalInfo!;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
      child: Column(children: [
        _infoCard('Basic Info', [
          if (m['age'] != null)        _infoRow('Age',        '${m['age']} years'),
          if (m['blood_type'] != null) _infoRow('Blood type', m['blood_type']),
        ]),
        if (m['allergies'] != null && m['allergies'].toString().isNotEmpty)
          _chipCard('Allergies',
              m['allergies'].toString().split(','),
              Colors.red.shade100, Colors.red.shade800),
        if (m['conditions'] != null && m['conditions'].toString().isNotEmpty)
          _chipCard('Conditions',
              m['conditions'].toString().split(','),
              Colors.orange.shade100, Colors.orange.shade800),
        if (m['emergency_name'] != null || m['emergency_phone'] != null)
          _infoCard('Emergency Contact', [
            if (m['emergency_name']  != null) _infoRow('Name',  m['emergency_name']),
            if (m['emergency_phone'] != null) _infoRow('Phone', m['emergency_phone']),
          ]),
        if (m['notes'] != null && m['notes'].toString().isNotEmpty)
          Container(
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
                  const Text('NOTES',
                      style: TextStyle(
                        fontSize: 11, color: AppTheme.textLight,
                        fontWeight: FontWeight.w600, letterSpacing: .5,
                      )),
                  const SizedBox(height: 8),
                  Text(m['notes'].toString(),
                      style: const TextStyle(
                          fontSize: 14, color: AppTheme.textDark, height: 1.5)),
                ]),
          ),
      ]),
    );
  }

  Widget _infoCard(String title, List<Widget> rows) {
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
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title.toUpperCase(),
            style: const TextStyle(
              fontSize: 11, color: AppTheme.textLight,
              fontWeight: FontWeight.w600, letterSpacing: .5,
            )),
        const SizedBox(height: 10),
        ...List<Widget>.from(rows),
      ]),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(children: [
        Text(label,
            style: const TextStyle(color: AppTheme.textLight, fontSize: 13)),
        const Spacer(),
        Text(value,
            style: const TextStyle(
              color: AppTheme.textDark, fontSize: 13,
              fontWeight: FontWeight.w600,
            )),
      ]),
    );
  }

  Widget _chipCard(String title, List<String> items, Color bg, Color fg) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8EEF4)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title.toUpperCase(),
            style: const TextStyle(
              fontSize: 11, color: AppTheme.textLight,
              fontWeight: FontWeight.w600, letterSpacing: .5,
            )),
        const SizedBox(height: 10),
        Wrap(
          spacing: 6, runSpacing: 6,
          children: items.map<Widget>((item) => Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(item.trim(),
                style: TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w600, color: fg)),
          )).toList(),
        ),
      ]),
    );
  }

  // ── HISTORY TAB ───────────────────────────────────────────
  Widget _buildHistoryTab() {
    if (_historyLoading) return const Center(child: CircularProgressIndicator());

    final weekPct  = _adherencePercent(7);
    final monthPct = _adherencePercent(30);
    final streak   = _streak();

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
      child: Column(children: [
        Row(children: [
          _statCard('${weekPct.toStringAsFixed(0)}%', 'This week',
              weekPct  >= 80 ? Colors.green : Colors.orange),
          const SizedBox(width: 10),
          _statCard('${monthPct.toStringAsFixed(0)}%', 'This month',
              monthPct >= 80 ? Colors.green : Colors.orange),
          const SizedBox(width: 10),
          _statCard('$streak', 'Day streak', AppTheme.primary),
        ]),
        const SizedBox(height: 16),
        if (_events.isEmpty)
          Padding(
            padding: const EdgeInsets.all(40),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.history, size: 48,
                  color: AppTheme.textLight.withOpacity(0.4)),
              const SizedBox(height: 12),
              const Text('No dose events yet.',
                  style: TextStyle(color: AppTheme.textLight)),
            ]),
          )
        else
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE8EEF4)),
            ),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _events.length,
              separatorBuilder: (_, __) =>
              const Divider(height: 1, color: Color(0xFFF0F4FF)),
              itemBuilder: (_, i) {
                final e      = _events[i];
                final name   = e['dose']?['label'] ?? 'Unknown';
                final status = e['status'] ?? 'unknown';
                final time   = e['created_at'] != null
                    ? DateTime.tryParse(e['created_at'])
                    : null;

                Color dotColor;
                Color badgeBg;
                Color badgeFg;
                switch (status) {
                  case 'taken':
                    dotColor = Colors.green;
                    badgeBg  = Colors.green.shade100;
                    badgeFg  = Colors.green.shade800;
                    break;
                  case 'missed':
                    dotColor = Colors.red;
                    badgeBg  = Colors.red.shade100;
                    badgeFg  = Colors.red.shade800;
                    break;
                  default:
                    dotColor = Colors.orange;
                    badgeBg  = Colors.orange.shade100;
                    badgeFg  = Colors.orange.shade800;
                }

                return Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                  child: Row(children: [
                    Container(
                      width: 8, height: 8,
                      decoration: BoxDecoration(
                          color: dotColor, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(name,
                                style: const TextStyle(
                                  fontSize: 13, fontWeight: FontWeight.w600,
                                  color: AppTheme.textDark,
                                )),
                            if (time != null)
                              Text(
                                '${time.day}/${time.month}/${time.year}  '
                                    '${time.hour.toString().padLeft(2,'0')}:'
                                    '${time.minute.toString().padLeft(2,'0')}',
                                style: const TextStyle(
                                    fontSize: 11, color: AppTheme.textLight),
                              ),
                          ]),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: badgeBg,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        status[0].toUpperCase() + status.substring(1),
                        style: TextStyle(
                          fontSize: 11, fontWeight: FontWeight.w600,
                          color: badgeFg,
                        ),
                      ),
                    ),
                  ]),
                );
              },
            ),
          ),
      ]),
    );
  }

  Widget _statCard(String value, String label, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE8EEF4)),
        ),
        child: Column(children: [
          Text(value,
              style: TextStyle(
                  fontSize: 22, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 4),
          Text(label,
              style: const TextStyle(
                  fontSize: 11, color: AppTheme.textLight),
              textAlign: TextAlign.center),
        ]),
      ),
    );
  }
}