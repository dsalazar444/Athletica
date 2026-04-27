import 'package:dio/dio.dart';
import '../../core/api_client.dart';
import '../../models/group/group_model.dart';
import '../../models/group/member_model.dart';

class GroupRepository {
  final Dio _dio = ApiClient.dio;

  /// 🔹 Obtener todos los grupos del coach
  Future<List<GroupModel>> getGroups() async {
    final response = await _dio.get('groups/');

    if (response.statusCode == 200) {
      final data = response.data as List;
      return data.map((e) => GroupModel.fromJson(e)).toList();
    } else {
      throw Exception('Error al obtener grupos');
    }
  }

  /// 🔹 Crear un nuevo grupo
  Future<GroupModel> createGroup(String name) async {
    final response = await _dio.post('groups/', data: {'name': name});

    if (response.statusCode == 201 || response.statusCode == 200) {
      return GroupModel.fromJson(response.data);
    } else {
      throw Exception('Error creando grupo');
    }
  }

  /// Obtener un grupo por ID
  Future<GroupModel> getGroup(int id) async {
    final response = await _dio.get('groups/$id/');
    if (response.statusCode == 200) {
      return GroupModel.fromJson(response.data);
    } else {
      throw Exception('Error al obtener grupo');
    }
  }

  /// Editar nombre y/o miembros
  Future<GroupModel> updateGroup(
    int id,
    String name,
    List<int> memberIds,
  ) async {
    final response = await _dio.put(
      'groups/$id/',
      data: {'name': name, 'member_ids': memberIds},
    );
    if (response.statusCode == 200) {
      return GroupModel.fromJson(response.data);
    } else {
      throw Exception('Error actualizando grupo');
    }
  }

  /// Buscar atletas por username, nombre o email
  Future<List<MemberModel>> searchAthletes(String query) async {
    final response = await _dio.get(
      'users/athletes/search/',
      queryParameters: {'q': query},
    );
    if (response.statusCode == 200) {
      final data = response.data as List;
      return data.map((e) => MemberModel.fromJson(e)).toList();
    } else {
      throw Exception('Error buscando atletas');
    }
  }
}
