import 'package:flutter/material.dart';
import 'home/home_screen.dart';
import 'routine/routines_list_screen.dart';
import 'profile/profile_screen.dart';
import 'nutrition/nutrition_screen.dart';
import '../../theme/app_colors.dart';
import '../../core/token_storage.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  int? _athleteId;

  @override
  void initState() {
    super.initState();
    _loadAthleteId();
  }

  Future<void> _loadAthleteId() async {
    final id = await TokenStorage.getAthleteId();
    setState(() => _athleteId = id);
  }

  List<Widget> get _screens => [
    const HomeScreen(),
    const RoutinesListScreen(),
    _athleteId != null
        ? NutritionScreen(athleteId: _athleteId!)
        : const Center(child: CircularProgressIndicator()),
    const Center(child: Text('Comunidad')),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() => _currentIndex = index);
        },
        backgroundColor: AppColors.surface,
        indicatorColor: AppColors.primary.withValues(alpha: 0.15),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home, color: AppColors.primary),
            label: 'Inicio',
          ),
          NavigationDestination(
            icon: Icon(Icons.fitness_center_outlined),
            selectedIcon: Icon(Icons.fitness_center, color: AppColors.primary),
            label: 'Rutinas',
          ),
          NavigationDestination(
            icon: Icon(Icons.restaurant_outlined),
            selectedIcon: Icon(Icons.restaurant, color: AppColors.primary),
            label: 'Comida',
          ),
          NavigationDestination(
            icon: Icon(Icons.people_outline),
            selectedIcon: Icon(Icons.people, color: AppColors.primary),
            label: 'Comunidad',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person, color: AppColors.primary),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }
}
