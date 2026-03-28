import 'package:dio/dio.dart';
import '../../models/auth/register_model.dart';
import '../../core/token_storage.dart';
import '../../core/api_client.dart';

// Repositorio encargado de las operaciones de autenticacion.
// Usa ApiClient.dio para que todas las peticiones pasen por el interceptor de tokens.
class AuthRepository {
  final Dio _dio = ApiClient.dio;

  // Envia los datos de registro al backend y guarda los tokens JWT recibidos.
  Future<void> register(RegisterModel data) async {
    try {
      final json = data.toApiJson();

      print('URL: ${_dio.options.baseUrl}auth/register/');
      print('JSON: $json');

      final response = await _dio.post('auth/register/', data: json);

      // Guarda el access token, el refresh token y el nombre en el almacenamiento local.
      await TokenStorage.saveTokens(
        access: response.data['access'],
        refresh: response.data['refresh'],
        name: response.data['user']['first_name'],
      );

      print('RESPONSE:');
      print(response.data);
    } on DioException catch (e) {
      print('STATUS: ${e.response?.statusCode}');
      print('ERROR: ${e.response?.data}');
      throw e.response?.data;
    }
  }
}
