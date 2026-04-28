import 'package:dio/dio.dart';
import '../core/token_storage.dart';

class ApiClient {
  static const String baseUrl = 'http://127.0.0.1:8000/api/';
  //static const String baseUrl = 'http://172.XX.XX.XX:8000/api/';

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
  bool _isRefreshing = false;
  Future<void>? _refreshFuture;

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

  // 2. Si el servidor responde 401, renueva el token (sincronizado) y reintenta
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401) {
      // Si el request ya era un intento de login o de refresh, no hacemos nada más
      if (err.requestOptions.path.contains('auth/login') ||
          err.requestOptions.path.contains('auth/refresh')) {
        handler.next(err);
        return;
      }

      try {
        if (!_isRefreshing) {
          _isRefreshing = true;
          _refreshFuture = _performRefresh();
        }

        // Esperamos a que la operación de refresco termine (la lanzada por el primero o la que ya esté en curso)
        await _refreshFuture;
        _isRefreshing = false;

        // Reintentamos con el nuevo token obtenido
        final newToken = await TokenStorage.getAccessToken();
        if (newToken != null) {
          final retryOptions = err.requestOptions;
          retryOptions.headers['Authorization'] = 'Bearer $newToken';

          // Usamos la misma instancia de dio para reintentar (pasará por onRequest de nuevo si es fetch)
          // pero aquí ya inyectamos el header manualmente para mayor seguridad
          final response = await dio.fetch(retryOptions);
          handler.resolve(response);
          return;
        }
      } catch (e) {
        // Si el refresh falla definitivamente
        _isRefreshing = false;
        await TokenStorage.clearTokens();
        handler.next(err);
        return;
      }
    }
    handler.next(err);
  }

  Future<void> _performRefresh() async {
    final refreshToken = await TokenStorage.getRefreshToken();
    if (refreshToken == null) throw Exception('No refresh token');

    final refreshDio = Dio(BaseOptions(baseUrl: ApiClient.baseUrl));
    final response = await refreshDio.post(
      'auth/refresh/',
      data: {'refresh': refreshToken},
    );

    // Guardamos los nuevos tokens (asumimos que el backend puede rotarlos o no)
    // Nota: SimpleJWT por defecto devuelve un nuevo 'access'.
    await TokenStorage.saveTokens(
      access: response.data['access'],
      refresh: response.data['refresh'] ?? refreshToken,
    );
  }
}
