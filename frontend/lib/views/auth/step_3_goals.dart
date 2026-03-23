import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../models/auth/register_model.dart';

class Step3Goals extends StatefulWidget {
  final Function(UserGoal) onNext; 

  const Step3Goals({super.key, required this.onNext});

  @override
  State<Step3Goals> createState() => _Step3GoalsState();
}

class _Step3GoalsState extends State<Step3Goals> {

  UserGoal? selectedGoal; //

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [

        const Text(
          "¿Cuál es tu objetivo?",
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
        ),

        const SizedBox(height: 10),

        const Text("Selecciona tu meta principal"),

        const SizedBox(height: 20),

        _card("Fuerza", UserGoal.fuerza),
        const SizedBox(height: 10),

        _card("Resistencia", UserGoal.resistencia),
        const SizedBox(height: 10),

        _card("Salud", UserGoal.salud),
        const SizedBox(height: 10),

        _card("Estética", UserGoal.estetica),

        const Spacer(),

        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: selectedGoal == null
                ? null
                : () => widget.onNext(selectedGoal!),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
            ),
            child: const Text("Continuar"),
          ),
        ),
      ],
    );
  }

  Widget _card(String title, UserGoal value) {
    final isSelected = selectedGoal == value;

    return GestureDetector(
      onTap: () {
        setState(() {
          selectedGoal = value;
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