import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_text_styles.dart';

class Step2Coach extends StatefulWidget {
  final Future<void> Function(
    String firstName,
    String speciality,
    String yearsExperience,
  )
  onNext;
  const Step2Coach({super.key, required this.onNext});

  @override
  State<Step2Coach> createState() => _Step2CoachState();
}

class _Step2CoachState extends State<Step2Coach> {
  final firstNameController = TextEditingController();
  final yearsController = TextEditingController();
  String? selectedSpeciality;
  bool isValid = false;

  void validate() {
    setState(() {
      isValid =
          firstNameController.text.isNotEmpty &&
          selectedSpeciality != null &&
          yearsController.text.isNotEmpty;
    });
  }

  @override
  void dispose() {
    firstNameController.dispose();
    yearsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Datos del entrenador", style: AppTextStyles.sectionTitle),
          const SizedBox(height: 8),
          Text(
            "Cuéntanos sobre tu especialidad y experiencia profesional.",
            style: AppTextStyles.sectionSubtitle,
          ),
          const SizedBox(height: 32),

          // Input nombre
          Text("Nombre", style: AppTextStyles.inputLabel),
          const SizedBox(height: 8),
          TextField(
            controller: firstNameController,
            keyboardType: TextInputType.name,
            onChanged: (_) => validate(),
            decoration: InputDecoration(
              prefixIcon: Icon(
                Icons.person_outline,
                color: AppColors.textHint,
                size: 22,
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Dropdown especialidad
          Text("Especialidad", style: AppTextStyles.inputLabel),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            isExpanded: true,
            initialValue: selectedSpeciality,
            decoration: InputDecoration(
              prefixIcon: Icon(
                Icons.workspace_premium_outlined,
                color: AppColors.textHint,
                size: 22,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 4,
                vertical: 16,
              ),
            ),
            style: AppTextStyles.inputText,
            items: const [
              DropdownMenuItem(
                value: "lose_weight",
                child: Text("Pérdida de peso"),
              ),
              DropdownMenuItem(
                value: "gain_muscle",
                child: Text("Ganar músculo"),
              ),
              DropdownMenuItem(value: "maintain", child: Text("Mantenimiento")),
              DropdownMenuItem(value: "endurance", child: Text("Resistencia")),
              DropdownMenuItem(value: "wellness", child: Text("Bienestar")),
            ],
            onChanged: (value) {
              setState(() => selectedSpeciality = value);
              validate();
            },
          ),

          const SizedBox(height: 20),

          // Input años de experiencia
          Text("Años de experiencia", style: AppTextStyles.inputLabel),
          const SizedBox(height: 8),
          TextField(
            controller: yearsController,
            keyboardType: TextInputType.number,
            onChanged: (_) => validate(),
            decoration: InputDecoration(
              prefixIcon: Icon(
                Icons.history_toggle_off_rounded,
                color: AppColors.textHint,
                size: 22,
              ),
            ),
          ),

          const SizedBox(height: 48),
          SizedBox(
            width: double.infinity,
            height: 58,
            child: ElevatedButton(
              onPressed: isValid
                  ? () async => await widget.onNext(
                      firstNameController.text,
                      selectedSpeciality!,
                      yearsController.text,
                    )
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: AppRadius.button),
              ),
              child: Text("Continuar", style: AppTextStyles.buttonPrimary),
            ),
          ),
        ],
      ),
    );
  }
}
