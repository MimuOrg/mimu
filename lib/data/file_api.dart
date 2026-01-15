import 'dart:io';
import 'dart:convert';
import 'package:mimu/data/api_service.dart';
import 'package:mimu/data/server_config.dart';
import 'package:path_provider/path_provider.dart';

/// API для работы с файлами
class FileApi {
  static final FileApi _instance = FileApi._internal();
  factory FileApi() => _instance;
  FileApi._internal();

  final ApiService _api = ApiService();

  /// Загрузить файл на сервер
  Future<Map<String, dynamic>> uploadFile({
    required File file,
    required String type, // 'image', 'video', 'voice', 'file'
    String? fileName,
    Function(int sent, int total)? onProgress,
  }) async {
    try {
      // Проверка размера файла
      final fileSize = await file.length();
      if (!_validateFileSize(fileSize, type)) {
        return {
          'success': false,
          'error': 'File too large',
          'message': 'File size exceeds maximum allowed size',
        };
      }

      // Определяем endpoint в зависимости от типа
      String endpoint;
      switch (type) {
        case 'image':
        case 'video':
          endpoint = ServerConfig.getMediaUploadUrl();
          break;
        case 'voice':
          endpoint = ServerConfig.getVoiceUploadUrl();
          break;
        default:
          endpoint = ServerConfig.getFileUploadUrl();
      }

      final result = await _api.uploadFile(
        endpoint,
        file,
        fileName: fileName ?? file.path.split('/').last,
        additionalFields: {
          'type': type,
        },
        onProgress: onProgress,
      );

      if (result['success'] == true && result['data'] != null) {
        return {
          'success': true,
          'fileId': result['data']['fileId'],
          'url': result['data']['url'],
          'size': result['data']['size'],
          'mimeType': result['data']['mimeType'],
        };
      }

      return result;
    } catch (e) {
      return {
        'success': false,
        'error': 'Upload failed',
        'message': e.toString(),
      };
    }
  }

  /// Скачать файл с сервера
  Future<Map<String, dynamic>> downloadFile({
    required String fileId,
    String? fileName,
    Function(int received, int total)? onProgress,
  }) async {
    try {
      final url = ServerConfig.getFileDownloadUrl(fileId);
      final response = await _api.downloadFile(
        url,
        onProgress: onProgress,
      );

      if (response.statusCode == 200) {
        // Сохраняем файл локально
        final directory = await getApplicationDocumentsDirectory();
        final downloadsDir = Directory('${directory.path}/downloads');
        if (!await downloadsDir.exists()) {
          await downloadsDir.create(recursive: true);
        }

        final savePath = '${downloadsDir.path}/${fileName ?? fileId}';
        final file = File(savePath);
        await file.writeAsBytes(response.bodyBytes);

        return {
          'success': true,
          'filePath': savePath,
          'size': response.bodyBytes.length,
        };
      } else {
        return {
          'success': false,
          'error': 'Download failed',
          'statusCode': response.statusCode,
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Download failed',
        'message': e.toString(),
      };
    }
  }

  /// Получить информацию о файле
  Future<Map<String, dynamic>> getFileInfo(String fileId) async {
    final result = await _api.retryRequest(() => _api.get(
      '/api/v1/files/$fileId/info',
    ));

    return result;
  }

  /// Удалить файл с сервера
  Future<Map<String, dynamic>> deleteFile(String fileId) async {
    final result = await _api.retryRequest(() => _api.delete(
      '/api/v1/files/$fileId',
    ));

    return result;
  }

  /// Загрузить изображение
  Future<Map<String, dynamic>> uploadImage({
    required File file,
    String? fileName,
    Function(int sent, int total)? onProgress,
  }) async {
    return uploadFile(
      file: file,
      type: 'image',
      fileName: fileName,
      onProgress: onProgress,
    );
  }

  /// Загрузить видео
  Future<Map<String, dynamic>> uploadVideo({
    required File file,
    String? fileName,
    Function(int sent, int total)? onProgress,
  }) async {
    return uploadFile(
      file: file,
      type: 'video',
      fileName: fileName,
      onProgress: onProgress,
    );
  }

  /// Загрузить голосовое сообщение
  Future<Map<String, dynamic>> uploadVoice({
    required File file,
    String? fileName,
    Function(int sent, int total)? onProgress,
  }) async {
    return uploadFile(
      file: file,
      type: 'voice',
      fileName: fileName,
      onProgress: onProgress,
    );
  }

  /// Загрузить обычный файл
  Future<Map<String, dynamic>> uploadDocument({
    required File file,
    String? fileName,
    Function(int sent, int total)? onProgress,
  }) async {
    return uploadFile(
      file: file,
      type: 'file',
      fileName: fileName,
      onProgress: onProgress,
    );
  }

  /// Проверить размер файла
  bool _validateFileSize(int fileSize, String type) {
    switch (type) {
      case 'image':
        return fileSize <= ServerConfig.maxImageSize;
      case 'video':
        return fileSize <= ServerConfig.maxFileSize;
      case 'voice':
        return fileSize <= ServerConfig.maxVoiceSize;
      case 'file':
        return fileSize <= ServerConfig.maxFileSize;
      default:
        return fileSize <= ServerConfig.maxFileSize;
    }
  }

  /// Получить URL для предпросмотра файла
  String getPreviewUrl(String fileId, {String? thumbnail}) {
    if (thumbnail != null) {
      return '${ServerConfig.mediaServer}/api/v1/thumbnails/$thumbnail';
    }
    return ServerConfig.getFileDownloadUrl(fileId);
  }

  /// Получить URL для потокового воспроизведения (видео/аудио)
  String getStreamUrl(String fileId) {
    return '${ServerConfig.mediaServer}/api/v1/stream/$fileId';
  }
}

