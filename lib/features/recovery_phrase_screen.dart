import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'package:mimu/data/services/crypto_auth_service.dart';
import 'package:mimu/data/services/bip39_wordlists.dart';

/// Mode for the recovery phrase screen
enum RecoveryPhraseMode {
  /// Display generated phrase (registration)
  display,
  /// Input phrase for recovery
  input,
}

/// Screen for displaying or inputting BIP-39 recovery phrase
class RecoveryPhraseScreen extends StatefulWidget {
  final RecoveryPhraseMode mode;
  final String? generatedPhrase;
  final MnemonicLanguage? generatedLanguage;
  final void Function(String phrase, MnemonicLanguage language)? onPhraseConfirmed;
  final VoidCallback? onBack;

  const RecoveryPhraseScreen({
    super.key,
    required this.mode,
    this.generatedPhrase,
    this.generatedLanguage,
    this.onPhraseConfirmed,
    this.onBack,
  });

  @override
  State<RecoveryPhraseScreen> createState() => _RecoveryPhraseScreenState();
}

class _RecoveryPhraseScreenState extends State<RecoveryPhraseScreen> {
  final CryptoAuthService _cryptoService = CryptoAuthService();
  final List<TextEditingController> _wordControllers = List.generate(
    12,
    (_) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(12, (_) => FocusNode());
  final List<String?> _wordErrors = List.filled(12, null);

  MnemonicLanguage _selectedLanguage = MnemonicLanguage.english;
  bool _isLoading = false;
  bool _hasConfirmedBackup = false;
  bool _showPhrase = false;
  String? _errorMessage;
  List<String> _suggestions = [];
  int _activeSuggestionIndex = -1;

  @override
  void initState() {
    super.initState();
    _initService();

    if (widget.mode == RecoveryPhraseMode.display && widget.generatedPhrase != null) {
      _selectedLanguage = widget.generatedLanguage ?? MnemonicLanguage.english;
      final words = widget.generatedPhrase!.split(' ');
      for (int i = 0; i < words.length && i < 12; i++) {
        _wordControllers[i].text = words[i];
      }
    }

    // Add listeners for autocomplete
    for (int i = 0; i < 12; i++) {
      _wordControllers[i].addListener(() => _onWordChanged(i));
      _focusNodes[i].addListener(() {
        if (_focusNodes[i].hasFocus) {
          _onWordChanged(i);
        } else {
          setState(() => _suggestions = []);
        }
      });
    }
  }

  Future<void> _initService() async {
    setState(() => _isLoading = true);
    try {
      await _cryptoService.init();
    } catch (e) {
      debugPrint('Failed to init crypto service: $e');
    }
    setState(() => _isLoading = false);
  }

  @override
  void dispose() {
    for (final controller in _wordControllers) {
      controller.dispose();
    }
    for (final node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  void _onWordChanged(int index) {
    final text = _wordControllers[index].text.trim().toLowerCase();

    if (text.isEmpty) {
      setState(() {
        _suggestions = [];
        _wordErrors[index] = null;
      });
      return;
    }

    // Get suggestions
    final wordlists = Bip39Wordlists();
    final suggestions = wordlists.getSuggestions(text, _selectedLanguage, maxResults: 5);

    // Validate word
    String? error;
    if (text.isNotEmpty && !wordlists.isValidWord(text, _selectedLanguage)) {
      // Check if it's valid in another language
      final otherLang = _selectedLanguage == MnemonicLanguage.english
          ? MnemonicLanguage.russian
          : MnemonicLanguage.english;
      if (wordlists.isValidWord(text, otherLang)) {
        error = 'Word from ${otherLang.displayName} wordlist';
      } else if (suggestions.isEmpty) {
        error = 'Invalid word';
      }
    }

    setState(() {
      _suggestions = suggestions;
      _wordErrors[index] = error;
      _activeSuggestionIndex = -1;
    });
  }

  void _selectSuggestion(String word, int fieldIndex) {
    _wordControllers[fieldIndex].text = word;
    _wordControllers[fieldIndex].selection = TextSelection.fromPosition(
      TextPosition(offset: word.length),
    );
    setState(() {
      _suggestions = [];
      _wordErrors[fieldIndex] = null;
    });

    // Move to next field
    if (fieldIndex < 11) {
      _focusNodes[fieldIndex + 1].requestFocus();
    } else {
      _focusNodes[fieldIndex].unfocus();
    }
  }

  void _onLanguageChanged(MnemonicLanguage? language) {
    if (language == null) return;
    setState(() {
      _selectedLanguage = language;
      _errorMessage = null;
    });

    // Re-validate all words
    for (int i = 0; i < 12; i++) {
      _onWordChanged(i);
    }
  }

  String _getFullPhrase() {
    return _wordControllers.map((c) => c.text.trim().toLowerCase()).join(' ');
  }

  Future<void> _validateAndConfirm() async {
    final phrase = _getFullPhrase();
    final validation = _cryptoService.validateMnemonic(phrase);

    if (!validation.isValid) {
      setState(() => _errorMessage = validation.error);
      return;
    }

    // Auto-detect language if different from selected
    if (validation.detectedLanguage != null &&
        validation.detectedLanguage != _selectedLanguage) {
      setState(() {
        _selectedLanguage = validation.detectedLanguage!;
      });
    }

    widget.onPhraseConfirmed?.call(phrase, _selectedLanguage);
  }

  void _copyToClipboard() {
    final phrase = _getFullPhrase();
    Clipboard.setData(ClipboardData(text: phrase));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Recovery phrase copied to clipboard'),
        backgroundColor: Colors.green.shade700,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _pasteFromClipboard() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data?.text == null) return;

    final words = data!.text!.trim().split(RegExp(r'\s+'));
    for (int i = 0; i < words.length && i < 12; i++) {
      _wordControllers[i].text = words[i].toLowerCase();
    }

    // Auto-detect language
    final phrase = _getFullPhrase();
    final wordlists = Bip39Wordlists();
    final detectedLang = wordlists.detectPhraseLanguage(phrase);
    if (detectedLang != null) {
      setState(() => _selectedLanguage = detectedLang);
    }

    // Validate all words
    for (int i = 0; i < 12; i++) {
      _onWordChanged(i);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDisplayMode = widget.mode == RecoveryPhraseMode.display;

    return Scaffold(
      backgroundColor: Colors.transparent, // Transparent to show parent background
      body: Stack(
        children: [
          // Main content
          SafeArea(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Colors.white))
                : CustomScrollView(
                    slivers: [
                      // Header
                      SliverToBoxAdapter(
                        child: _buildHeader(isDisplayMode),
                      ),

                      // Language selector
                      SliverToBoxAdapter(
                        child: _buildLanguageSelector(),
                      ),

                      // Word grid
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        sliver: SliverToBoxAdapter(
                          child: _buildWordGrid(isDisplayMode),
                        ),
                      ),

                      // Error message
                      if (_errorMessage != null)
                        SliverToBoxAdapter(
                          child: _buildErrorMessage(),
                        ),

                      // Actions
                      SliverToBoxAdapter(
                        child: _buildActions(isDisplayMode),
                      ),

                      // Bottom padding
                      const SliverToBoxAdapter(
                        child: SizedBox(height: 40),
                      ),
                    ],
                  ),
          ),

          // Suggestions overlay
          if (_suggestions.isNotEmpty) _buildSuggestionsOverlay(),
        ],
      ),
    );
  }

