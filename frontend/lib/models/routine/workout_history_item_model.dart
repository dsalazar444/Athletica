/// Modelo para cada sesión mostrada en el historial por rango de fechas.
class WorkoutHistoryItemModel {
  final int id;
  final int routineId;
  final String routineTitle;
  final DateTime date;

  WorkoutHistoryItemModel({
    required this.id,
    required this.routineId,
    required this.routineTitle,
    required this.date,
  });

  factory WorkoutHistoryItemModel.fromJson(Map<String, dynamic> json) {
    return WorkoutHistoryItemModel(
      id: json['id'],
      routineId: json['routine'],
      routineTitle: json['routine_title'] ?? '',
      date: DateTime.parse(json['date']),
    );
  }
}
