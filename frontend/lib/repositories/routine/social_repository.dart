import 'package:dio/dio.dart';
import '../../core/api_client.dart';
import '../../models/routine/comment_model.dart';

class SocialRepository {
  final Dio _dio = ApiClient.dio;

  Future<List<CommentModel>> fetchComments(int routineId) async {
    try {
      final response = await _dio.get('routines/$routineId/comments/');
      if (response.statusCode == 200) {
        return (response.data as List)
            .map((e) => CommentModel.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      throw Exception('Error al cargar comentarios.');
    } on DioException catch (e) {
      throw Exception('Error de red: ${e.message}');
    }
  }

  Future<CommentModel> postComment(
    int routineId,
    String text, {
    int? parentId,
  }) async {
    try {
      final data = <String, dynamic>{'text': text};
      if (parentId != null) data['parent'] = parentId;
      final response = await _dio.post(
        'routines/$routineId/comments/',
        data: data,
      );
      if (response.statusCode == 201) {
        return CommentModel.fromJson(response.data as Map<String, dynamic>);
      }
      throw Exception('Error al publicar comentario.');
    } on DioException catch (e) {
      throw Exception('Error de red: ${e.message}');
    }
  }

  Future<void> deleteComment(int commentId) async {
    try {
      await _dio.delete('comments/$commentId/');
    } on DioException catch (e) {
      throw Exception('Error al eliminar comentario: ${e.message}');
    }
  }

  /// Devuelve true si quedó reaccionado, false si se eliminó la reacción.
  Future<bool> toggleRoutineReaction(int routineId) async {
    try {
      final response = await _dio.post('routines/$routineId/react/');
      final reacted = response.data['reacted'] as bool? ?? false;
      return reacted;
    } on DioException catch (e) {
      throw Exception('Error al reaccionar: ${e.message}');
    }
  }

  Future<bool> toggleCommentReaction(int commentId) async {
    try {
      final response = await _dio.post('comments/$commentId/react/');
      final reacted = response.data['reacted'] as bool? ?? false;
      return reacted;
    } on DioException catch (e) {
      throw Exception('Error al reaccionar al comentario: ${e.message}');
    }
  }
}
