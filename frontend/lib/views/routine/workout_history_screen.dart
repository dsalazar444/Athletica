import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/config/api_config.dart';
import '../../repositories/routine/workout_repository.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_text_styles.dart';
import '../../view_models/routine/workout_history_view_model.dart';

/// Pantalla para consultar el historial completo de entrenamientos por rango de fechas.
class WorkoutHistoryScreen extends StatefulWidget {
  const WorkoutHistoryScreen({super.key});

  @override
  State<WorkoutHistoryScreen> createState() => _WorkoutHistoryScreenState();
}

class _WorkoutHistoryScreenState extends State<WorkoutHistoryScreen> {
  late final WorkoutHistoryViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = WorkoutHistoryViewModel(
      workoutRepository: WorkoutRepository(baseUrl: ApiConfig.baseUrl),
    );
    _viewModel.init();
  }

  Future<void> _pickRange(BuildContext context) async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _viewModel.selectedRange,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      await _viewModel.setDateRange(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<WorkoutHistoryViewModel>.value(
      value: _viewModel,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text(
            'Historial de entrenamientos',
            style: AppTextStyles.h3,
          ),
          actions: [
            TextButton.icon(
              onPressed: () => _pickRange(context),
              icon: const Icon(
                Icons.date_range,
                size: 18,
                color: AppColors.primary,
              ),
              label: Consumer<WorkoutHistoryViewModel>(
                builder: (context, vm, _) {
                  final formatter = DateFormat('d MMM');
                  return Text(
                    '${formatter.format(vm.selectedRange.start)} - ${formatter.format(vm.selectedRange.end)}',
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  );
                },
              ),
            ),
          ],
        ),
        body: Consumer<WorkoutHistoryViewModel>(
          builder: (context, vm, _) {
            if (vm.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (vm.errorMessage != null) {
              return _ErrorState(
                message: vm.errorMessage!,
                onRetry: () => vm.loadHistory(reset: true),
              );
            }

            if (vm.sessions.isEmpty) {
              return const _EmptyState();
            }

            return NotificationListener<ScrollNotification>(
              onNotification: (notification) {
                final threshold = notification.metrics.maxScrollExtent * 0.85;
                if (notification.metrics.pixels >= threshold) {
                  vm.loadNextPage();
                }
                return false;
              },
              child: RefreshIndicator(
                onRefresh: () => vm.loadHistory(reset: true),
                child: ListView.builder(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  itemCount: vm.sessions.length + (vm.isLoadingMore ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index >= vm.sessions.length) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }

                    final session = vm.sessions[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: AppRadius.card,
                        border: Border.all(
                          color: AppColors.border.withValues(alpha: 0.5),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.03),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        leading: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.event_available,
                            color: AppColors.primary,
                          ),
                        ),
                        title: Text(
                          session.routineTitle,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            DateFormat(
                              'EEEE, d MMM yyyy • HH:mm',
                              'es_ES',
                            ).format(session.date.toLocal()),
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.history_toggle_off, size: 52, color: AppColors.textHint),
            SizedBox(height: 12),
            Text(
              'No hay entrenamientos en este rango de fechas.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 15, color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppColors.error),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 14),
            ElevatedButton(
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              child: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }
}
