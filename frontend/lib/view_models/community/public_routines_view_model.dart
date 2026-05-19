import 'package:flutter/material.dart';

import '../../models/routine/comment_model.dart';
import '../../models/routine/routine_model.dart';
import '../../repositories/routine/routine_repository.dart';
import '../../repositories/routine/social_repository.dart';
import '../../core/token_storage.dart';

/// ViewModel para cargar y exponer las rutinas públicas disponibles en la comunidad.
class PublicRoutinesViewModel extends ChangeNotifier {
  final RoutineRepository routineRepository;
  final SocialRepository _socialRepository = SocialRepository();
  final bool mineOnly;

  bool isLoading = false;
  String? errorMessage;
  List<RoutineModel> publicRoutines = [];
  int? currentUserId;

  final Map<int, List<CommentModel>> commentsMap = {};
  final Map<int, bool> commentsLoadingMap = {};

  PublicRoutinesViewModel({
    required this.routineRepository,
    this.mineOnly = false,
  });

  /// Carga todas las rutinas públicas desde el backend.
  Future<void> loadPublicRoutines() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      // Obtener el ID del usuario actual
      currentUserId = await TokenStorage.getUserId();
      // Obtener rutinas publicas
      publicRoutines = await routineRepository.fetchPublicRoutines(
        mineOnly: mineOnly,
      );
    } catch (e) {
      errorMessage = 'No se pudieron cargar las rutinas públicas.';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  /// Refresca la lista sin cambiar la interfaz que la consume.
  Future<void> refresh() => loadPublicRoutines();

  /// Determina si una rutina pertenece al usuario actual.
  bool isOwnRoutine(RoutineModel routine) {
    return currentUserId != null && routine.createdBy == currentUserId;
  }

  /// Sigue al creador de una rutina.
  Future<void> followCreator(int userId) async {
    try {
      await routineRepository.followUser(userId);

      _updateFollowStateForCreator(userId: userId, isFollowing: true);
    } catch (e) {
      errorMessage = 'Error al seguir: $e';
      notifyListeners();
    }
  }

  /// Deja de seguir al creador de una rutina.
  Future<void> unfollowCreator(int userId) async {
    try {
      await routineRepository.unfollowUser(userId);

      _updateFollowStateForCreator(userId: userId, isFollowing: false);
    } catch (e) {
      errorMessage = 'Error al dejar de seguir: $e';
      notifyListeners();
    }
  }

  void _updateFollowStateForCreator({
    required int userId,
    required bool isFollowing,
  }) {
    publicRoutines = publicRoutines
        .map(
          (routine) => routine.createdBy == userId
              ? routine.copyWith(isFollowing: isFollowing)
              : routine,
        )
        .toList();
    notifyListeners();
  }

  Future<void> toggleRoutineReaction(int routineId) async {
    final index = publicRoutines.indexWhere((r) => r.id == routineId);
    if (index == -1) return;
    final routine = publicRoutines[index];
    final wasLiked = routine.userLiked;

    // Optimistic update
    publicRoutines[index] = routine.copyWith(
      userLiked: !wasLiked,
      likesCount: wasLiked ? routine.likesCount - 1 : routine.likesCount + 1,
    );
    notifyListeners();

    try {
      await _socialRepository.toggleRoutineReaction(routineId);
    } catch (_) {
      // Revert on error
      publicRoutines[index] = routine;
      notifyListeners();
    }
  }

  Future<void> loadComments(int routineId) async {
    commentsLoadingMap[routineId] = true;
    notifyListeners();
    try {
      commentsMap[routineId] = await _socialRepository.fetchComments(routineId);
    } catch (_) {
      commentsMap[routineId] = [];
    } finally {
      commentsLoadingMap[routineId] = false;
      notifyListeners();
    }
  }

  Future<void> postComment(int routineId, String text, {int? parentId}) async {
    final comment = await _socialRepository.postComment(
      routineId,
      text,
      parentId: parentId,
    );

    final comments = List<CommentModel>.from(commentsMap[routineId] ?? []);
    if (parentId == null) {
      commentsMap[routineId] = [...comments, comment];
      // Update comments count on routine
      final index = publicRoutines.indexWhere((r) => r.id == routineId);
      if (index != -1) {
        publicRoutines[index] = publicRoutines[index].copyWith(
          commentsCount: publicRoutines[index].commentsCount + 1,
        );
      }
    } else {
      commentsMap[routineId] = comments.map((c) {
        if (c.id == parentId) {
          return c.copyWith(replies: [...c.replies, comment]);
        }
        return c;
      }).toList();
    }
    notifyListeners();
  }

  Future<void> deleteComment(int commentId, int routineId) async {
    await _socialRepository.deleteComment(commentId);
    final comments = commentsMap[routineId] ?? [];
    final isTopLevel = comments.any((c) => c.id == commentId);

    commentsMap[routineId] = comments
        .where((c) => c.id != commentId)
        .map(
          (c) => c.copyWith(
            replies: c.replies.where((r) => r.id != commentId).toList(),
          ),
        )
        .toList();

    if (isTopLevel) {
      final index = publicRoutines.indexWhere((r) => r.id == routineId);
      if (index != -1) {
        publicRoutines[index] = publicRoutines[index].copyWith(
          commentsCount: (publicRoutines[index].commentsCount - 1).clamp(
            0,
            999999,
          ),
        );
      }
    }
    notifyListeners();
  }

  Future<void> toggleCommentReaction(int commentId, int routineId) async {
    final comments = commentsMap[routineId];
    if (comments == null) return;

    CommentModel toggleOne(CommentModel c) {
      if (c.id == commentId) {
        final wasLiked = c.userLiked;
        return c.copyWith(
          userLiked: !wasLiked,
          likesCount: wasLiked ? c.likesCount - 1 : c.likesCount + 1,
        );
      }
      final updatedReplies = c.replies.map((r) => toggleOne(r)).toList();
      return c.copyWith(replies: updatedReplies);
    }

    commentsMap[routineId] = comments.map(toggleOne).toList();
    notifyListeners();

    try {
      await _socialRepository.toggleCommentReaction(commentId);
    } catch (_) {
      await loadComments(routineId);
    }
  }

  /// Calcula las iniciales a partir de un nombre.
  static String getInitials(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return '?';
    final parts = trimmed.split(' ').where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return (parts[0][0] + parts[1][0]).toUpperCase();
  }
}
