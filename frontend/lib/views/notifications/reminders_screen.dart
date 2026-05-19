import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../../models/notification/reminder_model.dart';
import '../../repositories/notification/reminder_service.dart';
import '../../theme/app_colors.dart';

class RemindersScreen extends StatefulWidget {
  final VoidCallback? onReminderSaved;

  const RemindersScreen({super.key, this.onReminderSaved});

  @override
  State<RemindersScreen> createState() => _RemindersScreenState();
}

class _RemindersScreenState extends State<RemindersScreen> {
  final ReminderService _service = ReminderService();
  List<ReminderModel> _reminders = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadReminders();
  }

  Future<void> _loadReminders() async {
    setState(() => _isLoading = true);
    try {
      final reminders = await _service.getReminders();
      if (!mounted) return;
      setState(() {
        _reminders = reminders;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showMessage('No se pudieron cargar los recordatorios.');
    }
  }

  Future<void> _deleteReminder(ReminderModel reminder) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Eliminar recordatorio'),
        content: const Text('¿Deseas eliminar este recordatorio?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await _service.deleteReminder(reminder.id);
      _showMessage('Recordatorio eliminado.');
      _loadReminders();
    } catch (_) {
      _showMessage('No se pudo eliminar el recordatorio.');
    }
  }

  Future<void> _openReminderForm({ReminderModel? reminder}) async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ReminderFormSheet(
        reminder: reminder,
        service: _service,
        onReminderSaved: widget.onReminderSaved,
      ),
    );

    if (saved == true) {
      _loadReminders();
    }
  }

  void _showMessage(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  String _activityLabel(String type) {
    switch (type) {
      case 'training':
        return 'Entrenamiento';
      case 'nutrition':
        return 'Registro de alimentación';
      default:
        return type;
    }
  }

  String _recurrenceLabel(String recurrence) {
    switch (recurrence) {
      case 'none':
        return 'Una sola vez';
      case 'daily':
        return 'Diariamente';
      case 'weekly':
        return 'Semanalmente';
      case 'biweekly':
        return 'Cada 2 semanas';
      case 'monthly':
        return 'Mensualmente';
      default:
        return recurrence;
    }
  }

  String _formatDate(DateTime date) {
    final d =
        '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    final t =
        '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    return '$d • $t';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Recordatorios'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : _reminders.isEmpty
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'No tienes recordatorios configurados.',
                  textAlign: TextAlign.center,
                ),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _reminders.length,
              itemBuilder: (context, index) {
                final reminder = _reminders[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    leading: Icon(
                      reminder.activityType == 'training'
                          ? Icons.fitness_center_rounded
                          : Icons.restaurant_rounded,
                      color: AppColors.primary,
                    ),
                    title: Text(
                      _activityLabel(reminder.activityType),
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    subtitle: Text(
                      '${_formatDate(reminder.remindAt)} • ${_recurrenceLabel(reminder.recurrence)}',
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit_outlined),
                          onPressed: () =>
                              _openReminderForm(reminder: reminder),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () => _deleteReminder(reminder),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openReminderForm(),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_alert_rounded),
        label: const Text('Nuevo recordatorio'),
      ),
    );
  }
}

class _ReminderFormSheet extends StatefulWidget {
  final ReminderModel? reminder;
  final ReminderService service;
  final VoidCallback? onReminderSaved;

  const _ReminderFormSheet({
    required this.reminder,
    required this.service,
    this.onReminderSaved,
  });

  @override
  State<_ReminderFormSheet> createState() => _ReminderFormSheetState();
}

class _ReminderFormSheetState extends State<_ReminderFormSheet> {
  String? _activityType;
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  String? _recurrence;
  String? _timezone;
  bool _isSaving = false;

  bool get _isEdit => widget.reminder != null;

  @override
  void initState() {
    super.initState();
    if (widget.reminder != null) {
      final remindAt = widget.reminder!.remindAt;
      _activityType = widget.reminder!.activityType;
      _selectedDate = DateTime(remindAt.year, remindAt.month, remindAt.day);
      _selectedTime = TimeOfDay(hour: remindAt.hour, minute: remindAt.minute);
      _recurrence = widget.reminder!.recurrence;
      _timezone = widget.reminder!.timezone;
    } else {
      _recurrence = 'none';
      _timezone = 'UTC';
    }
  }

