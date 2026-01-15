/// Конфигурация серверов с доменами-заглушками
class ServerConfig {
  // Основной сервер для сообщений и чатов
  static const String messageServer = 'https://api.mimu.chat';
  
  // Сервер для загрузки и хранения файлов
  static const String fileServer = 'https://files.mimu.chat';
  
  // Сервер для медиа (изображения, видео)
  static const String mediaServer = 'https://media.mimu.chat';
  
  // Сервер для голосовых сообщений
  static const String voiceServer = 'https://voice.mimu.chat';
  
  // Сервер для синхронизации данных
  static const String syncServer = 'https://sync.mimu.chat';
  
  // Таймауты запросов
  static const Duration requestTimeout = Duration(seconds: 30);
  static const Duration uploadTimeout = Duration(minutes: 5);
  
  // Максимальное количество повторных попыток
  static const int maxRetries = 3;
  static const Duration retryDelay = Duration(seconds: 2);
  
  // Размеры для загрузки файлов
  static const int maxFileSize = 100 * 1024 * 1024; // 100 MB
  static const int maxImageSize = 10 * 1024 * 1024; // 10 MB
  static const int maxVoiceSize = 5 * 1024 * 1024; // 5 MB
  
  /// Получить базовый URL для API
  static String getApiBaseUrl() => messageServer;
  
  /// Получить URL для загрузки файлов
  static String getFileUploadUrl() => '$fileServer/api/v1/upload';
  
  /// Получить URL для скачивания файлов
  static String getFileDownloadUrl(String fileId) => '$fileServer/api/v1/files/$fileId';
  
  /// Получить URL для загрузки медиа
  static String getMediaUploadUrl() => '$mediaServer/api/v1/upload';
  
  /// Получить URL для голосовых сообщений
  static String getVoiceUploadUrl() => '$voiceServer/api/v1/upload';
  
  /// Получить URL для синхронизации
  static String getSyncUrl() => '$syncServer/api/v1/sync';
}

