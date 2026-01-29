import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:mimu/data/server_config.dart';
import 'package:mimu/data/user_service.dart';
import 'package:mimu/data/error_handler.dart';

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
      // При релизе поднимать версию для совместимости с сервером
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
    return await ErrorHandler.withRetry(
      operation: () async {
        final url = Uri.parse('${ServerConfig.getApiBaseUrl()}$endpoint')
            .replace(queryParameters: queryParams);
        
        final requestHeaders = await _getHeaders(additional: headers);
        
        final response = await http
            .get(url, headers: requestHeaders)
            .timeout(ServerConfig.requestTimeout);

        return _handleResponse(response);
      },
      shouldRetry: ErrorHandler.canRetry,
    ).catchError((error) {
      ErrorHandler.logError(error, StackTrace.current, context: 'GET $endpoint');
      return _handleError(error);
    });
  }

  /// Выполнить POST запрос
  Future<Map<String, dynamic>> post(
    String endpoint, {
    Map<String, dynamic>? body,
    Map<String, String>? headers,
  }) async {
    return await ErrorHandler.withRetry(
      operation: () async {
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
      },
      shouldRetry: ErrorHandler.canRetry,
    ).catchError((error) {
      ErrorHandler.logError(error, StackTrace.current, context: 'POST $endpoint');
      return _handleError(error);
    });
  }

  /// Выполнить PUT запрос
  Future<Map<String, dynamic>> put(
    String endpoint, {
    Map<String, dynamic>? body,
    Map<String, String>? headers,
  }) async {
    return await ErrorHandler.withRetry(
      operation: () async {
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
      },
      shouldRetry: ErrorHandler.canRetry,
    ).catchError((error) {
      ErrorHandler.logError(error, StackTrace.current, context: 'PUT $endpoint');
      return _handleError(error);
    });
  }

  /// Выполнить DELETE запрос
  Future<Map<String, dynamic>> delete(
    String endpoint, {
    Map<String, String>? headers,
  }) async {
    return await ErrorHandler.withRetry(
      operation: () async {
        final url = Uri.parse('${ServerConfig.getApiBaseUrl()}$endpoint');
        final requestHeaders = await _getHeaders(additional: headers);
        
        final response = await http
            .delete(url, headers: requestHeaders)
            .timeout(ServerConfig.requestTimeout);

        return _handleResponse(response);
      },
      shouldRetry: ErrorHandler.canRetry,
    ).catchError((error) {
      ErrorHandler.logError(error, StackTrace.current, context: 'DELETE $endpoint');
      return _handleError(error);
    });
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

  /// Redact sensitive keys for debug logging (tokens, payloads). Returns safe string.
  static String _redactForLog(dynamic value) {
    if (value == null) return 'null';
    if (value is String) {
      try {
        final decoded = jsonDecode(value);
        return _redactForLog(decoded);
      } catch (_) {
        return value.length > 80 ? '${value.substring(0, 80)}...' : value;
      }
    }
    if (value is Map) {
      const sensitiveKeys = {'access_token', 'refresh_token', 'encrypted_payload', 'decrypted_content', 'token', 'authorization'};
      final redacted = <String, dynamic>{};
      for (final entry in value.entries) {
        final k = entry.key.toString().toLowerCase();
        final isSensitive = sensitiveKeys.any((s) => k.contains(s));
        redacted[entry.key.toString()] = isSensitive ? '<redacted>' : _redactForLog(entry.value);
      }
      return redacted.toString();
    }
    if (value is List) return '[${value.length} items]';
    return value.toString();
  }

  /// Обработать ответ сервера
  Map<String, dynamic> _handleResponse(http.Response response) {
    if (kDebugMode) {
      print('=== API Response ===');
      print('Status Code: ${response.statusCode}');
      print('Response Body: ${_redactForLog(response.body)}');
      print('===================');
    }
    
    if (response.statusCode >= 200 && response.statusCode < 300) {
      try {
        if (response.body.isEmpty) {
          if (kDebugMode) print('Empty response body');
          return {'success': true, 'data': null};
        }
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        if (kDebugMode) print('Parsed JSON data: ${_redactForLog(data)}');
        return {'success': true, 'data': data};
      } catch (e) {
        if (kDebugMode) print('JSON parsing error: $e');
        return {
          'success': false,
          'error': 'Invalid JSON response',
          'statusCode': response.statusCode,
          'rawBody': response.body,
        };
      }
    } else {
      // Пытаемся распарсить ошибку от сервера
      String errorMessage = 'Unknown error';
      try {
        if (response.body.isNotEmpty) {
          final errorData = jsonDecode(response.body);
          if (errorData is Map<String, dynamic>) {
            errorMessage = errorData['message'] ?? 
                          errorData['error'] ?? 
                          errorData['detail'] ?? 
                          response.body;
          } else {
            errorMessage = response.body;
          }
        }
      } catch (e) {
        errorMessage = response.body.isNotEmpty ? response.body : 'Unknown error';
      }
      if (kDebugMode) print('Server error: ${_redactForLog(errorMessage)}');
      return {
        'success': false,
        'error': 'Server error',
        'statusCode': response.statusCode,
        'message': errorMessage,
        'rawBody': response.body,
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

