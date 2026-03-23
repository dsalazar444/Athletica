import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

class Step2Coach extends StatefulWidget {
  final Future<void> Function(String specialty, String yearsExperience) onNext;

  const Step2Coach({super.key, required this.onNext});

  @override
  State<Step2Coach> createState() => _Step2CoachState();
}

class _Step2CoachState extends State<Step2Coach> {
  final specialtyController = TextEditingController();
  final yearsController = TextEditingController();

  bool isValid = false;

  void validate() {
    setState(() {
      isValid =
          specialtyController.text.isNotEmpty &&
          yearsController.text.isNotEmpty;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Datos del entrenador",
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),
          const Text(
            "Cuéntanos sobre tu experiencia",
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 20),
          _input("Especialidad", specialtyController),
          const SizedBox(height: 15),
          _input("Años de experiencia", yearsController, isNumber: true),
          const SizedBox(height: 30),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: isValid
              ? () async => await widget.onNext(
                    specialtyController.text,
                    yearsController.text,
                  )
              : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text("Continuar"),
            ),
          ),
        ],
      ),
    );
  }

  Widget _input(String label, TextEditingController controller,
      {bool isNumber = false}) {
    return TextField(
      controller: controller,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      onChanged: (_) => validate(),
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: AppColors.surfaceVariant,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}