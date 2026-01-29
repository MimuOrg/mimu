import 'package:dio/dio.dart';
import 'package:mimu/data/server_config.dart';
import 'package:mimu/data/user_service.dart';

/// Dio client for /api/v1/* with Authorization interceptor.
class DioApiClient {
  static final DioApiClient _instance = DioApiClient._internal();
  factory DioApiClient() => _instance;
  DioApiClient._internal() {
    _dio = Dio(
      BaseOptions(
        baseUrl: ServerConfig.getApiBaseUrl(),
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          await UserService.init();
          final token = UserService.getAccessToken();
          final path = options.path.startsWith('http') ? Uri.tryParse(options.path)?.path ?? options.path : options.path;
          final needAuth = path.startsWith('/api/v1/') ||
              path.startsWith('/calls/') ||
              path == '/users/me' ||
              path.startsWith('/users/search') ||
              (path.startsWith('/users/') && path.endsWith('/verify'));
          if (token != null && token.isNotEmpty && needAuth) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
      ),
    );
  }

  late final Dio _dio;

  Dio get dio => _dio;
}

