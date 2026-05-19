import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../core/api_client.dart';
import '../../core/token_storage.dart';
import '../../models/badge/badge_model.dart';
import '../../models/profile/profile_settings_model.dart';
import '../../models/profile/comparative_stats_model.dart';
import '../../models/dashboard/dashboard_model.dart';
import '../../repositories/badge/badge_repository.dart';
import '../../repositories/dashboard/dashboard_repository.dart';
import '../../repositories/profile/profile_repository.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_text_styles.dart';
import '../../view_models/dashboard/dashboard_view_model.dart';
import '../auth/login_screen.dart';
import '../group/groups_screen.dart';
import '../notifications/reminders_screen.dart';

class ProfileScreen extends StatefulWidget {
  final VoidCallback? onReminderSaved;
  final int refreshTick;

  const ProfileScreen({super.key, this.onReminderSaved, this.refreshTick = 0});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  int _lastRefreshTick = 0;
  String _userName = '';
  String _role = 'athlete';
  int? _age;
  double? _weight;
  double? _height;

  final ProfileRepository _profileRepository = ProfileRepository();
  final BadgeRepository _badgeRepository = BadgeRepository(
    baseUrl: ApiClient.baseUrl,
  );
  final DashboardViewModel _vm = DashboardViewModel();

  final _nameCtrl = TextEditingController();
  final _weightCtrl = TextEditingController();
  final _heightCtrl = TextEditingController();
  String? _selectedGoal;

  bool _isProfileLoading = false;
  bool _isSaving = false;

  ComparativeStatsModel? _comparativeStats;
  bool _isStatsLoading = false;
  String _statsPeriod = 'monthly';

  bool _isBadgesLoading = false;
  List<UserBadgeEntry> _unlockedBadges = [];

  @override
  void initState() {
    super.initState();
    _lastRefreshTick = widget.refreshTick;
    _loadProfileSettings();
    _loadComparativeStats();
    _loadUnlockedBadges();
  }

