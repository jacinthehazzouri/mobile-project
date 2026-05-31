import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

import '../controllers/link_patient_controller.dart';
import '../theme/app_theme.dart';

class LinkPatientView extends StatefulWidget {
  const LinkPatientView({super.key});

  @override
  State<LinkPatientView> createState() => _LinkPatientViewState();
}

class _LinkPatientViewState extends State<LinkPatientView> {
  final LinkPatientController linkPatientController = LinkPatientController();

  final patientIdController = TextEditingController();

  bool loading = false;

  void showToast(String message) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
    );
  }

  Future<void> linkPatient() async {
    if (patientIdController.text.trim().isEmpty) {
      showToast('Please enter patient ID');
      return;
    }

    setState(() => loading = true);

    try {
      await linkPatientController.linkPatient(
        patientIdController.text.trim(),
      );

      if (!mounted) return;

      showToast('Patient linked successfully');
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      showToast('Failed to link patient');
    }

    if (mounted) {
      setState(() => loading = false);
    }
  }

  @override
  void dispose() {
    patientIdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Link Patient'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Container(
                width: 82,
                height: 82,
                decoration: BoxDecoration(
                  color: AppTheme.primary,
                  borderRadius: BorderRadius.circular(26),
                ),
                child: const Icon(
                  Icons.link,
                  color: Colors.white,
                  size: 42,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Link Patient by ID',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textDark,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Enter the patient ID to connect them to your caregiver account.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  color: AppTheme.textLight,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 30),
              TextField(
                controller: patientIdController,
                decoration: const InputDecoration(
                  labelText: 'Patient ID',
                  prefixIcon: Icon(Icons.badge_outlined),
                ),
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: loading ? null : linkPatient,
                  child: loading
                      ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Colors.white,
                    ),
                  )
                      : const Text('Link Patient'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}