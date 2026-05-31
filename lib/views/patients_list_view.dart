import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

import '../controllers/patients_list_controller.dart';
import '../models/patient_list_model.dart';
import '../theme/app_theme.dart';
import 'patient_detail_view.dart';

class PatientsListView extends StatefulWidget {
  const PatientsListView({super.key});

  @override
  State<PatientsListView> createState() => _PatientsListViewState();
}

class _PatientsListViewState extends State<PatientsListView> {
  final PatientsListController patientsListController =
  PatientsListController();

  bool isLoading = true;
  List<PatientListModel> patients = [];

  @override
  void initState() {
    super.initState();
    loadPatients();
  }

  void showToast(String message) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
    );
  }

  Future<void> loadPatients() async {
    try {
      final result = await patientsListController.getPatients();

      if (!mounted) return;

      setState(() {
        patients = result;
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() => isLoading = false);
      showToast('Failed to load patients');
    }
  }

  Future<void> deletePatientLink(String patientId) async {
    try {
      await patientsListController.removePatient(patientId);
      await loadPatients();

      showToast('Patient removed successfully');
    } catch (e) {
      showToast('Failed to remove patient');
    }
  }

  Future<void> confirmDelete(String patientId, String patientName) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text(
            'Remove Patient',
            textAlign: TextAlign.center,
          ),
          content: Text(
            'Are you sure you want to remove $patientName from your patient list?',
            textAlign: TextAlign.center,
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            SizedBox(
              width: 110,
              height: 44,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Remove'),
              ),
            ),
          ],
        );
      },
    );

    if (shouldDelete == true) {
      await deletePatientLink(patientId);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Patients List'),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : patients.isEmpty
          ? const Center(
        child: Text(
          'No patients linked yet.',
          style: TextStyle(
            color: AppTheme.textLight,
            fontSize: 16,
          ),
        ),
      )
          : ListView.builder(
        padding: const EdgeInsets.all(24),
        itemCount: patients.length,
        itemBuilder: (context, index) {
          final patient = patients[index];

          final patientId = patient.id;
          final patientName = patient.name.isEmpty
              ? 'Unknown Patient'
              : patient.name;
          final patientPhone =
              patient.phone ?? 'No phone number';

          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: AppTheme.cardColor,
              borderRadius: BorderRadius.circular(24),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 18,
                vertical: 10,
              ),
              leading: const CircleAvatar(
                backgroundColor: AppTheme.primary,
                child: Icon(
                  Icons.person,
                  color: Colors.white,
                ),
              ),
              title: Text(
                patientName,
                style: const TextStyle(
                  color: AppTheme.textDark,
                  fontWeight: FontWeight.bold,
                  fontSize: 17,
                ),
              ),
              subtitle: Text(
                patientPhone,
                style: const TextStyle(
                  color: AppTheme.textLight,
                ),
              ),
              trailing: IconButton(
                icon: const Icon(Icons.delete_outline),
                color: Colors.red,
                onPressed: () {
                  confirmDelete(patientId, patientName);
                },
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PatientDetailView(
                      patientId: patientId,
                      patientName: patientName,
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}