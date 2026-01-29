/// BIP-39 Wordlists for mnemonic phrase generation
/// Supports English and Russian languages
/// https://github.com/bitcoin/bips/blob/master/bip-0039.mediawiki

import 'package:flutter/services.dart' show rootBundle;

enum MnemonicLanguage {
  english,
  russian;

  String get displayName {
    switch (this) {
      case MnemonicLanguage.english:
        return 'English';
      case MnemonicLanguage.russian:
        return 'Русский';
    }
  }

  String get assetPath {
    switch (this) {
      case MnemonicLanguage.english:
        return 'assets/wordlists/english.txt';
      case MnemonicLanguage.russian:
        return 'assets/wordlists/russian.txt';
    }
  }
}

/// Singleton service for managing BIP-39 wordlists
class Bip39Wordlists {
  static final Bip39Wordlists _instance = Bip39Wordlists._internal();
  factory Bip39Wordlists() => _instance;
  Bip39Wordlists._internal();

  final Map<MnemonicLanguage, List<String>> _cache = {};
  bool _initialized = false;

  /// Initialize and preload all wordlists
  Future<void> init() async {
    if (_initialized) return;

    for (final lang in MnemonicLanguage.values) {
      await _loadWordlist(lang);
    }
    _initialized = true;
  }

  Future<List<String>> _loadWordlist(MnemonicLanguage language) async {
    if (_cache.containsKey(language)) {
      return _cache[language]!;
    }

    try {
      final content = await rootBundle.loadString(language.assetPath);
      final words = content
          .split('\n')
          .map((w) => w.trim().toLowerCase())
          .where((w) => w.isNotEmpty)
          .toList();

      if (words.length != 2048) {
        throw Exception(
            'Invalid wordlist for ${language.name}: expected 2048 words, got ${words.length}');
      }

      _cache[language] = words;
      return words;
    } catch (e) {
      // Wordlists must be loaded from assets
      throw Exception('Failed to load wordlist for ${language.name}: $e');
    }
  }

  /// Get wordlist for language (sync, requires init() first)
  List<String> getWordlist(MnemonicLanguage language) {
    if (!_cache.containsKey(language)) {
      throw StateError(
          'Wordlist not loaded. Call init() first or use getWordlistAsync()');
    }
    return _cache[language]!;
  }

  /// Get wordlist async (auto-loads if needed)
  Future<List<String>> getWordlistAsync(MnemonicLanguage language) async {
    return await _loadWordlist(language);
  }

  /// Detect language of a single word
  MnemonicLanguage? detectWordLanguage(String word) {
    final normalized = word.trim().toLowerCase();

    for (final lang in MnemonicLanguage.values) {
      if (_cache.containsKey(lang) && _cache[lang]!.contains(normalized)) {
        return lang;
      }
    }
    return null;
  }

  /// Detect language of a mnemonic phrase
  MnemonicLanguage? detectPhraseLanguage(String phrase) {
    final words = phrase.trim().toLowerCase().split(RegExp(r'\s+'));
    if (words.isEmpty) return null;

    for (final lang in MnemonicLanguage.values) {
      if (!_cache.containsKey(lang)) continue;
      final wordlist = _cache[lang]!;
      if (words.every((w) => wordlist.contains(w))) {
        return lang;
      }
    }
    return null;
  }

  /// Check if word is valid in specified language
  bool isValidWord(String word, MnemonicLanguage language) {
    if (!_cache.containsKey(language)) return false;
    return _cache[language]!.contains(word.trim().toLowerCase());
  }

  /// Get word index in wordlist (for BIP-39 encoding)
  int getWordIndex(String word, MnemonicLanguage language) {
    if (!_cache.containsKey(language)) {
      throw StateError('Wordlist not loaded for ${language.name}');
    }
    return _cache[language]!.indexOf(word.trim().toLowerCase());
  }

  /// Get word by index
  String getWordByIndex(int index, MnemonicLanguage language) {
    if (!_cache.containsKey(language)) {
      throw StateError('Wordlist not loaded for ${language.name}');
    }
    final wordlist = _cache[language]!;
    if (index < 0 || index >= wordlist.length) {
      throw RangeError('Index $index out of range for wordlist');
    }
    return wordlist[index];
  }

  /// Get autocomplete suggestions for a partial word
  List<String> getSuggestions(
    String partial,
    MnemonicLanguage language, {
    int maxResults = 5,
  }) {
    if (!_cache.containsKey(language)) return [];
    final normalized = partial.trim().toLowerCase();
    if (normalized.isEmpty) return [];

    return _cache[language]!
        .where((w) => w.startsWith(normalized))
        .take(maxResults)
        .toList();
  }
}

/// Convenience function for quick access
List<String> getWordlist(MnemonicLanguage language) {
  return Bip39Wordlists().getWordlist(language);
}
