import 'dart:io';
import 'dart:typed_data';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';

/// Обработка медиа файлов (сжатие, оптимизация)
class MediaProcessor {
  /// Сжать изображение
  static Future<File?> compressImage(
    File imageFile, {
    int maxWidth = 1920,
    int maxHeight = 1920,
    int quality = 85,
  }) async {
    try {
      final bytes = await imageFile.readAsBytes();
      final image = img.decodeImage(bytes);
      
      if (image == null) return null;
      
      // Изменяем размер если нужно
      img.Image resized = image;
      if (image.width > maxWidth || image.height > maxHeight) {
        resized = img.copyResize(
          image,
          width: image.width > image.height ? maxWidth : null,
          height: image.height > image.width ? maxHeight : null,
          maintainAspect: true,
        );
      }
      
      // Сжимаем JPEG
      final compressedBytes = img.encodeJpg(resized, quality: quality);
      
      // Сохраняем во временный файл
      final tempDir = await getTemporaryDirectory();
      final compressedFile = File('${tempDir.path}/compressed_${DateTime.now().millisecondsSinceEpoch}.jpg');
      await compressedFile.writeAsBytes(compressedBytes);
      
      return compressedFile;
    } catch (e) {
      print('Error compressing image: $e');
      return null;
    }
  }

  /// Создать thumbnail изображения
  static Future<Uint8List?> createThumbnail(
    File imageFile, {
    int width = 200,
    int height = 200,
  }) async {
    try {
      final bytes = await imageFile.readAsBytes();
      final image = img.decodeImage(bytes);
      
      if (image == null) return null;
      
      final thumbnail = img.copyResize(
        image,
        width: width,
        height: height,
        maintainAspect: true,
      );
      
      return Uint8List.fromList(img.encodeJpg(thumbnail, quality: 70));
    } catch (e) {
      print('Error creating thumbnail: $e');
      return null;
    }
  }

  /// Получить информацию о медиа файле
  static Future<MediaInfo?> getMediaInfo(File file) async {
    try {
      final stat = await file.stat();
      final extension = file.path.split('.').last.toLowerCase();
      
      MediaType type;
      if (['jpg', 'jpeg', 'png', 'gif', 'webp'].contains(extension)) {
        type = MediaType.image;
      } else if (['mp4', 'mov', 'avi', 'mkv'].contains(extension)) {
        type = MediaType.video;
      } else if (['mp3', 'wav', 'm4a', 'aac'].contains(extension)) {
        type = MediaType.audio;
      } else {
        type = MediaType.file;
      }
      
      return MediaInfo(
        path: file.path,
        size: stat.size,
        type: type,
        extension: extension,
      );
    } catch (e) {
      return null;
    }
  }

  /// Проверить, нужно ли сжимать изображение
  static Future<bool> shouldCompress(File imageFile, {int maxSize = 5 * 1024 * 1024}) async {
    final stat = await imageFile.stat();
    return stat.size > maxSize;
  }
}

enum MediaType {
  image,
  video,
  audio,
  file,
}

class MediaInfo {
  final String path;
  final int size;
  final MediaType type;
  final String extension;

  MediaInfo({
    required this.path,
    required this.size,
    required this.type,
    required this.extension,
  });
}

