import 'package:flutter/material.dart';
import 'theme/app_colors.dart';
import 'views/routine/new_routine_view.dart';

void main() {
  runApp(const WorkoutApp());
}
 
class WorkoutApp extends StatelessWidget {
  const WorkoutApp({super.key});
 
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Athletica: Tu progreso fitness',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primary),
        scaffoldBackgroundColor: AppColors.background,
      ),
      home: const NewRoutineScreen(),
    );
  }
}