  Future<void> _pickDate() async {
    final initialDate = _selectedDate ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() => _selectedTime = picked);
    }
  }

  DateTime? _buildReminderDateTime() {
    final date = _selectedDate;
    final time = _selectedTime;
    if (date == null || time == null) return null;

    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  Future<void> _save() async {
    final remindAt = _buildReminderDateTime();

    if (_activityType == null || remindAt == null) {
      _showMessage('Completa la actividad, fecha y hora requeridas.');
      return;
    }

    if (remindAt.isBefore(DateTime.now())) {
      _showMessage('El horario seleccionado es inválido. Debe ser futuro.');
      return;
    }

    setState(() => _isSaving = true);
    try {
      if (_isEdit) {
        await widget.service.updateReminder(
          widget.reminder!.id,
          activityType: _activityType,
          remindAt: remindAt,
          recurrence: _recurrence,
          timezone: _timezone,
        );
      } else {
        await widget.service.createReminder(
          activityType: _activityType!,
          remindAt: remindAt,
          recurrence: _recurrence,
          timezone: _timezone,
        );
      }

      if (!mounted) return;

      // Dispara el callback para sincronizar recordatorios en MainScreen
      widget.onReminderSaved?.call();

      Navigator.pop(context, true);
    } on DioException catch (e) {
      final serverMessage = e.response?.data?['remind_at'];
      if (serverMessage is List && serverMessage.isNotEmpty) {
        _showMessage(serverMessage.first.toString());
      } else if (serverMessage is String) {
        _showMessage(serverMessage);
      } else {
        _showMessage('No se pudo guardar el recordatorio.');
      }
      setState(() => _isSaving = false);
    } catch (_) {
      _showMessage('No se pudo guardar el recordatorio.');
      setState(() => _isSaving = false);
    }
  }

  void _showMessage(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final viewInsets = MediaQuery.of(context).viewInsets.bottom;
    final remindAt = _buildReminderDateTime();
    final dateText = _selectedDate == null
        ? 'Seleccionar fecha'
        : '${_selectedDate!.day.toString().padLeft(2, '0')}/${_selectedDate!.month.toString().padLeft(2, '0')}/${_selectedDate!.year}';
    final timeText = _selectedTime == null
        ? 'Seleccionar hora'
        : '${_selectedTime!.hour.toString().padLeft(2, '0')}:${_selectedTime!.minute.toString().padLeft(2, '0')}';

    return Padding(
      padding: EdgeInsets.only(bottom: viewInsets),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: EdgeInsets.zero,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isNarrow = constraints.maxWidth < 360;
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _isEdit ? 'Editar recordatorio' : 'Nuevo recordatorio',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      initialValue: _activityType,
                      decoration: InputDecoration(
                        labelText: 'Actividad',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'training',
                          child: Text('Entrenamiento'),
                        ),
                        DropdownMenuItem(
                          value: 'nutrition',
                          child: Text('Registro de alimentación'),
                        ),
                      ],
                      onChanged: (value) =>
                          setState(() => _activityType = value),
                    ),
                    const SizedBox(height: 12),
                    // Recurrence + Timezone: responsive layout
                    isNarrow
                        ? Column(
                            children: [
                              DropdownButtonFormField<String>(
                                initialValue: _recurrence,
                                decoration: InputDecoration(
                                  labelText: 'Recurrencia',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                items: const [
                                  DropdownMenuItem(
                                    value: 'none',
                                    child: Text('Una sola vez'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'daily',
                                    child: Text('Diariamente'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'weekly',
                                    child: Text('Semanalmente'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'biweekly',
                                    child: Text('Cada 2 semanas'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'monthly',
                                    child: Text('Mensualmente'),
                                  ),
                                ],
                                onChanged: (value) =>
                                    setState(() => _recurrence = value),
                              ),
                              const SizedBox(height: 10),
                              DropdownButtonFormField<String>(
                                initialValue: _timezone,
                                decoration: InputDecoration(
                                  labelText: 'Zona horaria',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                items: const [
                                  DropdownMenuItem(
                                    value: 'UTC',
                                    child: Text('UTC'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'America/Bogota',
                                    child: Text('Colombia'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'America/New_York',
                                    child: Text('Nueva York'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'America/Los_Angeles',
                                    child: Text('Los Ángeles'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'Europe/London',
                                    child: Text('Londres'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'Europe/Paris',
                                    child: Text('París'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'Asia/Tokyo',
                                    child: Text('Tokio'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'Australia/Sydney',
                                    child: Text('Sydney'),
                                  ),
                                ],
                                onChanged: (value) =>
                                    setState(() => _timezone = value),
                              ),
                            ],
                          )
                        : Row(
                            children: [
                              Expanded(
                                child: DropdownButtonFormField<String>(
                                  initialValue: _recurrence,
                                  decoration: InputDecoration(
                                    labelText: 'Recurrencia',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  items: const [
                                    DropdownMenuItem(
                                      value: 'none',
                                      child: Text('Una sola vez'),
                                    ),
                                    DropdownMenuItem(
                                      value: 'daily',
                                      child: Text('Diariamente'),
                                    ),
                                    DropdownMenuItem(
                                      value: 'weekly',
                                      child: Text('Semanalmente'),
                                    ),
                                    DropdownMenuItem(
                                      value: 'biweekly',
                                      child: Text('Cada 2 semanas'),
                                    ),
                                    DropdownMenuItem(
                                      value: 'monthly',
                                      child: Text('Mensualmente'),
                                    ),
                                  ],
                                  onChanged: (value) =>
                                      setState(() => _recurrence = value),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: DropdownButtonFormField<String>(
                                  initialValue: _timezone,
                                  decoration: InputDecoration(
                                    labelText: 'Zona horaria',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  items: const [
                                    DropdownMenuItem(
                                      value: 'UTC',
                                      child: Text('UTC'),
                                    ),
                                    DropdownMenuItem(
                                      value: 'America/Bogota',
                                      child: Text('Colombia'),
                                    ),
                                    DropdownMenuItem(
                                      value: 'America/New_York',
                                      child: Text('Nueva York'),
                                    ),
                                    DropdownMenuItem(
                                      value: 'America/Los_Angeles',
                                      child: Text('Los Ángeles'),
                                    ),
                                    DropdownMenuItem(
                                      value: 'Europe/London',
                                      child: Text('Londres'),
                                    ),
                                    DropdownMenuItem(
                                      value: 'Europe/Paris',
                                      child: Text('París'),
                                    ),
                                    DropdownMenuItem(
                                      value: 'Asia/Tokyo',
                                      child: Text('Tokio'),
                                    ),
                                    DropdownMenuItem(
                                      value: 'Australia/Sydney',
                                      child: Text('Sydney'),
                                    ),
                                  ],
                                  onChanged: (value) =>
                                      setState(() => _timezone = value),
                                ),
                              ),
                            ],
                          ),
                    const SizedBox(height: 12),
                    // Date + Time selectors: responsive
                    isNarrow
                        ? Column(
                            children: [
                              OutlinedButton.icon(
                                onPressed: _pickDate,
                                icon: const Icon(Icons.calendar_today_rounded),
                                label: Text(dateText),
                              ),
                              const SizedBox(height: 10),
                              OutlinedButton.icon(
                                onPressed: _pickTime,
                                icon: const Icon(Icons.access_time_rounded),
                                label: Text(timeText),
                              ),
                            ],
                          )
                        : Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: _pickDate,
                                  icon: const Icon(
                                    Icons.calendar_today_rounded,
                                  ),
                                  label: Text(dateText),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: _pickTime,
                                  icon: const Icon(Icons.access_time_rounded),
                                  label: Text(timeText),
                                ),
                              ),
                            ],
                          ),
                    if (remindAt != null) ...[
                      const SizedBox(height: 10),
                      Text(
                        'Programado para: ${remindAt.day.toString().padLeft(2, '0')}/${remindAt.month.toString().padLeft(2, '0')}/${remindAt.year} ${remindAt.hour.toString().padLeft(2, '0')}:${remindAt.minute.toString().padLeft(2, '0')}',
                        style: const TextStyle(color: AppColors.textSecondary),
                      ),
                    ],
                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: FilledButton(
                        onPressed: _isSaving ? null : _save,
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.primary,
                        ),
                        child: _isSaving
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Text(
                                _isEdit ? 'Actualizar' : 'Guardar recordatorio',
                              ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
