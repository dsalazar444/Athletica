import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'dart:async';
import '../../../../models/routine/exercise_model.dart';
import '../../../../repositories/routine/routine_repository.dart';
import '../../../../theme/app_colors.dart';
import '../../../../theme/app_text_styles.dart';
import '../../../../core/api_client.dart';

class AddExerciseSheet extends StatefulWidget {
  final int routineId;
  final int currentExerciseCount;
  final RoutineRepository repository;
  final VoidCallback onAdded;

  const AddExerciseSheet({
    super.key,
    required this.routineId,
    required this.currentExerciseCount,
    required this.repository,
    required this.onAdded,
  });

  @override
  State<AddExerciseSheet> createState() => _AddExerciseSheetState();
}

class _AddExerciseSheetState extends State<AddExerciseSheet> {
  final TextEditingController _searchController = TextEditingController();
  List<dynamic> _results = [];
  bool _isSearching = false;
  bool _isAdding = false;
  dynamic _selectedExercise;
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _searchExercises(String query) async {
    if (_debounce?.isActive ?? false) _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () async {
      if (query.length < 2) {
        if (mounted) setState(() => _results = []);
        return;
      }
      if (mounted) setState(() => _isSearching = true);
      try {
        final dio = Dio(BaseOptions(
          connectTimeout: const Duration(seconds: 5),
          headers: {'User-Agent': 'AthleticaApp/1.0 (contact@athletica.com)'},
        ));
        final response = await dio.get(
          'https://wger.de/api/v2/exercise/search/',
          queryParameters: {'term': query, 'language': '2', 'format': 'json'},
        );
        final suggestions = response.data['suggestions'] as List? ?? [];
        if (mounted) setState(() => _results = suggestions);
      } catch (e) {
        debugPrint('Exercise search error: $e');
        if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(
             SnackBar(content: Text("Error al conectar con el catálogo de ejercicios. Reintenta.")),
           );
        }
      } finally {
        if (mounted) setState(() => _isSearching = false);
      }
    });
  }

  Future<void> _addExercise() async {
    if (_selectedExercise == null) return;
    if (mounted) setState(() => _isAdding = true);
    try {
      final data = _selectedExercise['data'];
      final externalId = int.parse(_selectedExercise['value'].toString());
      final name = _selectedExercise['label'] ?? data?['name'] ?? 'Ejercicio';

      final exists = await widget.repository.existsExercise(externalId);
      if (!exists) {
        await widget.repository.createExercise(ExerciseModel(
          id: externalId,
          name: name,
          description: '',
          muscles: [], 
          imageUrl: '',
        ));
      }

      await ApiClient.dio.patch(
        'routines/${widget.routineId}/add_exercises/',
        data: {
          'exercises': [
            {'external_id': externalId}
          ]
        },
      );

      if (mounted) {
        Navigator.pop(context);
        widget.onAdded();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('"$name" añadido a la rutina.'),
            backgroundColor: AppColors.primary,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) setState(() => _isAdding = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (_, scrollController) => Container(
        decoration: const BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          children: [
            _buildHandle(),
            _buildHeader(),
            const SizedBox(height: 8),
            _buildResults(scrollController),
            _buildAddButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildHandle() {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      width: 40, height: 4,
      decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(4)),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('AÑADIR EJERCICIO', style: AppTextStyles.fitnessBold),
              IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close_rounded)),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _searchController,
            onChanged: _searchExercises,
            autofocus: true,
            decoration: InputDecoration(
              hintText: 'Buscar ejercicio (ej. squat, bench)...',
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: _isSearching
                  ? const Padding(padding: EdgeInsets.all(14), child: CircularProgressIndicator(strokeWidth: 2))
                  : null,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
              filled: true,
              fillColor: AppColors.surface,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResults(ScrollController scrollController) {
    return Expanded(
      child: ListView.builder(
        controller: scrollController,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        itemCount: _results.length,
        itemBuilder: (_, i) {
          final ex = _results[i];
          final isSelected = _selectedExercise == ex;
          return GestureDetector(
            onTap: () => setState(() => _selectedExercise = isSelected ? null : ex),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary.withValues(alpha: 0.08) : AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected ? AppColors.primary : AppColors.border.withValues(alpha: 0.3),
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.fitness_center_rounded, color: AppColors.primary, size: 20),
                  ),
                  const SizedBox(width: 16),
                  Expanded(child: Text(ex['label'] ?? '', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15))),
                  if (isSelected) const Icon(Icons.check_circle_rounded, color: AppColors.primary),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildAddButton() {
    return Padding(
      padding: EdgeInsets.fromLTRB(24, 12, 24, MediaQuery.of(context).viewInsets.bottom + 24),
      child: SizedBox(
        width: double.infinity, height: 56,
        child: ElevatedButton(
          onPressed: _selectedExercise == null || _isAdding ? null : _addExercise,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          child: _isAdding
              ? const CircularProgressIndicator(color: Colors.white)
              : const Text('AÑADIR A LA RUTINA', style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 1)),
        ),
      ),
    );
  }
}
