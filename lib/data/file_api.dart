import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:mimu/data/services/dio_api_client.dart';
import 'package:mimu/data/server_config.dart';
import 'package:mimu/data/media_processor.dart';
import 'package:path_provider/path_provider.dart';

/// API для работы с файлами.
/// Сервер: presign (POST) → PUT в S3 по upload_url → confirm (POST).
/// Скачивание: GET /api/v1/files/{id}/presign → GET по download_url.
class FileApi {
  static final FileApi _instance = FileApi._internal();
  factory FileApi() => _instance;
  FileApi._internal();

  final _dio = DioApiClient().dio;

  /// Тип файла для сервера: image | video | audio | voice | document
  static String _serverFileType(String type) {
    switch (type) {
      case 'image':
      case 'video':
      case 'voice':
        return type;
      case 'file':
        return 'document';
      default:
        return 'document';
    }
  }

  /// Загрузить файл: presign → PUT → confirm
  Future<Map<String, dynamic>> uploadFile({
    required File file,
    required String type, // 'image', 'video', 'voice', 'file'
    String? fileName,
    Function(int sent, int total)? onProgress,
  }) async {
    try {
      File processedFile = file;
      if (type == 'image') {
        try {
          final compressed = await MediaProcessor.compressImage(file);
          if (compressed != null) processedFile = compressed;
        } catch (_) {}
      }

      final fileSize = await processedFile.length();
      if (!_validateFileSize(fileSize, type)) {
        return {
          'success': false,
          'error': 'File too large',
          'message': 'File size exceeds maximum allowed size',
        };
      }

      final name = fileName ?? processedFile.path.split(RegExp(r'[/\\]')).last;
      final contentTypes = <String, String>{
        'image': 'image/jpeg',
        'video': 'video/mp4',
        'voice': 'audio/ogg',
        'file': 'application/octet-stream',
      };
      final contentTypesByExt = <String, String>{
        'jpg': 'image/jpeg',
        'jpeg': 'image/jpeg',
        'png': 'image/png',
        'gif': 'image/gif',
        'webp': 'image/webp',
        'mp4': 'video/mp4',
        'webm': 'video/webm',
        'ogg': 'audio/ogg',
        'opus': 'audio/opus',
        'mp3': 'audio/mpeg',
        'pdf': 'application/pdf',
      };
      String contentType = contentTypes[type] ?? 'application/octet-stream';
      final ext = name.contains('.') ? name.split('.').last.toLowerCase() : '';
      if (contentTypesByExt.containsKey(ext)) {
        contentType = contentTypesByExt[ext]!;
      }

      // 1. Presign
      final presignResp = await _dio.post(
        '/api/v1/files/presign',
        data: {
          'size': fileSize,
          'content_type': contentType,
          'filename': name,
          'file_type': _serverFileType(type),
        },
      );
      final presign = presignResp.data is Map
          ? Map<String, dynamic>.from(presignResp.data as Map)
          : null;
      if (presign == null ||
          presign['file_id'] == null ||
          presign['upload_url'] == null) {
        return {'success': false, 'error': 'Invalid presign response', 'message': 'Missing file_id or upload_url'};
      }
      final fileId = presign['file_id'].toString();
      final uploadUrl = presign['upload_url'] as String;

      // 2. PUT file to presigned URL
      final bytes = await processedFile.readAsBytes();
      final putResp = await http.put(
        Uri.parse(uploadUrl),
        headers: {'Content-Type': contentType, 'Content-Length': bytes.length.toString()},
        body: bytes,
      );
      if (putResp.statusCode < 200 || putResp.statusCode >= 300) {
        return {
          'success': false,
          'error': 'Upload failed',
          'message': 'S3 upload returned ${putResp.statusCode}',
        };
      }

      // 3. Confirm
      final confirmResp = await _dio.post(
        '/api/v1/files/confirm',
        data: {
          'file_id': fileId,
          'actual_size': bytes.length,
        },
      );
      final confirm = confirmResp.data is Map
          ? Map<String, dynamic>.from(confirmResp.data as Map)
          : null;
      if (confirm == null) {
        return {'success': false, 'error': 'Invalid confirm response', 'message': 'Empty body'};
      }

      final downloadUrl = confirm['download_url'] as String? ?? '';
      return {
        'success': true,
        'fileId': fileId,
        'url': downloadUrl,
        'size': bytes.length,
        'mimeType': contentType,
      };
    } catch (e) {
      return {
        'success': false,
        'error': 'Upload failed',
        'message': e.toString(),
      };
    }
  }

