import 'package:dio/dio.dart';
import '../../models/auth/register_model.dart';
import '../../core/token_storage.dart';
import '../../core/api_client.dart';


class AuthRepository {
  final Dio _dio = ApiClient.dio;


  Future<void> register(RegisterModel data) async {
    try {
      final json = data.toApiJson();
      print("URL: ${_dio.options.baseUrl}auth/register/");
      print("JSON: $json");

      final response = await _dio.post("auth/register/", data: json);

      // 👈 guardar tokens
      await TokenStorage.saveTokens(
        access: response.data['access'],
        refresh: response.data['refresh'],
      );

      print("RESPONSE:");
      print(response.data);
    } on DioException catch (e) {
      print("STATUS: ${e.response?.statusCode}");
      print("ERROR: ${e.response?.data}");
      throw e.response?.data;
    }
  }
}