
/// Валидация пользовательских данных
class Validators {
  /// Валидация текста сообщения
  static ValidationResult validateMessage(String text) {
    if (text.isEmpty) {
      return ValidationResult(false, 'Сообщение не может быть пустым');
    }
    
    if (text.length > 4096) {
      return ValidationResult(false, 'Сообщение слишком длинное (максимум 4096 символов)');
    }
    
    // Проверка на XSS
    if (_containsXSS(text)) {
      return ValidationResult(false, 'Сообщение содержит недопустимые символы');
    }
    
    return ValidationResult(true);
  }

  /// Валидация имени пользователя
  static ValidationResult validateUsername(String username) {
    if (username.isEmpty) {
      return ValidationResult(false, 'Имя пользователя не может быть пустым');
    }
    
    if (username.length < 3) {
      return ValidationResult(false, 'Имя пользователя должно быть не менее 3 символов');
    }
    
    if (username.length > 32) {
      return ValidationResult(false, 'Имя пользователя должно быть не более 32 символов');
    }
    
    if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(username)) {
      return ValidationResult(false, 'Имя пользователя может содержать только буквы, цифры и подчеркивание');
    }
    
    return ValidationResult(true);
  }

  /// Валидация размера файла
  static ValidationResult validateFileSize(int sizeInBytes, {int? maxSize}) {
    final max = maxSize ?? 100 * 1024 * 1024; // 100 MB по умолчанию
    
    if (sizeInBytes > max) {
      final maxMB = (max / (1024 * 1024)).toStringAsFixed(0);
      return ValidationResult(false, 'Файл слишком большой (максимум $maxMB MB)');
    }
    
    return ValidationResult(true);
  }

  /// Валидация типа файла
  static ValidationResult validateFileType(String fileName, List<String> allowedTypes) {
    final extension = fileName.split('.').last.toLowerCase();
    
    if (!allowedTypes.contains(extension)) {
      return ValidationResult(false, 'Тип файла не поддерживается');
    }
    
    return ValidationResult(true);
  }

  /// Санитизация текста (удаление потенциально опасных символов)
  static String sanitizeText(String text) {
    // Удаляем HTML теги
    text = text.replaceAll(RegExp(r'<[^>]*>'), '');
    
    // Экранируем специальные символы
    text = text
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&#x27;');
    
    return text;
  }

  /// Проверка на XSS атаки
  static bool _containsXSS(String text) {
    final xssPatterns = [
      RegExp(r'<script[^>]*>', caseSensitive: false),
      RegExp(r'javascript:', caseSensitive: false),
      RegExp(r'on\w+\s*=', caseSensitive: false), // onclick, onload, etc.
      RegExp(r'<iframe[^>]*>', caseSensitive: false),
      RegExp(r'<object[^>]*>', caseSensitive: false),
      RegExp(r'<embed[^>]*>', caseSensitive: false),
    ];
    
    for (final pattern in xssPatterns) {
      if (pattern.hasMatch(text)) {
        return true;
      }
    }
    
    return false;
  }

  /// Валидация URL
  static ValidationResult validateUrl(String url) {
    try {
      final uri = Uri.parse(url);
      if (!uri.hasScheme || (!uri.scheme.startsWith('http'))) {
        return ValidationResult(false, 'Некорректный URL');
      }
      return ValidationResult(true);
    } catch (e) {
      return ValidationResult(false, 'Некорректный URL');
    }
  }

  /// Валидация email
  static ValidationResult validateEmail(String email) {
    final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    if (!emailRegex.hasMatch(email)) {
      return ValidationResult(false, 'Некорректный email адрес');
    }
    return ValidationResult(true);
  }
}

class ValidationResult {
  final bool isValid;
  final String? errorMessage;

  ValidationResult(this.isValid, [this.errorMessage]);
}

