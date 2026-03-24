import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../models/auth/register_model.dart';

class Step4Experience extends StatefulWidget {
  final Future<void> Function(ActivityLevel) onNext;
  const Step4Experience({super.key, required this.onNext});

  @override
  State<Step4Experience> createState() => _Step4ExperienceState();
}

class _Step4ExperienceState extends State<Step4Experience> {
  ActivityLevel? selectedLevel;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Nivel de experiencia",
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),
          const Text("Selecciona tu nivel actual"),
          const SizedBox(height: 20),
          _card("Principiante", ActivityLevel.low),
          const SizedBox(height: 10),
          _card("Intermedio", ActivityLevel.medium),
          const SizedBox(height: 10),
          _card("Avanzado", ActivityLevel.high),
          const SizedBox(height: 30),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: selectedLevel == null
                  ? null
                  : () async => await widget.onNext(selectedLevel!), 
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                "Finalizar",
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _card(String title, ActivityLevel value) {
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