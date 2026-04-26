import 'dart:ui';
import 'package:flutter/material.dart';
import '../../core/token_storage.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_text_styles.dart';
import '../../view_models/dashboard/dashboard_view_model.dart';
import '../auth/login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String _userName = '';
  String _userRole = '';
  final DashboardViewModel _vm = DashboardViewModel();

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final name = await TokenStorage.getUserName();
    final role = await TokenStorage.getUserRole();
    setState(() {
      _userName = name ?? 'Usuario';
      _userRole = role ?? '';
    });
    if (_userRole == 'athlete') {
      await _vm.loadAthleteDashboard();
    } else if (_userRole == 'coach') {
      await _vm.loadCoachDashboard();
    }
    if (mounted) setState(() {});
  }

  Future<void> _logout() async {
    final confirm = await showGeneralDialog<bool>(
      context: context,
      barrierDismissible: true,
      barrierLabel: '',
      pageBuilder: (ctx, anim1, anim2) => Container(),
      transitionBuilder: (ctx, anim1, anim2, child) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: ScaleTransition(
            scale: anim1,
            child: AlertDialog(
              backgroundColor: AppColors.surface.withValues(alpha: 0.9),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              title: const Text(
                '¿Cerrar Sesión?',
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
              content: const Text(
                'Tu progreso se mantendrá a salvo hasta que vuelvas.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text(
                    'CANCELAR',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.error,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'CERRAR SESIÓN',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
      transitionDuration: const Duration(milliseconds: 300),
    );

    if (confirm == true) {
      await TokenStorage.clearTokens();
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (_) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Header — igual que antes
              Container(
                width: double.infinity,
                padding: const EdgeInsets.only(
                  left: 24,
                  right: 24,
                  top: 40,
                  bottom: 40,
                ),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.primary, Color(0xFFFF8A5C)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(30),
                    bottomRight: Radius.circular(30),
                  ),
                ),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: Colors.white.withValues(alpha: 0.3),
                      child: Text(
                        _userName.isNotEmpty ? _userName[0].toUpperCase() : '?',
                        style: const TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _userName,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _userRole == 'coach' ? 'Entrenador' : 'Atleta',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Datos según el rol
                    if (_userRole == 'athlete') _buildAthleteProfile(),
                    if (_userRole == 'coach') _buildCoachProfile(),

                    const SizedBox(height: 32),

                    // Cerrar sesión
                    _buildOption(
                      icon: Icons.logout,
                      label: 'Cerrar sesión',
                      color: AppColors.error,
                      onTap: _logout,
                    ),
                    const SizedBox(height: 120),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Perfil Atleta ──────────────────────────────────────────────────────────

  Widget _buildAthleteProfile() {
    final d = _vm.athleteDashboard;
    if (_vm.isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "MIS DATOS",
          style: AppTextStyles.fitnessBold.copyWith(letterSpacing: 1.0),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _infoCard(
                icon: Icons.height_rounded,
                label: "Altura",
                value: d != null
                    ? "${(d.height * 100).toStringAsFixed(0)} cm"
                    : "--",
                color: const Color(0xFF448AFF),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _infoCard(
                icon: Icons.cake_rounded,
                label: "Edad",
                value: d != null ? "${d.age} años" : "--",
                color: const Color(0xFFFF5252),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _infoCard(
                icon: Icons.wc_rounded,
                label: "Género",
                value: d != null ? _mapGender(d.gender) : "--",
                color: const Color(0xFFFFD740),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _infoCard(
                icon: Icons.bolt_rounded,
                label: "Actividad",
                value: d != null ? _mapActivity(d.activityLevel) : "--",
                color: const Color(0xFF64FFDA),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Text(
          "MI META",
          style: AppTextStyles.fitnessBold.copyWith(letterSpacing: 1.0),
        ),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            borderRadius: AppRadius.card,
          ),
          child: Row(
            children: [
              const Icon(Icons.flag_rounded, color: Colors.white, size: 28),
              const SizedBox(width: 16),
              Text(
                d?.goal != null
                    ? _mapGoal(d!.goal!.goalType)
                    : "Sin meta activa",
                style: AppTextStyles.fitnessBold.copyWith(color: Colors.white),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Text(
          "PESO ACTUAL",
          style: AppTextStyles.fitnessBold.copyWith(letterSpacing: 1.0),
        ),
        const SizedBox(height: 16),
        _buildOption(
          icon: Icons.monitor_weight_rounded,
          label: d?.latestWeight != null
              ? "${d!.latestWeight!.weight} kg — ${d.latestWeight!.date}"
              : "Sin registros de peso",
          onTap: () {}, // navegar a historial de peso
        ),
      ],
    );
  }

  // ── Perfil Coach ───────────────────────────────────────────────────────────

  Widget _buildCoachProfile() {
    final d = _vm.coachDashboard;
    if (_vm.isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "MI PERFIL",
          style: AppTextStyles.fitnessBold.copyWith(letterSpacing: 1.0),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _infoCard(
                icon: Icons.workspace_premium_rounded,
                label: "Especialidad",
                value: d != null ? _mapSpeciality(d.speciality) : "--",
                color: const Color(0xFF448AFF),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _infoCard(
                icon: Icons.history_toggle_off_rounded,
                label: "Experiencia",
                value: d != null ? "${d.yearsExperience} años" : "--",
                color: const Color(0xFFFF5252),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Text(
          "MIS GRUPOS",
          style: AppTextStyles.fitnessBold.copyWith(letterSpacing: 1.0),
        ),
        const SizedBox(height: 16),
        if (d == null || d.groups.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: AppRadius.card,
            ),
            child: Text(
              "Sin grupos creados",
              style: AppTextStyles.sectionSubtitle,
            ),
          )
        else
          ...d.groups.map(
            (group) => Container(
              margin: const EdgeInsets.only(bottom: 12),
              child: _buildOption(
                icon: Icons.group_rounded,
                label: group.name,
                onTap: () {}, // navegar a detalle del grupo
              ),
            ),
          ),
      ],
    );
  }

  // ── Widgets compartidos ────────────────────────────────────────────────────

  Widget _infoCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.card,
        boxShadow: AppColors.deepShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 12),
          Text(value, style: AppTextStyles.fitnessBold),
          const SizedBox(height: 4),
          Text(
            label,
            style: AppTextStyles.fitnessCaption.copyWith(fontSize: 10),
          ),
        ],
      ),
    );
  }

  Widget _buildOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color? color,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Icon(icon, color: color ?? AppColors.primary),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: color ?? AppColors.textPrimary,
                ),
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: (color ?? AppColors.textPrimary).withValues(alpha: 0.4),
            ),
          ],
        ),
      ),
    );
  }

  // ── Mapeos ─────────────────────────────────────────────────────────────────

  String _mapGender(String g) {
    switch (g) {
      case 'male':
        return 'Masculino';
      case 'female':
        return 'Femenino';
      case 'other':
        return 'Otro';
      default:
        return g;
    }
  }

  String _mapActivity(String level) {
    switch (level) {
      case 'high':
        return 'Alta';
      case 'medium':
        return 'Media';
      case 'low':
        return 'Baja';
      default:
        return level;
    }
  }

  String _mapGoal(String goal) {
    switch (goal) {
      case 'lose_weight':
        return 'Pérdida de peso';
      case 'gain_muscle':
        return 'Ganar músculo';
      case 'maintain':
        return 'Mantenimiento';
      case 'endurance':
        return 'Resistencia';
      case 'wellness':
        return 'Bienestar';
      default:
        return goal;
    }
  }

  String _mapSpeciality(String s) {
    switch (s) {
      case 'lose_weight':
        return 'Pérdida de peso';
      case 'gain_muscle':
        return 'Ganar músculo';
      case 'maintain':
        return 'Mantenimiento';
      case 'endurance':
        return 'Resistencia';
      case 'wellness':
        return 'Bienestar';
      default:
        return s;
    }
  }
}
