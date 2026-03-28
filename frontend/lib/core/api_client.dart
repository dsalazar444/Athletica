import 'package:dio/dio.dart';
import '../core/token_storage.dart';

class ApiClient {
  static const String baseUrl = 'http://127.0.0.1:8000/api/';

  static final Dio dio = _createDio();

  static Dio _createDio() {
    final dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
        headers: {'Content-Type': 'application/json'},
      ),
    );

    dio.interceptors.add(_AuthInterceptor(dio));

    return dio;
  }
}

class _AuthInterceptor extends Interceptor {
  final Dio dio;
  _AuthInterceptor(this.dio);

  // 1. Agrega el token a cada request automáticamente
  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await TokenStorage.getAccessToken();
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  // 2. Si el servidor responde 401, renueva el token y reintenta
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401) {
      try {
        final refreshToken = await TokenStorage.getRefreshToken();
        if (refreshToken == null) {
          handler.next(err);
          return;
        }

        // Llama a auth/refresh/ con un Dio limpio (sin interceptor para evitar loop)
        final refreshDio = Dio(BaseOptions(baseUrl: ApiClient.baseUrl));
        final response = await refreshDio.post(
          'auth/refresh/',
          data: {'refresh': refreshToken},
        );

        // Guarda el nuevo access token
        await TokenStorage.saveTokens(
          access: response.data['access'],
          refresh: refreshToken,
        );

        // Reintenta el request original con el nuevo token
        final retryOptions = err.requestOptions;
        retryOptions.headers['Authorization'] =
            'Bearer ${response.data['access']}';
        final retryResponse = await dio.fetch(retryOptions);
        handler.resolve(retryResponse);
      } catch (_) {
        // Si el refresh también falla → limpiar tokens (logout automático)
        await TokenStorage.clearTokens();
        handler.next(err);
      }
    } else {
      handler.next(err);
    }
  }
}
