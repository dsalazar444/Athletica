import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthService {
  final Dio _dio = Dio(BaseOptions(
    baseUrl: 'http://10.0.2.2:8000/api/', // Android emulator
    // baseUrl: 'http://localhost:8000/api/', // iOS simulator
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
  ));
  final _storage = const FlutterSecureStorage();

  // ─── REGISTER ───────────────────────────────────
  Future<Map<String, dynamic>> register({
    required String email,
    required String username,
    required String firstName,
    required String lastName,
    required String gender,
    required String password,
    required String password2,
    int? age,
    double? weight,
    double? height,
  }) async {
    try {
      final res = await _dio.post('register/', data: {
        'email': email,
        'username': username,
        'first_name': firstName,
        'last_name': lastName,
        'gender': gender,
        'age': age,
        'weight': weight,
        'height': height,
        'password': password,
        'password2': password2,
      });
      await _saveTokens(res.data);
      return {'success': true, 'user': res.data['user']};
    } on DioException catch (e) {
      return {'success': false, 'errors': e.response?.data ?? {}};
    }
  }

  // ─── LOGIN ──────────────────────────────────────
  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final res = await _dio.post('login/', data: {
        'email': email,
        'password': password,
      });
      await _saveTokens(res.data);
      return {'success': true, 'user': res.data['user']};
    } on DioException catch (e) {
      final error = e.response?.data?['error'] ?? 'Error al iniciar sesión.';
      return {'success': false, 'error': error};
    }
  }

  // ─── LOGOUT ─────────────────────────────────────
  Future<void> logout() => _storage.deleteAll();

  // ─── TOKENS ─────────────────────────────────────
  Future<void> _saveTokens(Map data) async {
    await _storage.write(key: 'access', value: data['access']);
    await _storage.write(key: 'refresh', value: data['refresh']);
  }

  Future<String?> getAccessToken() => _storage.read(key: 'access');

  Future<bool> isLoggedIn() async {
    final token = await getAccessToken();
    return token != null;
  }
}