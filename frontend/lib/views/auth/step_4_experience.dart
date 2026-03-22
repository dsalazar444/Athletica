import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../models/auth/register_model.dart';

class Step4Experience extends StatefulWidget {
  final Function(Experience) onNext; // ✅ enum

  const Step4Experience({super.key, required this.onNext});

  @override
  State<Step4Experience> createState() => _Step4ExperienceState();
}

class _Step4ExperienceState extends State<Step4Experience> {

  Experience? selectedLevel; // ✅ enum

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [

        const Text(
          "Nivel de experiencia",
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
        ),

        const SizedBox(height: 10),

        const Text("Selecciona tu nivel actual"),

        const SizedBox(height: 20),

        _card("Principiante", Experience.bajo),
        const SizedBox(height: 10),

        _card("Intermedio", Experience.medio),
        const SizedBox(height: 10),

        _card("Avanzado", Experience.alto),

        const Spacer(),

        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: selectedLevel == null
                ? null
                : () => widget.onNext(selectedLevel!),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
            ),
            child: const Text("Finalizar"),
          ),
        ),
      ],
    );
  }

  Widget _card(String title, Experience value) {
    final isSelected = selectedLevel == value;

    return GestureDetector(
      onTap: () {
        setState(() {
          selectedLevel = value;
        });
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Expanded(child: Text(title)),
            if (isSelected)
              const Icon(Icons.check_circle, color: AppColors.primary),
          ],
        ),
      ),
    );
  }
}