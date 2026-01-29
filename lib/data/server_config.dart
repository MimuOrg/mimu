import 'package:shared_preferences/shared_preferences.dart';

/// Конфигурация серверов с доменами-заглушками
class ServerConfig {
  static const String _serverKey = 'dev_server_url';
  
  // Основной сервер для сообщений и чатов
  // Берем из переменных окружения или используем fallback для разработки
  static String get _defaultMessageServer {
    const envUrl = String.fromEnvironment('API_BASE_URL');
    if (envUrl.isNotEmpty) return envUrl;
    // Fallback для разработки (можно переопределить через setApiBaseUrl)
    return 'http://localhost:8080';
  }
  
  // Сервер для загрузки и хранения файлов (использует тот же базовый URL)
  static String get fileServer => _cachedServerUrl ?? _defaultMessageServer;
  
  // Сервер для медиа (изображения, видео)
  static String get mediaServer => _cachedServerUrl ?? _defaultMessageServer;
  
  // Сервер для голосовых сообщений
  static String get voiceServer => _cachedServerUrl ?? _defaultMessageServer;
  
  // Сервер для синхронизации данных
  static String get syncServer => _cachedServerUrl ?? _defaultMessageServer;
  
  // Таймауты запросов (увеличены для мобильной сети)
  static const Duration requestTimeout = Duration(seconds: 15);
  static const Duration uploadTimeout = Duration(minutes: 5);
  
  // Максимальное количество повторных попыток
  static const int maxRetries = 3;
  static const Duration retryDelay = Duration(seconds: 2);
  
  // Размеры для загрузки файлов
  static const int maxFileSize = 100 * 1024 * 1024; // 100 MB
  static const int maxImageSize = 10 * 1024 * 1024; // 10 MB
  static const int maxVoiceSize = 5 * 1024 * 1024; // 5 MB
  
  static String? _cachedServerUrl;

  /// Получить базовый URL для API (синхронная версия для обратной совместимости)
  static String getApiBaseUrl() {
    // Для обратной совместимости используем кеш или дефолтное значение
    // В реальном приложении нужно инициализировать при старте
    return _cachedServerUrl ?? _defaultMessageServer;
  }

  /// Геттер для обратной совместимости (алиас для getApiBaseUrl)
  static String get baseUrl => getApiBaseUrl();

  /// Получить базовый URL для API (асинхронная версия)
  static Future<String> getApiBaseUrlAsync() async {
    final prefs = await SharedPreferences.getInstance();
    final url = prefs.getString(_serverKey) ?? _defaultMessageServer;
    _cachedServerUrl = url;
    return url;
  }

  /// Инициализировать конфигурацию (вызывать при старте приложения)
  static Future<void> init() async {
    _cachedServerUrl = await getApiBaseUrlAsync();
  }

  /// Установить базовый URL для API (для режима разработчика)
  static Future<void> setApiBaseUrl(String url) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_serverKey, url);
    _cachedServerUrl = url;
  }
  
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

  /// База ссылки для приглашения в приватный чат/канал: t.mimu.app/join/{token}
  static const String inviteLinkBase = 'https://t.mimu.app/join';
  static String getInviteLink(String inviteToken) => '$inviteLinkBase/$inviteToken';
}

