import 'dart:ui';
import 'package:flutter/material.dart';
import '../../core/token_storage.dart';
import '../../models/profile/profile_settings_model.dart';
import '../../repositories/profile/profile_repository.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_text_styles.dart';
import '../auth/login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String _userName = '';
  String _role = 'athlete';
  int? _age;
  double? _weight;
  double? _height;
  String? _trainingGoal;

  final ProfileRepository _profileRepository = ProfileRepository();

  final _nameCtrl = TextEditingController();
  final _weightCtrl = TextEditingController();
  final _heightCtrl = TextEditingController();
  String? _selectedGoal;

  bool _isProfileLoading = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadProfileSettings();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _weightCtrl.dispose();
    _heightCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadProfileSettings() async {
    setState(() => _isProfileLoading = true);
    try {
      final profile = await _profileRepository.getProfileSettings();
      if (!mounted) return;
      setState(() {
        _userName = profile.name;
        _role = profile.role;
        _age = profile.age;
        _weight = profile.weight;
        _height = profile.height;
        _trainingGoal = profile.trainingGoal;
        _nameCtrl.text = profile.name;
        _weightCtrl.text = profile.weight?.toStringAsFixed(1) ?? '';
        _heightCtrl.text = profile.height?.toStringAsFixed(1) ?? '';
        _selectedGoal = profile.trainingGoal;
        _isProfileLoading = false;
      });
    } catch (_) {
      final fallbackName = await TokenStorage.getUserName();
      if (!mounted) return;
      setState(() {
        _userName = fallbackName ?? 'Usuario';
        _nameCtrl.text = _userName;
        _isProfileLoading = false;
      });
    }
  }

  Future<void> _saveProfileSettings() async {
    final name = _nameCtrl.text.trim();
    final weight = double.tryParse(_weightCtrl.text.trim());
    final height = double.tryParse(_heightCtrl.text.trim());

    if (name.isEmpty || weight == null || height == null || _selectedGoal == null) {
      _showMessage('Completa todos los campos con valores validos.');
      return;
    }

    if (weight <= 0 || height <= 0) {
      _showMessage('Peso y altura deben ser mayores que 0.');
      return;
    }

    setState(() => _isSaving = true);
    try {
      final updated = await _profileRepository.updateProfileSettings(
        ProfileSettingsModel(
          name: name,
          age: _age,
          weight: weight,
          height: height,
          trainingGoal: _selectedGoal,
          role: _role,
        ),
      );

      await TokenStorage.saveUserName(updated.name);

      if (!mounted) return;
      setState(() {
        _userName = updated.name;
        _age = updated.age;
        _weight = updated.weight;
        _height = updated.height;
        _trainingGoal = updated.trainingGoal;
        _nameCtrl.text = updated.name;
        _weightCtrl.text = updated.weight?.toStringAsFixed(1) ?? '';
        _heightCtrl.text = updated.height?.toStringAsFixed(1) ?? '';
        _selectedGoal = updated.trainingGoal;
        _isSaving = false;
      });

      Navigator.pop(context);
      _showMessage('Perfil actualizado correctamente.');
    } catch (_) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      _showMessage('No se pudieron guardar los cambios. Intenta de nuevo.');
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  void _openSettingsSheet() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: Container(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
            decoration: const BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Configuracion del perfil',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 16),
                  _buildInputField(
                    controller: _nameCtrl,
                    label: 'Nombre',
                    keyboardType: TextInputType.name,
                  ),
                  const SizedBox(height: 12),
                  _buildInputField(
                    controller: _weightCtrl,
                    label: 'Peso (kg)',
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  ),
                  const SizedBox(height: 12),
                  _buildInputField(
                    controller: _heightCtrl,
                    label: 'Altura (cm)',
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.cake_rounded, color: AppColors.primary),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Edad registrada: ${_age?.toString() ?? "Sin dato"}',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Objetivo de entrenamiento',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    initialValue: _selectedGoal,
                    decoration: _inputDecoration(),
                    items: _goalOptions
                        .map(
                          (goal) => DropdownMenuItem<String>(
                            value: goal.value,
                            child: Text(goal.label),
                          ),
                        )
                        .toList(),
                    onChanged: (value) => setState(() => _selectedGoal = value),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _saveProfileSettings,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: _isSaving
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2.4,
                              ),
                            )
                          : const Text(
                              'Guardar cambios',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  InputDecoration _inputDecoration() {
    return InputDecoration(
      filled: true,
      fillColor: AppColors.background,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          decoration: _inputDecoration(),
        ),
      ],
    );
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
                'Cerrar sesion?',
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
              content: const Text(
                'Tu progreso se mantendra a salvo hasta que vuelvas.',
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
                    'CERRAR SESION',
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
    final nameDisplay = _userName.isNotEmpty ? _userName : 'Usuario';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: _isProfileLoading
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              )
            : SingleChildScrollView(
                child: Column(
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.only(
                        left: 24,
                        right: 24,
                        top: 40,
                        bottom: 28,
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
                              nameDisplay[0].toUpperCase(),
                              style: const TextStyle(
                                fontSize: 36,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            nameDisplay,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _role == 'coach' ? 'Coach' : 'Athlete',
                            style: const TextStyle(
                              fontSize: 13,
                              color: Colors.white70,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Tus datos',
                            style: AppTextStyles.fitnessBold.copyWith(
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: _ProfileStatCard(
                                  label: 'Edad',
                                  value: _age?.toString() ?? 'Sin dato',
                                  icon: Icons.cake_rounded,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _ProfileStatCard(
                                  label: 'Peso',
                                  value: _weight != null
                                      ? '${_weight!.toStringAsFixed(1)} kg'
                                      : 'Sin dato',
                                  icon: Icons.monitor_weight_rounded,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: _ProfileStatCard(
                                  label: 'Altura',
                                  value: _height != null
                                      ? '${_height!.toStringAsFixed(1)} cm'
                                      : 'Sin dato',
                                  icon: Icons.height_rounded,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _ProfileStatCard(
                                  label: 'Objetivo',
                                  value: _goalLabel(_trainingGoal),
                                  icon: Icons.flag_rounded,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          Text(
                            'Configuracion',
                            style: AppTextStyles.fitnessBold.copyWith(
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 12),
                          _buildOption(
                            icon: Icons.settings,
                            label: 'Editar perfil',
                            onTap: _openSettingsSheet,
                          ),
                          const SizedBox(height: 14),
                          _buildOption(
                            icon: Icons.logout,
                            label: 'Cerrar sesion',
                            color: AppColors.error,
                            onTap: _logout,
                          ),
                          const SizedBox(height: 36),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
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
}

class _ProfileStatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _ProfileStatCard({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.card,
        boxShadow: AppColors.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.primary, size: 20),
          const SizedBox(height: 14),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.cardTitle.copyWith(fontSize: 16),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: AppTextStyles.cardSubtitle,
          ),
        ],
      ),
    );
  }
}

String _goalLabel(String? goal) {
  switch (goal) {
    case 'lose_weight':
      return 'Perder peso';
    case 'gain_muscle':
      return 'Ganar musculo';
    case 'maintain':
      return 'Mantener';
    case 'endurance':
      return 'Resistencia';
    case 'wellness':
      return 'Bienestar';
    default:
      return 'Sin dato';
  }
}

class _GoalOption {
  final String value;
  final String label;

  const _GoalOption(this.value, this.label);
}

const List<_GoalOption> _goalOptions = [
  _GoalOption('lose_weight', 'Perder peso'),
  _GoalOption('gain_muscle', 'Ganar musculo'),
  _GoalOption('maintain', 'Mantener estado'),
  _GoalOption('endurance', 'Resistencia'),
  _GoalOption('wellness', 'Bienestar'),
];
