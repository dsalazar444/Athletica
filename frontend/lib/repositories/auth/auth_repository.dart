import 'package:dio/dio.dart';
import '../../models/auth/register_model.dart';

class AuthRepository {
  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: "http://127.0.0.1:8000/api/", 
      headers: {
        "Content-Type": "application/json",
      },
    ),
  );

  Future<void> register(RegisterModel data) async {
    try {
      final json = data.toApiJson();
      print("📤 URL: ${_dio.options.baseUrl}auth/register/"); 
      print("📤 JSON: $json");  
      final response = await _dio.post(
        "auth/register/",
        data: data.toApiJson(),
      );
      

      print("✅ RESPONSE:");
      print(response.data);

    } on DioException catch (e) {
      print("❌ ERROR:");
      print(e.response?.data);
      throw e.response?.data;
    }
  }
}