  Widget _buildHeader(bool isDisplayMode) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Back button
          if (widget.onBack != null)
            IconButton(
              onPressed: widget.onBack,
              icon: const Icon(PhosphorIconsRegular.arrowLeft, color: Colors.white),
              style: IconButton.styleFrom(
                backgroundColor: const Color(0xFF2C2C2E).withOpacity(0.6),
              ),
            ),

          const SizedBox(height: 20),

          // Title
          Text(
            isDisplayMode ? 'Your Recovery Phrase' : 'Enter Recovery Phrase',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ).animate().fadeIn(duration: 300.ms).slideX(begin: -0.1),

          const SizedBox(height: 12),

          // Description
          Text(
            isDisplayMode
                ? 'Write down these 12 words in order. This is the ONLY way to recover your account. Keep it secret and safe!'
                : 'Enter your 12-word recovery phrase to restore your account.',
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 15,
              height: 1.5,
            ),
          ).animate().fadeIn(duration: 300.ms, delay: 100.ms),

          if (isDisplayMode) ...[
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.orange.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(PhosphorIconsRegular.warning, color: Colors.orange.shade300, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Never share this phrase with anyone. Mimu staff will never ask for it.',
                          style: TextStyle(
                            color: Colors.orange.shade200,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ).animate().fadeIn(duration: 300.ms, delay: 200.ms),
          ],
        ],
      ),
    );
  }

  Widget _buildLanguageSelector() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF2C2C2E).withOpacity(0.6),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
            ),
            child: Row(
              children: [
                Text(
                  'Phrase Language:',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withOpacity(0.2)),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<MnemonicLanguage>(
                      value: _selectedLanguage,
                      dropdownColor: const Color(0xFF2C2C2E),
                      style: const TextStyle(color: Colors.white),
                      icon: Icon(
                        PhosphorIconsRegular.caretDown,
                        color: Colors.white.withOpacity(0.7),
                        size: 16,
                      ),
                      items: MnemonicLanguage.values.map((lang) {
                        return DropdownMenuItem(
                          value: lang,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                lang == MnemonicLanguage.english ? '🇬🇧' : '🇷🇺',
                                style: const TextStyle(fontSize: 16),
                              ),
                              const SizedBox(width: 8),
                              Text(lang.displayName),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: widget.mode == RecoveryPhraseMode.display
                          ? null
                          : _onLanguageChanged,
                    ),
                  ),
                ),
                const Spacer(),
                if (widget.mode == RecoveryPhraseMode.input)
                  TextButton.icon(
                    onPressed: _pasteFromClipboard,
                    icon: const Icon(PhosphorIconsRegular.clipboard, size: 18),
                    label: const Text('Paste'),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.white.withOpacity(0.7),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    ).animate().fadeIn(duration: 300.ms, delay: 150.ms);
  }

  Widget _buildWordGrid(bool isDisplayMode) {
    return Column(
      children: [
        // Show/Hide toggle for display mode
        if (isDisplayMode)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextButton.icon(
                  onPressed: () => setState(() => _showPhrase = !_showPhrase),
                  icon: Icon(
                    _showPhrase
                        ? PhosphorIconsRegular.eyeSlash
                        : PhosphorIconsRegular.eye,
                    size: 18,
                  ),
                  label: Text(_showPhrase ? 'Hide Phrase' : 'Show Phrase'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.white.withOpacity(0.8),
                    backgroundColor: Colors.white.withOpacity(0.1),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                ),
              ],
            ),
          ),

        // Word grid (2 columns x 6 rows)
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF2C2C2E).withOpacity(0.6),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withOpacity(0.1)),
              ),
              child: Column(
                children: List.generate(6, (row) {
                  return Padding(
                    padding: EdgeInsets.only(bottom: row < 5 ? 12 : 0),
                    child: Row(
                      children: [
                        _buildWordField(row * 2, isDisplayMode),
                        const SizedBox(width: 12),
                        _buildWordField(row * 2 + 1, isDisplayMode),
                      ],
                    ),
                  );
                }),
              ),
            ),
          ),
        ).animate().fadeIn(duration: 400.ms, delay: 200.ms).scale(begin: const Offset(0.95, 0.95)),
      ],
    );
  }

  Widget _buildWordField(int index, bool isDisplayMode) {
    final hasError = _wordErrors[index] != null;
    final word = _wordControllers[index].text;
    final isHidden = isDisplayMode && !_showPhrase;

    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            decoration: BoxDecoration(
              color: hasError
                  ? Colors.red.withOpacity(0.1)
                  : Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: hasError
                    ? Colors.red.withOpacity(0.5)
                    : _focusNodes[index].hasFocus
                        ? Colors.blue.withOpacity(0.5)
                        : Colors.white.withOpacity(0.1),
              ),
            ),
            child: Row(
              children: [
                // Index number
                Container(
                  width: 32,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(11),
                      bottomLeft: Radius.circular(11),
                    ),
                  ),
                  child: Text(
                    '${index + 1}',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.5),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),

                // Word input/display
                Expanded(
                  child: isDisplayMode
                      ? Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 14,
                          ),
                          child: Text(
                            isHidden ? '••••••' : word,
                            style: TextStyle(
                              color: Colors.white.withOpacity(isHidden ? 0.3 : 0.9),
                              fontSize: 14,
                              fontFamily: isHidden ? null : 'monospace',
                            ),
                          ),
                        )
                      : TextField(
                          controller: _wordControllers[index],
                          focusNode: _focusNodes[index],
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                          ),
                          decoration: InputDecoration(
                            hintText: 'word ${index + 1}',
                            hintStyle: TextStyle(
                              color: Colors.white.withOpacity(0.3),
                              fontSize: 14,
                            ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 14,
                            ),
                          ),
                          textInputAction: index < 11
                              ? TextInputAction.next
                              : TextInputAction.done,
                          onSubmitted: (_) {
                            if (index < 11) {
                              _focusNodes[index + 1].requestFocus();
                            }
                          },
                          autocorrect: false,
                          enableSuggestions: false,
                        ),
                ),
              ],
            ),
          ),

          // Error text
          if (hasError)
            Padding(
              padding: const EdgeInsets.only(top: 4, left: 4),
              child: Text(
                _wordErrors[index]!,
                style: TextStyle(
                  color: Colors.red.shade300,
                  fontSize: 11,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSuggestionsOverlay() {
    // Find active field index
    int activeIndex = -1;
    for (int i = 0; i < 12; i++) {
      if (_focusNodes[i].hasFocus) {
        activeIndex = i;
        break;
      }
    }

    if (activeIndex == -1) return const SizedBox.shrink();

    return Positioned(
      left: 20,
      right: 20,
      bottom: 100,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF2C2C2E).withOpacity(0.9),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withOpacity(0.2)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.5),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: _suggestions.asMap().entries.map((entry) {
                final idx = entry.key;
                final word = entry.value;
                final isSelected = idx == _activeSuggestionIndex;

                return InkWell(
                  onTap: () => _selectSuggestion(word, activeIndex),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    color: isSelected ? Colors.white.withOpacity(0.1) : null,
                    child: Text(
                      word,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 15,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ),
    ).animate().fadeIn(duration: 150.ms);
  }

  Widget _buildErrorMessage() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.red.withOpacity(0.5)),
            ),
            child: Row(
              children: [
                Icon(PhosphorIconsRegular.warningCircle, color: Colors.red.shade300, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _errorMessage!,
                    style: TextStyle(
                      color: Colors.red.shade200,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActions(bool isDisplayMode) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          if (isDisplayMode) ...[
            // Confirmation checkbox
            GestureDetector(
              onTap: () => setState(() => _hasConfirmedBackup = !_hasConfirmedBackup),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF2C2C2E).withOpacity(0.6),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _hasConfirmedBackup
                        ? Colors.green.withOpacity(0.5)
                        : Colors.white.withOpacity(0.1),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: _hasConfirmedBackup
                            ? Colors.green
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: _hasConfirmedBackup
                              ? Colors.green
                              : Colors.white.withOpacity(0.3),
                          width: 2,
                        ),
                      ),
                      child: _hasConfirmedBackup
                          ? const Icon(
                              PhosphorIconsBold.check,
                              color: Colors.white,
                              size: 16,
                            )
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'I have written down my recovery phrase and stored it safely',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Copy button
            OutlinedButton.icon(
              onPressed: _showPhrase ? _copyToClipboard : null,
              icon: const Icon(PhosphorIconsRegular.copy, size: 18),
              label: const Text('Copy to Clipboard'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white.withOpacity(0.7),
                side: BorderSide(color: Colors.white.withOpacity(0.2)),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                minimumSize: const Size(double.infinity, 50),
              ),
            ),
            const SizedBox(height: 12),
          ],

          // Main action button
          ElevatedButton(
            onPressed: isDisplayMode
                ? (_hasConfirmedBackup ? _validateAndConfirm : null)
                : _validateAndConfirm,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.black,
              disabledBackgroundColor: Colors.grey.shade800,
              disabledForegroundColor: Colors.grey.shade500,
              padding: const EdgeInsets.symmetric(vertical: 16),
              minimumSize: const Size(double.infinity, 54),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              isDisplayMode ? 'Continue' : 'Restore Account',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms, delay: 300.ms);
  }
}