  @override
  void didUpdateWidget(covariant ProfileScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.refreshTick != _lastRefreshTick) {
      _lastRefreshTick = widget.refreshTick;
      _loadProfileSettings();
      _loadUnlockedBadges();
    }
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
        _nameCtrl.text = profile.name;
        _weightCtrl.text = profile.weight?.toStringAsFixed(1) ?? '';
        _heightCtrl.text = profile.height?.toStringAsFixed(1) ?? '';
        _selectedGoal = profile.trainingGoal;
        _isProfileLoading = false;
      });
      if (_role == 'athlete') {
        await _vm.loadAthleteDashboard();
      } else if (_role == 'coach') {
        await _vm.loadCoachDashboard();
      }
      if (mounted) setState(() {});
    } catch (_) {
      final fallbackName = await TokenStorage.getUserName();
      final fallbackRole = await TokenStorage.getUserRole();
      if (!mounted) return;
      setState(() {
        _userName = fallbackName ?? 'Usuario';
        _role = fallbackRole ?? 'athlete';
        _nameCtrl.text = _userName;
        _isProfileLoading = false;
      });
    }
  }

  Future<void> _loadComparativeStats() async {
    setState(() => _isStatsLoading = true);
    try {
      final stats = await _profileRepository.getComparativeStats(
        period: _statsPeriod,
      );
      if (mounted) {
        setState(() {
          _comparativeStats = stats;
          _isStatsLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isStatsLoading = false);
      }
    }
  }

  Future<void> _loadUnlockedBadges() async {
    setState(() => _isBadgesLoading = true);
    try {
      final summary = await _badgeRepository.fetchUserBadgeSummary();
      if (!mounted) return;
      setState(() {
        _unlockedBadges = summary.unlockedBadges;
        _isBadgesLoading = false;
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _unlockedBadges = [];
          _isBadgesLoading = false;
        });
      }
    }
  }

  String _badgeAssetPath(BadgeDefinition badge) {
    return 'assets/images/badges/svg/${badge.svgFilename}';
  }

  Widget _buildUnlockedBadgesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '🏅 Mis Insignias',
          style: AppTextStyles.fitnessBold.copyWith(
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        if (_isBadgesLoading)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(18),
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
          )
        else if (_unlockedBadges.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: AppRadius.card,
              boxShadow: AppColors.softShadow,
            ),
            child: const Text(
              'Todavía no tienes insignias desbloqueadas.',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          )
        else
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _unlockedBadges.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.02,
            ),
            itemBuilder: (context, index) {
              final badge = _unlockedBadges[index].badge;
              return Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: AppRadius.card,
                  boxShadow: AppColors.softShadow,
                ),
                child: Center(
                  child: SvgPicture.asset(
                    _badgeAssetPath(badge),
                    fit: BoxFit.contain,
                  ),
                ),
              );
            },
          ),
      ],
    );
  }

  Future<void> _saveProfileSettings() async {
    final name = _nameCtrl.text.trim();
    final weight = double.tryParse(_weightCtrl.text.trim());
    final height = double.tryParse(_heightCtrl.text.trim());

    if (name.isEmpty ||
        weight == null ||
        height == null ||
        _selectedGoal == null) {
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
        _selectedGoal = updated.trainingGoal;
        _nameCtrl.text = updated.name;
        _weightCtrl.text = updated.weight?.toStringAsFixed(1) ?? '';
        _heightCtrl.text = updated.height?.toStringAsFixed(1) ?? '';
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
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  void _openGoalsDialog() {
    showDialog(
      context: context,
      builder: (_) => _GoalsDialog(
        repository: _vm.repository,
        onChanged: () async {
          await _vm.loadAthleteDashboard();
          if (mounted) setState(() {});
        },
      ),
    );
  }

  void _openWeightDialog() {
    showDialog(
      context: context,
      builder: (_) => _WeightLogDialog(
        repository: _vm.repository,
        onChanged: () async {
          await _vm.loadAthleteDashboard();
          if (mounted) setState(() {});
        },
      ),
    );
  }

  void _openSettingsSheet() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
          ),
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
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildInputField(
                    controller: _heightCtrl,
                    label: 'Altura (cm)',
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
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
                        const Icon(
                          Icons.cake_rounded,
                          color: AppColors.primary,
                        ),
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
    final followersCount = _role == 'athlete'
        ? (_vm.athleteDashboard?.followersCount ?? 0)
        : (_vm.coachDashboard?.followersCount ?? 0);
    final followingCount = _role == 'athlete'
        ? (_vm.athleteDashboard?.followingCount ?? 0)
        : (_vm.coachDashboard?.followingCount ?? 0);

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
                            backgroundColor: Colors.white.withValues(
                              alpha: 0.3,
                            ),
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
                            _role == 'coach' ? 'Entrenador' : 'Atleta',
                            style: const TextStyle(
                              fontSize: 13,
                              color: Colors.white70,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 18),
                          Center(
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 330),
                              child: _buildFollowersFollowingSection(
                                followersCount: followersCount,
                                followingCount: followingCount,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (_role == 'athlete') _buildAthleteProfile(),
                          if (_role == 'coach') _buildCoachProfile(),
                          const SizedBox(height: 24),
                          Text(
                            '⚙️ Configuración',
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
                            icon: Icons.alarm_rounded,
                            label: 'Recordatorios',
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => RemindersScreen(
                                    onReminderSaved: widget.onReminderSaved,
                                  ),
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 14),
                          _buildOption(
                            icon: Icons.logout,
                            label: 'Cerrar sesion',
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        Text(
          '📈 Tus datos',
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
                    ? (_height! < 10
                          ? '${_height!.toStringAsFixed(2)} m'
                          : '${_height!.toStringAsFixed(0)} cm')
                    : 'Sin dato',
                icon: Icons.height_rounded,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _ProfileStatCard(
                label: 'Actividad',
                value: d != null ? _mapActivity(d.activityLevel) : 'Sin dato',
                icon: Icons.bolt_rounded,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '🎯 Mi objetivo',
              style: AppTextStyles.fitnessBold.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
            GestureDetector(
              onTap: _openGoalsDialog,
              child: Text(
                'Ver metas',
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: _openGoalsDialog,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: AppRadius.card,
              boxShadow: AppColors.softShadow,
            ),
            child: d?.goal == null
                ? Row(
                    children: [
                      Icon(
                        Icons.flag_rounded,
                        color: AppColors.primary,
                        size: 20,
                      ),
                      const SizedBox(width: 14),
                      const Expanded(
                        child: Text(
                          'Sin objetivo activo',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      const Icon(
                        Icons.chevron_right,
                        color: AppColors.textSecondary,
                      ),
                    ],
                  )
                : Row(
                    children: [
                      Icon(
                        Icons.flag_rounded,
                        color: AppColors.primary,
                        size: 20,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _goalLabel(d!.goal!.goalType),
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            if (d.goal!.targetValue != null) ...[
                              const SizedBox(height: 2),
                              Text(
                                'Objetivo: ${d.goal!.targetValue}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                            if (d.goal!.deadline != null) ...[
                              const SizedBox(height: 2),
                              Text(
                                'Fecha límite: ${d.goal!.deadline}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.chevron_right,
                        color: AppColors.textSecondary,
                      ),
                    ],
                  ),
          ),
        ),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: _openWeightDialog,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: AppRadius.card,
              boxShadow: AppColors.softShadow,
            ),
            child: Row(
              children: [
                Icon(
                  Icons.monitor_weight_rounded,
                  color: AppColors.primary,
                  size: 20,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        d?.latestWeight != null
                            ? '${d!.latestWeight!.weight} kg'
                            : 'Sin registros de peso',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      if (d?.latestWeight != null)
                        Text(
                          d!.latestWeight!.date,
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                          ),
                        ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: AppColors.textSecondary),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        _buildComparativeStats(),
        const SizedBox(height: 24),
        _buildUnlockedBadgesSection(),
      ],
    );
  }

  Widget _buildComparativeStats() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '📊 Progreso',
              style: AppTextStyles.fitnessBold.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
            DropdownButton<String>(
              value: _statsPeriod,
              dropdownColor: AppColors.surface,
              style: const TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
              underline: const SizedBox(),
              icon: const Icon(Icons.arrow_drop_down, color: AppColors.primary),
              items: const [
                DropdownMenuItem(value: 'monthly', child: Text('Mensual')),
                DropdownMenuItem(value: 'quarterly', child: Text('Trimestral')),
              ],
              onChanged: (val) {
                if (val != null) {
                  setState(() {
                    _statsPeriod = val;
                  });
                  _loadComparativeStats();
                }
              },
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_isStatsLoading)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
          )
        else if (_comparativeStats == null)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: AppRadius.card,
              boxShadow: AppColors.softShadow,
            ),
            child: const Text(
              'No se pudieron cargar las estadísticas',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          )
        else
          Column(
            children: [
              _buildStatComparativeRow(
                title: 'Entrenamientos',
                icon: Icons.fitness_center_rounded,
                stat: _comparativeStats!.workouts,
                unit: 'sesiones',
                invertColors: false,
              ),
              const SizedBox(height: 8),
              _buildStatComparativeRow(
                title: 'Calorías Diarias',
                icon: Icons.local_fire_department_rounded,
                stat: _comparativeStats!.caloriesDailyAvg,
                unit: 'kcal',
                invertColors: true,
              ),
              const SizedBox(height: 8),
              _buildStatComparativeRow(
                title: 'Peso Promedio',
                icon: Icons.monitor_weight_rounded,
                stat: _comparativeStats!.weightAvg,
                unit: 'kg',
                invertColors: true,
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildStatComparativeRow({
    required String title,
    required IconData icon,
    required StatItem stat,
    required String unit,
    required bool invertColors,
  }) {
    final change = stat.changePercentage;
    final isZero = change == 0;
    final isIncrease = change > 0;

    Color changeColor = Colors.grey;
    IconData changeIcon = Icons.remove_rounded;

    if (!isZero) {
      if (isIncrease) {
        changeColor = invertColors ? AppColors.error : AppColors.success;
        changeIcon = Icons.arrow_upward_rounded;
      } else {
        changeColor = invertColors ? AppColors.success : AppColors.error;
        changeIcon = Icons.arrow_downward_rounded;
      }
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.card,
        boxShadow: AppColors.softShadow,
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: AppColors.primary, size: 20),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${stat.current} $unit',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      'Anterior: ${stat.previous} $unit',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: changeColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(changeIcon, color: changeColor, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      '${change.abs().toStringAsFixed(1)}%',
                      style: TextStyle(
                        color: changeColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: stat.current > 0 || stat.previous > 0
                  ? (stat.current /
                        ((stat.current > stat.previous
                                    ? stat.current
                                    : stat.previous) ==
                                0
                            ? 1
                            : (stat.current > stat.previous
                                  ? stat.current
                                  : stat.previous)))
                  : 0.0,
              backgroundColor: AppColors.border,
              valueColor: AlwaysStoppedAnimation<Color>(changeColor),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }

  // ── Perfil Coach ───────────────────────────────────────────────────────────

  Widget _buildCoachProfile() {
    final d = _vm.coachDashboard;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '📈 Tus datos',
          style: AppTextStyles.fitnessBold.copyWith(
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _ProfileStatCard(
                label: 'Especialidad',
                value: d != null ? _mapSpeciality(d.speciality) : 'Sin dato',
                icon: Icons.workspace_premium_rounded,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _ProfileStatCard(
                label: 'Experiencia',
                value: d != null ? '${d.yearsExperience} años' : 'Sin dato',
                icon: Icons.history_toggle_off_rounded,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Text(
          '👥 Mis grupos',
          style: AppTextStyles.fitnessBold.copyWith(
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const MyGroupsScreen()),
          ),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              borderRadius: AppRadius.card,
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.group_rounded,
                    color: AppColors.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        d == null || d.groups.isEmpty
                            ? 'Sin grupos creados'
                            : '${d.groups.length} equipo${d.groups.length == 1 ? '' : 's'}',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      if (d != null && d.groups.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          'Toca para gestionar',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.primary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: AppColors.primary),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ── Widgets compartidos ────────────────────────────────────────────────────

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

  Widget _buildFollowersFollowingSection({
    required int followersCount,
    required int followingCount,
  }) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildFollowStatItem(
              icon: Icons.groups_rounded,
              label: 'Seguidores',
              value: followersCount.toString(),
            ),
          ),
          Container(
            width: 1,
            height: 48,
            color: Colors.white.withValues(alpha: 0.22),
          ),
          Expanded(
            child: _buildFollowStatItem(
              icon: Icons.person_add_alt_1_rounded,
              label: 'Siguiendo',
              value: followingCount.toString(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFollowStatItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.white, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Colors.white70,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 20,
                    height: 1,
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
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

// ── Widgets externos ───────────────────────────────────────────────────────

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
          Text(label, style: AppTextStyles.cardSubtitle),
        ],
      ),
    );
  }
}

// ── Weight Log Dialog ──────────────────────────────────────────────────────

class _WeightLogDialog extends StatefulWidget {
  final DashboardRepository repository;
  final VoidCallback onChanged;

  const _WeightLogDialog({required this.repository, required this.onChanged});

  @override
  State<_WeightLogDialog> createState() => _WeightLogDialogState();
}

class _WeightLogDialogState extends State<_WeightLogDialog> {
  List<WeightLogModel> _logs = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadLogs();
  }

  Future<void> _loadLogs() async {
    setState(() => _isLoading = true);
    try {
      final data = await widget.repository.getWeightLogs();
      if (mounted) setState(() => _logs = data);
    } catch (e) {
      debugPrint('ERROR cargando pesos: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _openForm() {
    showDialog(
      context: context,
      builder: (_) => _WeightFormDialog(
        repository: widget.repository,
        onSaved: () {
          _loadLogs();
          widget.onChanged();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      child: SizedBox(
        width: double.infinity,
        height: 520,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 12, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Historial de peso',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const Divider(),
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primary,
                      ),
                    )
                  : _logs.isEmpty
                  ? const Center(child: Text('Sin registros de peso'))
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _logs.length,
                      itemBuilder: (context, index) {
                        final log = _logs[index];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: AppColors.softShadow,
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(7),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(
                                    alpha: 0.15,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.monitor_weight_rounded,
                                  color: AppColors.primary,
                                  size: 18,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${log.weight} kg',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 14,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                    Text(
                                      log.date,
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                    if (log.bodyFat != null)
                                      Text(
                                        'Grasa: ${log.bodyFat}%',
                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _openForm,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                  ),
                  icon: const Icon(Icons.add),
                  label: const Text('Registrar peso'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Weight Form Dialog ─────────────────────────────────────────────────────

class _WeightFormDialog extends StatefulWidget {
  final DashboardRepository repository;
  final VoidCallback onSaved;

  const _WeightFormDialog({required this.repository, required this.onSaved});

  @override
  State<_WeightFormDialog> createState() => _WeightFormDialogState();
}

class _WeightFormDialogState extends State<_WeightFormDialog> {
  final _weightCtrl = TextEditingController();
  final _bodyFatCtrl = TextEditingController();
  String? _selectedDate;
  bool _isSaving = false;

  @override
  void dispose() {
    _weightCtrl.dispose();
    _bodyFatCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(primary: AppColors.primary),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        _selectedDate =
            '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
      });
    }
  }

  Future<void> _save() async {
    final weight = double.tryParse(_weightCtrl.text.trim());
    if (weight == null || weight <= 0) return;

    setState(() => _isSaving = true);
    try {
      await widget.repository.addWeightLog(
        weight,
        bodyFat: double.tryParse(_bodyFatCtrl.text.trim()),
        date: _selectedDate,
      );
      widget.onSaved();
      if (mounted) Navigator.pop(context);
    } catch (e) {
      debugPrint('ERROR guardando peso: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Error al guardar peso')));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  InputDecoration _inputDec(String label, {IconData? icon}) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: AppColors.primary),
      prefixIcon: icon != null ? Icon(icon, color: AppColors.primary) : null,
      filled: true,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Registrar peso',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _weightCtrl,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: _inputDec(
                'Peso (kg)',
                icon: Icons.monitor_weight_rounded,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _bodyFatCtrl,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: _inputDec(
                '% Grasa corporal (opcional)',
                icon: Icons.percent,
              ),
            ),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: _pickDate,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _selectedDate != null
                        ? AppColors.primary
                        : Colors.transparent,
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.calendar_today,
                      color: AppColors.primary,
                      size: 18,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      _selectedDate ?? 'Seleccionar fecha (opcional)',
                      style: TextStyle(
                        color: _selectedDate != null
                            ? AppColors.textPrimary
                            : AppColors.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _isSaving ? null : _save,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                ),
                child: _isSaving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Guardar'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Goals Dialog ───────────────────────────────────────────────────────────

class _GoalsDialog extends StatefulWidget {
  final DashboardRepository repository;
  final VoidCallback onChanged;

  const _GoalsDialog({required this.repository, required this.onChanged});

  @override
  State<_GoalsDialog> createState() => _GoalsDialogState();
}

class _GoalsDialogState extends State<_GoalsDialog> {
  List<GoalModel> _goals = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadGoals();
  }

  Future<void> _loadGoals() async {
    setState(() => _isLoading = true);
    try {
      final data = await widget.repository.getGoals();
      if (mounted) setState(() => _goals = data);
    } catch (e) {
      debugPrint('ERROR cargando metas: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _openForm({GoalModel? goal}) {
    showDialog(
      context: context,
      builder: (_) => _GoalFormDialog(
        repository: widget.repository,
        goal: goal,
        onSaved: () {
          _loadGoals();
          widget.onChanged();
        },
      ),
    );
  }

  Future<void> _deleteGoal(GoalModel goal) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Eliminar meta'),
        content: Text('¿Eliminar "${_goalLabel(goal.goalType)}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text(
              'Eliminar',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await widget.repository.deleteGoal(goal.id);
      _loadGoals();
      widget.onChanged();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      child: SizedBox(
        width: double.infinity,
        height: 520,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 12, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Mis metas',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const Divider(),
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primary,
                      ),
                    )
                  : _goals.isEmpty
                  ? const Center(child: Text('Sin metas registradas'))
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _goals.length,
                      itemBuilder: (context, index) {
                        final goal = _goals[index];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.07),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(7),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(
                                    alpha: 0.15,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.flag_rounded,
                                  color: AppColors.primary,
                                  size: 18,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _goalLabel(goal.goalType),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 14,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                    if (goal.targetValue != null)
                                      Text(
                                        'Objetivo: ${goal.targetValue}',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                    if (goal.deadline != null)
                                      Text(
                                        'Fecha límite: ${goal.deadline}',
                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.edit_outlined,
                                  color: AppColors.primary,
                                  size: 20,
                                ),
                                onPressed: () => _openForm(goal: goal),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.delete_outline,
                                  color: Colors.red,
                                  size: 20,
                                ),
                                onPressed: () => _deleteGoal(goal),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () => _openForm(),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                  ),
                  icon: const Icon(Icons.add),
                  label: const Text('Nueva meta'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Goal Form Dialog ───────────────────────────────────────────────────────

class _GoalFormDialog extends StatefulWidget {
  final DashboardRepository repository;
  final GoalModel? goal;
  final VoidCallback onSaved;

  const _GoalFormDialog({
    required this.repository,
    this.goal,
    required this.onSaved,
  });

  @override
  State<_GoalFormDialog> createState() => _GoalFormDialogState();
}

class _GoalFormDialogState extends State<_GoalFormDialog> {
  final _targetCtrl = TextEditingController();
  final _currentCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  String? _selectedGoalType;
  String? _selectedDeadline;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    if (widget.goal != null) {
      final g = widget.goal!;
      _selectedGoalType = g.goalType;
      _targetCtrl.text = g.targetValue?.toString() ?? '';
      _currentCtrl.text = g.currentValue?.toString() ?? '';
      _descCtrl.text = g.description;
      _selectedDeadline = g.deadline;
    }
  }

  @override
  void dispose() {
    _targetCtrl.dispose();
    _currentCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_selectedGoalType == null) return;
    setState(() => _isSaving = true);
    try {
      if (widget.goal == null) {
        await widget.repository.createGoal(
          goalType: _selectedGoalType!,
          description: _descCtrl.text.trim(),
          targetValue: double.tryParse(_targetCtrl.text),
          currentValue: double.tryParse(_currentCtrl.text),
          deadline: _selectedDeadline,
        );
      } else {
        await widget.repository.updateGoal(
          widget.goal!.id,
          goalType: _selectedGoalType,
          description: _descCtrl.text.trim(),
          targetValue: double.tryParse(_targetCtrl.text),
          currentValue: double.tryParse(_currentCtrl.text),
          deadline: _selectedDeadline,
        );
      }
      widget.onSaved();
      if (mounted) Navigator.pop(context);
    } catch (e) {
      debugPrint('ERROR guardando meta: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Error al guardar meta')));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _pickDeadline() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime.now(),
      lastDate: DateTime(2030),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(primary: AppColors.primary),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        _selectedDeadline =
            '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
      });
    }
  }

  InputDecoration _inputDec(String label, {IconData? icon}) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: AppColors.primary),
      prefixIcon: icon != null ? Icon(icon, color: AppColors.primary) : null,
      filled: true,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    widget.goal == null ? 'Nueva meta' : 'Editar meta',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _selectedGoalType,
              decoration: _inputDec(
                'Tipo de objetivo',
                icon: Icons.flag_rounded,
              ),
              items: _goalOptions
                  .map(
                    (g) =>
                        DropdownMenuItem(value: g.value, child: Text(g.label)),
                  )
                  .toList(),
              onChanged: (v) => setState(() => _selectedGoalType = v),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _targetCtrl,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: _inputDec(
                'Valor objetivo (ej: 70 kg)',
                icon: Icons.track_changes,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _currentCtrl,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: _inputDec('Valor actual', icon: Icons.trending_up),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descCtrl,
              decoration: _inputDec(
                'Descripción (opcional)',
                icon: Icons.notes,
              ),
            ),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: _pickDeadline,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _selectedDeadline != null
                        ? AppColors.primary
                        : Colors.transparent,
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.calendar_today,
                      color: AppColors.primary,
                      size: 18,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      _selectedDeadline ?? 'Seleccionar fecha límite',
                      style: TextStyle(
                        color: _selectedDeadline != null
                            ? AppColors.textPrimary
                            : AppColors.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _isSaving || _selectedGoalType == null
                    ? null
                    : _save,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                ),
                child: _isSaving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        widget.goal == null ? 'Crear meta' : 'Guardar cambios',
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Helpers ────────────────────────────────────────────────────────────────

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
