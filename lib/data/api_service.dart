import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:mimu/data/server_config.dart';
import 'package:mimu/data/user_service.dart';

/// Базовый сервис для работы с API
class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  /// Получить заголовки для запросов
  Future<Map<String, String>> _getHeaders({Map<String, String>? additional}) async {
    await UserService.init();
    final prId = UserService.getPrId();
    
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'X-PrID': prId ?? '',
      'X-Client-Version': '1.0.0',
      'X-Platform': Platform.isAndroid ? 'android' : Platform.isIOS ? 'ios' : 'other',
    };
    
    if (additional != null) {
      headers.addAll(additional);
    }
    
    return headers;
  }

  /// Выполнить GET запрос
  Future<Map<String, dynamic>> get(
    String endpoint, {
    Map<String, String>? queryParams,
    Map<String, String>? headers,
  }) async {
    try {
      final url = Uri.parse('${ServerConfig.getApiBaseUrl()}$endpoint')
          .replace(queryParameters: queryParams);
      
      final requestHeaders = await _getHeaders(additional: headers);
      
      final response = await http
          .get(url, headers: requestHeaders)
          .timeout(ServerConfig.requestTimeout);

      return _handleResponse(response);
    } catch (e) {
      return _handleError(e);
    }
  }

  /// Выполнить POST запрос
  Future<Map<String, dynamic>> post(
    String endpoint, {
    Map<String, dynamic>? body,
    Map<String, String>? headers,
  }) async {
    try {
      final url = Uri.parse('${ServerConfig.getApiBaseUrl()}$endpoint');
      final requestHeaders = await _getHeaders(additional: headers);
      
      final response = await http
          .post(
            url,
            headers: requestHeaders,
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(ServerConfig.requestTimeout);

      return _handleResponse(response);
    } catch (e) {
      return _handleError(e);
    }
  }

  /// Выполнить PUT запрос
  Future<Map<String, dynamic>> put(
    String endpoint, {
    Map<String, dynamic>? body,
    Map<String, String>? headers,
  }) async {
    try {
      final url = Uri.parse('${ServerConfig.getApiBaseUrl()}$endpoint');
      final requestHeaders = await _getHeaders(additional: headers);
      
      final response = await http
          .put(
            url,
            headers: requestHeaders,
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(ServerConfig.requestTimeout);

      return _handleResponse(response);
    } catch (e) {
      return _handleError(e);
    }
  }

  /// Выполнить DELETE запрос
  Future<Map<String, dynamic>> delete(
    String endpoint, {
    Map<String, String>? headers,
  }) async {
    try {
      final url = Uri.parse('${ServerConfig.getApiBaseUrl()}$endpoint');
      final requestHeaders = await _getHeaders(additional: headers);
      
      final response = await http
          .delete(url, headers: requestHeaders)
          .timeout(ServerConfig.requestTimeout);

      return _handleResponse(response);
    } catch (e) {
      return _handleError(e);
    }
  }

  /// Загрузить файл
  Future<Map<String, dynamic>> uploadFile(
    String endpoint,
    File file, {
    String? fileName,
    Map<String, String>? additionalFields,
    Function(int sent, int total)? onProgress,
  }) async {
    try {
      final url = Uri.parse(endpoint);
      final requestHeaders = await _getHeaders();
      requestHeaders.remove('Content-Type'); // Для multipart/form-data
      
      final request = http.MultipartRequest('POST', url);
      request.headers.addAll(requestHeaders);
      
      final fileStream = file.openRead();
      final length = await file.length();
      
      final multipartFile = await http.MultipartFile.fromPath(
        'file',
        file.path,
        filename: fileName ?? file.path.split('/').last,
      );
      request.files.add(multipartFile);
      
      if (additionalFields != null) {
        request.fields.addAll(additionalFields);
      }
      
      final streamedResponse = await request.send()
          .timeout(ServerConfig.uploadTimeout);
      
      final response = await http.Response.fromStream(streamedResponse);
      return _handleResponse(response);
    } catch (e) {
      return _handleError(e);
    }
  }

  /// Скачать файл
  Future<http.Response> downloadFile(
    String url, {
    Map<String, String>? headers,
    Function(int received, int total)? onProgress,
  }) async {
    try {
      final requestHeaders = await _getHeaders(additional: headers);
      final uri = Uri.parse(url);
      
      final response = await http
          .get(uri, headers: requestHeaders)
          .timeout(ServerConfig.uploadTimeout);
      
      return response;
    } catch (e) {
      rethrow;
    }
  }

  /// Обработать ответ сервера
  Map<String, dynamic> _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      try {
        if (response.body.isEmpty) {
          return {'success': true, 'data': null};
        }
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return {'success': true, 'data': data};
      } catch (e) {
        return {
          'success': false,
          'error': 'Invalid JSON response',
          'statusCode': response.statusCode,
        };
      }
    } else {
      return {
        'success': false,
        'error': 'Server error',
        'statusCode': response.statusCode,
        'message': response.body.isNotEmpty ? response.body : 'Unknown error',
      };
    }
  }

  /// Обработать ошибку
  Map<String, dynamic> _handleError(dynamic error) {
    if (error is http.ClientException) {
      return {
        'success': false,
        'error': 'Network error',
        'message': error.message,
      };
    } else if (error is SocketException) {
      return {
        'success': false,
        'error': 'Connection error',
        'message': 'No internet connection',
      };
    } else {
      return {
        'success': false,
        'error': 'Unknown error',
        'message': error.toString(),
      };
    }
  }

  /// Выполнить запрос с повторными попытками
  Future<Map<String, dynamic>> retryRequest(
    Future<Map<String, dynamic>> Function() request, {
    int maxRetries = ServerConfig.maxRetries,
    Duration delay = ServerConfig.retryDelay,
  }) async {
    int attempts = 0;
    
    while (attempts < maxRetries) {
      final result = await request();
      
      if (result['success'] == true) {
        return result;
      }
      
      // Не повторяем для клиентских ошибок (4xx)
      if (result['statusCode'] != null && result['statusCode'] >= 400 && result['statusCode'] < 500) {
        return result;
      }
      
      attempts++;
      if (attempts < maxRetries) {
        await Future.delayed(delay * attempts); // Экспоненциальная задержка
      }
    }
    
    return {
      'success': false,
      'error': 'Max retries exceeded',
      'message': 'Failed after $maxRetries attempts',
    };
  }
}

