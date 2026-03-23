import 'package:flutter/material.dart';
<<<<<<< HEAD
import 'views/auth/register_flow_screen.dart';

=======
import 'theme/app_colors.dart';
import 'views/main_screen.dart';
>>>>>>> 37ce4c6a42ca010449fce516f14affc49c0a2d28
void main() {
  runApp(const WorkoutApp());
}
<<<<<<< HEAD

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Athletica',
      debugShowCheckedModeBanner: false,
      home: const RegisterFlowScreen(), 
=======
 
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
      home: const MainScreen(),
>>>>>>> 37ce4c6a42ca010449fce516f14affc49c0a2d28
    );
  }
}