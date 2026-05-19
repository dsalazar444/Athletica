import 'package:flutter/material.dart';
import '../../core/api_client.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';

class AthleteStatsScreen extends StatefulWidget {
  final int athleteId;
  final String athleteName;

  const AthleteStatsScreen({
    super.key,
    required this.athleteId,
    required this.athleteName,
  });

  @override
  State<AthleteStatsScreen> createState() => _AthleteStatsScreenState();
}

class _AthleteStatsScreenState extends State<AthleteStatsScreen> {
  bool _isLoading = true;
  String? _error;
  Map<String, dynamic>? _stats;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final response = await ApiClient.dio.get(
        'coach/athletes/${widget.athleteId}/stats/',
      );
      setState(() => _stats = response.data as Map<String, dynamic>);
    } catch (e) {
      setState(() => _error = 'No se pudieron cargar las estadísticas.');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_rounded,
            color: AppColors.textPrimary,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.athleteName.toUpperCase(),
              style: AppTextStyles.fitnessBold.copyWith(fontSize: 14),
            ),
            Text(
              'REPORTE DE PROGRESO',
              style: AppTextStyles.fitnessCaption.copyWith(fontSize: 10),
            ),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : _error != null
          ? _buildError()
          : _buildContent(),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline_rounded,
            size: 64,
            color: AppColors.error.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(_error!, style: const TextStyle(color: AppColors.textSecondary)),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _loadStats,
            style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    final summary = _stats!['summary'] as Map<String, dynamic>;
    final weeklySessions = _stats!['weekly_sessions'] as List<dynamic>;
    final weightHistory = _stats!['weight_history'] as List<dynamic>;
    final activeGoal = _stats!['active_goal'] as Map<String, dynamic>?;

    return RefreshIndicator(
      onRefresh: _loadStats,
      color: AppColors.primary,
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        children: [
          _buildSummaryRow(summary),
          const SizedBox(height: 20),
          _buildVolumeCard(summary),
          const SizedBox(height: 20),
          _buildWeeklyChart(weeklySessions),
          const SizedBox(height: 20),
          if (weightHistory.isNotEmpty) ...[
            _buildWeightChart(weightHistory),
            const SizedBox(height: 20),
          ],
          if (activeGoal != null) ...[
            _buildGoalCard(activeGoal),
            const SizedBox(height: 20),
          ],
          const SizedBox(height: 60),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(Map<String, dynamic> summary) {
    final current = summary['current_month_sessions'] as int? ?? 0;
    final prev = summary['prev_month_sessions'] as int? ?? 0;
    final changePct = summary['session_change_pct'] as int?;

    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            label: 'ESTE MES',
            value: '$current',
            unit: 'sesiones',
            icon: Icons.fitness_center_rounded,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            label: 'MES ANTERIOR',
            value: '$prev',
            unit: 'sesiones',
            icon: Icons.history_rounded,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            label: 'CAMBIO',
            value: changePct == null
                ? '--'
                : '${changePct > 0 ? '+' : ''}$changePct%',
            unit: 'vs anterior',
            icon: changePct == null
                ? Icons.remove_rounded
                : changePct >= 0
                ? Icons.trending_up_rounded
                : Icons.trending_down_rounded,
            color: changePct == null
                ? AppColors.textHint
                : changePct >= 0
                ? AppColors.success
                : AppColors.error,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String label,
    required String value,
    required String unit,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 8),
          Text(
            value,
            style: AppTextStyles.fitnessBold.copyWith(
              fontSize: 22,
              color: color,
            ),
          ),
          Text(
            unit,
            style: AppTextStyles.fitnessCaption.copyWith(fontSize: 10),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: AppTextStyles.fitnessCaption.copyWith(fontSize: 9),
          ),
        ],
      ),
    );
  }

  Widget _buildVolumeCard(Map<String, dynamic> summary) {
    final upper = (summary['upper_body_volume_kg'] as num?)?.toDouble() ?? 0.0;
    final lower = (summary['lower_body_volume_kg'] as num?)?.toDouble() ?? 0.0;
    final total = upper + lower;
    final upperPct = total > 0 ? upper / total : 0.5;
    final lowerPct = total > 0 ? lower / total : 0.5;

    return _buildSectionCard(
      title: 'VOLUMEN DE ENTRENAMIENTO',
      subtitle: 'Últimos 30 días',
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildVolumeBar(
                  label: 'TREN SUPERIOR',
                  kg: upper,
                  fraction: upperPct.toDouble(),
                  color: AppColors.primary,
                  icon: Icons.sports_handball_rounded,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildVolumeBar(
                  label: 'TREN INFERIOR',
                  kg: lower,
                  fraction: lowerPct.toDouble(),
                  color: const Color(0xFF4C6EF5),
                  icon: Icons.directions_run_rounded,
                ),
              ),
            ],
          ),
          if (total == 0)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                'Sin datos de volumen registrados.',
                style: AppTextStyles.fitnessCaption,
                textAlign: TextAlign.center,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildVolumeBar({
    required String label,
    required double kg,
    required double fraction,
    required Color color,
    required IconData icon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                style: AppTextStyles.fitnessCaption.copyWith(fontSize: 10),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(100),
          child: LinearProgressIndicator(
            value: fraction.clamp(0.0, 1.0),
            minHeight: 10,
            backgroundColor: color.withValues(alpha: 0.15),
            valueColor: AlwaysStoppedAnimation(color),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          '${kg.toStringAsFixed(1)} kg',
          style: AppTextStyles.fitnessBold.copyWith(fontSize: 14, color: color),
        ),
      ],
    );
  }

  Widget _buildWeeklyChart(List<dynamic> weeklySessions) {
    if (weeklySessions.isEmpty) return const SizedBox.shrink();

    final counts = weeklySessions
        .map((w) => (w['count'] as int?) ?? 0)
        .toList();
    final maxCount = counts.reduce((a, b) => a > b ? a : b);
    final effectiveMax = maxCount == 0 ? 1 : maxCount;

    return _buildSectionCard(
      title: 'SESIONES SEMANALES',
      subtitle: 'Últimas 8 semanas',
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(weeklySessions.length, (i) {
          final week = weeklySessions[i];
          final count = (week['count'] as int?) ?? 0;
          final fraction = count / effectiveMax;
          final weekLabel = _shortWeekLabel(
            week['week_start'] as String? ?? '',
          );
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: Column(
                children: [
                  Text(
                    '$count',
                    style: AppTextStyles.fitnessBold.copyWith(
                      fontSize: 10,
                      color: count > 0 ? AppColors.primary : AppColors.textHint,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    height: 80 * fraction + 4,
                    decoration: BoxDecoration(
                      color: count > 0
                          ? AppColors.primary.withValues(
                              alpha: 0.7 + 0.3 * fraction,
                            )
                          : AppColors.border,
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    weekLabel,
                    style: AppTextStyles.fitnessCaption.copyWith(fontSize: 9),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  String _shortWeekLabel(String isoDate) {
    if (isoDate.length < 10) return '';
    final parts = isoDate.split('-');
    if (parts.length < 3) return '';
    final month = int.tryParse(parts[1]) ?? 0;
    final day = int.tryParse(parts[2]) ?? 0;
    const months = [
      '',
      'En',
      'Fe',
      'Ma',
      'Ab',
      'My',
      'Jn',
      'Jl',
      'Ag',
      'Se',
      'Oc',
      'No',
      'Di',
    ];
    return '${months[month]}\n$day';
  }

  Widget _buildWeightChart(List<dynamic> weightHistory) {
    final weights = weightHistory
        .map((w) => (w['weight'] as num?)?.toDouble() ?? 0.0)
        .toList();
    final minW = weights.reduce((a, b) => a < b ? a : b);
    final maxW = weights.reduce((a, b) => a > b ? a : b);
    final range = maxW - minW;

    return _buildSectionCard(
      title: 'HISTORIAL DE PESO',
      subtitle: 'Últimas entradas',
      child: Column(
        children: [
          SizedBox(
            height: 100,
            child: CustomPaint(
              painter: _WeightLinePainter(
                weights: weights,
                minWeight: minW,
                range: range == 0 ? 1 : range,
                color: AppColors.primary,
              ),
              child: const SizedBox.expand(),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Mín: ${minW.toStringAsFixed(1)} kg',
                style: AppTextStyles.fitnessCaption.copyWith(fontSize: 10),
              ),
              Text(
                'Último: ${weights.last.toStringAsFixed(1)} kg',
                style: AppTextStyles.fitnessBold.copyWith(
                  fontSize: 12,
                  color: AppColors.primary,
                ),
              ),
              Text(
                'Máx: ${maxW.toStringAsFixed(1)} kg',
                style: AppTextStyles.fitnessCaption.copyWith(fontSize: 10),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGoalCard(Map<String, dynamic> goal) {
    final description = goal['description'] as String? ?? '';
    final targetDate = goal['target_date'] as String?;

    return _buildSectionCard(
      title: 'META ACTIVA',
      subtitle: 'Objetivo en progreso',
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.flag_rounded,
              color: AppColors.primary,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  description,
                  style: AppTextStyles.fitnessBold.copyWith(fontSize: 13),
                ),
                if (targetDate != null)
                  Text(
                    'Hasta: $targetDate',
                    style: AppTextStyles.fitnessCaption.copyWith(fontSize: 11),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required String subtitle,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTextStyles.fitnessBold.copyWith(fontSize: 12)),
          Text(
            subtitle,
            style: AppTextStyles.fitnessCaption.copyWith(fontSize: 10),
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _WeightLinePainter extends CustomPainter {
  final List<double> weights;
  final double minWeight;
  final double range;
  final Color color;

  _WeightLinePainter({
    required this.weights,
    required this.minWeight,
    required this.range,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (weights.length < 2) return;

    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final dotPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final fillPaint = Paint()
      ..color = color.withValues(alpha: 0.1)
      ..style = PaintingStyle.fill;

    final step = size.width / (weights.length - 1);

    Offset pointAt(int i) {
      final x = i * step;
      final y =
          size.height -
          ((weights[i] - minWeight) / range) * (size.height * 0.85) -
          4;
      return Offset(x, y);
    }

    final fillPath = Path();
    fillPath.moveTo(0, size.height);
    fillPath.lineTo(pointAt(0).dx, pointAt(0).dy);
    for (int i = 1; i < weights.length; i++) {
      fillPath.lineTo(pointAt(i).dx, pointAt(i).dy);
    }
    fillPath.lineTo(size.width, size.height);
    fillPath.close();
    canvas.drawPath(fillPath, fillPaint);

    final path = Path();
    path.moveTo(pointAt(0).dx, pointAt(0).dy);
    for (int i = 1; i < weights.length; i++) {
      path.lineTo(pointAt(i).dx, pointAt(i).dy);
    }
    canvas.drawPath(path, paint);

    for (int i = 0; i < weights.length; i++) {
      canvas.drawCircle(pointAt(i), 4, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _WeightLinePainter old) =>
      old.weights != weights ||
      old.minWeight != minWeight ||
      old.range != range;
}