  /// Скачать файл: получить presigned download URL, затем GET
  Future<Map<String, dynamic>> downloadFile({
    required String fileId,
    String? fileName,
    Function(int received, int total)? onProgress,
  }) async {
    try {
      final presignResp = await _dio.get('/api/v1/files/$fileId/presign');
      final presign = presignResp.data is Map
          ? Map<String, dynamic>.from(presignResp.data as Map)
          : null;
      final downloadUrl = presign?['download_url'] as String?;
      if (downloadUrl == null || downloadUrl.isEmpty) {
        return {'success': false, 'error': 'No download URL', 'message': 'Presign response missing download_url'};
      }

      final response = await http.get(Uri.parse(downloadUrl))
          .timeout(ServerConfig.uploadTimeout);
      if (response.statusCode != 200) {
        return {
          'success': false,
          'error': 'Download failed',
          'statusCode': response.statusCode,
        };
      }

      final directory = await getApplicationDocumentsDirectory();
      final downloadsDir = Directory('${directory.path}/downloads');
      if (!await downloadsDir.exists()) {
        await downloadsDir.create(recursive: true);
      }
      final savePath = '${downloadsDir.path}/${fileName ?? fileId}';
      final f = File(savePath);
      await f.writeAsBytes(response.bodyBytes);

      return {
        'success': true,
        'filePath': savePath,
        'size': response.bodyBytes.length,
      };
    } catch (e) {
      return {
        'success': false,
        'error': 'Download failed',
        'message': e.toString(),
      };
    }
  }

  /// Получить информацию о файле (GET /api/v1/files/{id}/info)
  Future<Map<String, dynamic>> getFileInfo(String fileId) async {
    try {
      final resp = await _dio.get('/api/v1/files/$fileId/info');
      final data = resp.data is Map ? Map<String, dynamic>.from(resp.data as Map) : <String, dynamic>{};
      return {'success': true, 'data': data};
    } catch (e) {
      return {'success': false, 'error': e.toString(), 'message': e.toString()};
    }
  }

  /// Удалить файл (DELETE /api/v1/files/{id})
  Future<Map<String, dynamic>> deleteFile(String fileId) async {
    try {
      await _dio.delete('/api/v1/files/$fileId');
      return {'success': true};
    } catch (e) {
      return {'success': false, 'error': e.toString(), 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> uploadImage({
    required File file,
    String? fileName,
    Function(int sent, int total)? onProgress,
  }) =>
      uploadFile(file: file, type: 'image', fileName: fileName, onProgress: onProgress);

  Future<Map<String, dynamic>> uploadVideo({
    required File file,
    String? fileName,
    Function(int sent, int total)? onProgress,
  }) =>
      uploadFile(file: file, type: 'video', fileName: fileName, onProgress: onProgress);

  Future<Map<String, dynamic>> uploadVoice({
    required File file,
    String? fileName,
    Function(int sent, int total)? onProgress,
  }) =>
      uploadFile(file: file, type: 'voice', fileName: fileName, onProgress: onProgress);

  Future<Map<String, dynamic>> uploadDocument({
    required File file,
    String? fileName,
    Function(int sent, int total)? onProgress,
  }) =>
      uploadFile(file: file, type: 'file', fileName: fileName, onProgress: onProgress);

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

  /// Предпросмотр: для превью нужно получить presigned URL по file_id (или thumbnail_key)
  String getPreviewUrl(String fileId, {String? thumbnail}) {
    if (thumbnail != null) {
      return '${ServerConfig.mediaServer}/api/v1/thumbnails/$thumbnail';
    }
    return '${ServerConfig.getApiBaseUrl()}/api/v1/files/$fileId/presign';
  }

  String getStreamUrl(String fileId) {
    return '${ServerConfig.mediaServer}/api/v1/stream/$fileId';
  }
}
