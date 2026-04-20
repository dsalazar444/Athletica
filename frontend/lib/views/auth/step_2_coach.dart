import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_text_styles.dart';


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
          Text(
            "Datos del entrenador",
            style: AppTextStyles.sectionTitle,
          ),
          const SizedBox(height: 8),
          Text(
            "Cuéntanos sobre tu especialidad y experiencia profesional.",
            style: AppTextStyles.sectionSubtitle,
          ),
          const SizedBox(height: 32),
          _input("Especialidad", specialtyController, icon: Icons.workspace_premium_outlined),
          const SizedBox(height: 20),
          _input("Años de experiencia", yearsController, isNumber: true, icon: Icons.history_toggle_off_rounded),
          const SizedBox(height: 48),
          SizedBox(
            width: double.infinity,
            height: 58,
            child: ElevatedButton(
              onPressed: isValid
                  ? () async => await widget.onNext(
                      specialtyController.text,
                      yearsController.text,
                    )
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: AppRadius.button,
                ),
              ),
              child: Text("Continuar", style: AppTextStyles.buttonPrimary),
            ),
          ),
        ],
      ),

    );
  }

  Widget _input(
    String label,
    TextEditingController controller, {
    bool isNumber = false,
    required IconData icon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.inputLabel),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: isNumber ? TextInputType.number : TextInputType.text,
          onChanged: (_) => validate(),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: AppColors.textHint, size: 22),
          ),
        ),
      ],
    );
  }
}

