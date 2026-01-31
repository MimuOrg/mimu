import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'package:mimu/app/routes.dart';
import 'package:mimu/data/services/auth_service.dart';
import 'package:mimu/data/services/bip39_wordlists.dart';
import 'package:mimu/features/recovery_phrase_screen.dart';
import 'package:mimu/shared/app_styles.dart';

/// Screen for selecting authentication method
class AuthMethodScreen extends StatefulWidget {
  const AuthMethodScreen({super.key});

  @override
  State<AuthMethodScreen> createState() => _AuthMethodScreenState();
}

class _AuthMethodScreenState extends State<AuthMethodScreen> {
  final AuthService _authService = AuthService();
  bool _isInitializing = true;

  @override
  void initState() {
    super.initState();
    _initServices();
  }

  Future<void> _initServices() async {
    await _authService.init();
    setState(() => _isInitializing = false);
  }

  void _navigateToCreateAccount() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const _CreateAccountFlow(),
      ),
    );
  }

  void _navigateToRestoreAccount() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const _RestoreAccountFlow(),
      ),
    );
  }

  void _navigateToLegacyLogin() {
    Navigator.of(context).pushNamed(AppRoutes.authLegacy);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppStyles.backgroundOled,
      body: Stack(
        children: [
          // Background Image
          _buildBackground(),

          // Main content
          SafeArea(
            child: _isInitializing
                ? const Center(child: CircularProgressIndicator())
                : _buildContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildBackground() {
    return const SizedBox.expand(
      child: ColoredBox(color: AppStyles.backgroundOled),
    );
  }

  Widget _buildContent() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          const Spacer(flex: 2),

          // Logo/Icon with Glass Effect
          Container(
            width: 100,
            height: 100,
            decoration: AppStyles.surfaceDecoration(borderRadius: 50),
            child: const Icon(
              PhosphorIconsBold.shieldCheck,
              color: Colors.white,
              size: 48,
            ),
          ).animate().scale(duration: 500.ms, curve: Curves.elasticOut),

          const SizedBox(height: 32),

          // Title
          Text(
            'Welcome to Mimu',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 30,
              fontWeight: FontWeight.w700,
              fontFamily: AppStyles.fontFamily,
              letterSpacing: AppStyles.letterSpacingSignature,
            ),
            textAlign: TextAlign.center,
          ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.2),

          const SizedBox(height: 12),

          // Subtitle
          Text(
            'Secure messaging powered by cryptography.\nNo email or phone number required.',
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 16,
              height: 1.5,
              fontFamily: AppStyles.fontFamily,
            ),
            textAlign: TextAlign.center,
          ).animate().fadeIn(duration: 400.ms, delay: 100.ms),

          const Spacer(flex: 1),

          // Create Account Button (Primary)
          _AuthMethodButton(
            icon: PhosphorIconsRegular.keyReturn,
            title: 'Create New Account',
            subtitle: 'Get a 12-word recovery phrase',
            isPrimary: true,
            onTap: _navigateToCreateAccount,
          ).animate().fadeIn(duration: 400.ms, delay: 200.ms).slideY(begin: 0.1),

          const SizedBox(height: 16),

          // Restore Account Button
          _AuthMethodButton(
            icon: PhosphorIconsRegular.arrowsClockwise,
            title: 'Restore Account',
            subtitle: 'Enter your 12-word recovery phrase',
            isPrimary: false,
            onTap: _navigateToRestoreAccount,
          ).animate().fadeIn(duration: 400.ms, delay: 300.ms).slideY(begin: 0.1),

          const Spacer(flex: 1),

          // Legacy login link
          TextButton(
            onPressed: _navigateToLegacyLogin,
            child: Text(
              'Login with password instead',
              style: TextStyle(
                color: Colors.white.withOpacity(0.5),
                fontSize: 14,
              ),
            ),
          ).animate().fadeIn(duration: 400.ms, delay: 400.ms),

          const SizedBox(height: 16),

          // Terms and privacy
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              'By continuing, you agree to our Terms of Service and Privacy Policy',
              style: TextStyle(
                color: Colors.white.withOpacity(0.4),
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
          ).animate().fadeIn(duration: 400.ms, delay: 500.ms),

          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

/// Custom button widget for auth method selection with dark glass style
class _AuthMethodButton extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool isPrimary;
  final VoidCallback onTap;

  const _AuthMethodButton({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.isPrimary,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: AppStyles.surfaceDecoration(
          color: isPrimary
              ? Theme.of(context).primaryColor.withOpacity(0.12)
              : AppStyles.surfaceDeep,
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: AppStyles.surfaceDecoration(
                borderRadius: 16,
                color: isPrimary
                    ? Theme.of(context).primaryColor.withOpacity(0.18)
                    : AppStyles.surfaceDeep,
              ),
              child: Icon(
                icon,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      fontFamily: AppStyles.fontFamily,
                      letterSpacing: -0.4,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 13,
                      fontFamily: AppStyles.fontFamily,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              PhosphorIconsRegular.caretRight,
              color: Colors.white.withOpacity(0.5),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

/// Flow for creating a new account with recovery phrase
class _CreateAccountFlow extends StatefulWidget {
  const _CreateAccountFlow();

  @override
  State<_CreateAccountFlow> createState() => _CreateAccountFlowState();
}

class _CreateAccountFlowState extends State<_CreateAccountFlow> {
  final AuthService _authService = AuthService();
  final PageController _pageController = PageController();
  final TextEditingController _displayNameController = TextEditingController();

  MnemonicLanguage _selectedLanguage = MnemonicLanguage.english;
  String? _generatedMnemonic;
  bool _isLoading = false;
  String? _error;
  int _currentStep = 0;

  @override
  void dispose() {
    _pageController.dispose();
    _displayNameController.dispose();
    super.dispose();
  }

  void _selectLanguage(MnemonicLanguage language) {
    setState(() {
      _selectedLanguage = language;
      _generatedMnemonic = _authService.generateMnemonic(language: language);
    });
    _pageController.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
    setState(() => _currentStep = 1);
  }

  void _onPhraseConfirmed(String phrase, MnemonicLanguage language) {
    _pageController.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
    setState(() => _currentStep = 2);
  }

  Future<void> _completeRegistration() async {
    final displayName = _displayNameController.text.trim();
    if (displayName.isEmpty) {
      setState(() => _error = 'Please enter a display name');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final result = await _authService.registerWithCrypto(
        displayName: displayName,
        language: _selectedLanguage == MnemonicLanguage.russian ? 'ru' : 'en',
      );

      if (result.success) {
        if (mounted) {
          Navigator.of(context).pushNamedAndRemoveUntil('/home', (route) => false);
        }
      } else {
        setState(() => _error = result.error ?? 'Registration failed');
      }
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppStyles.backgroundOled,
      body: Stack(
        children: [
          // Background
          SizedBox.expand(
            child: Container(color: AppStyles.backgroundOled),
          ),

          // Content
          SafeArea(
            child: Column(
              children: [
                // Progress indicator
                _buildProgressIndicator(),

                // Pages
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      _buildLanguageSelection(),
                      if (_generatedMnemonic != null)
                        RecoveryPhraseScreen(
                          mode: RecoveryPhraseMode.display,
                          generatedPhrase: _generatedMnemonic,
                          generatedLanguage: _selectedLanguage,
                          onPhraseConfirmed: _onPhraseConfirmed,
                          onBack: () {
                            _pageController.previousPage(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            );
                            setState(() => _currentStep = 0);
                          },
                        ),
                      _buildProfileSetup(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          // Back button
          if (_currentStep > 0)
            IconButton(
              onPressed: () {
                _pageController.previousPage(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
                setState(() => _currentStep--);
              },
              icon: const Icon(PhosphorIconsRegular.arrowLeft, color: Colors.white),
              style: IconButton.styleFrom(
                backgroundColor: const Color(0xFF2C2C2E).withOpacity(0.6),
              ),
            )
          else
            IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(PhosphorIconsRegular.x, color: Colors.white),
              style: IconButton.styleFrom(
                backgroundColor: const Color(0xFF2C2C2E).withOpacity(0.6),
              ),
            ),

          const Spacer(),

          // Step indicators
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF2C2C2E).withOpacity(0.6),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(3, (index) {
                final isActive = index <= _currentStep;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: index == _currentStep ? 24 : 8,
                  height: 8,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    color: isActive
                        ? Colors.white
                        : Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                );
              }),
            ),
          ),

          const Spacer(),
          const SizedBox(width: 48), // Balance the back button
        ],
      ),
    );
  }

  Widget _buildLanguageSelection() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),

          Text(
            'Choose Phrase Language',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ).animate().fadeIn(duration: 300.ms),

          const SizedBox(height: 12),

          Text(
            'Select the language for your 12-word recovery phrase. You can choose English or Russian.',
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 15,
              height: 1.5,
            ),
          ).animate().fadeIn(duration: 300.ms, delay: 100.ms),

          const SizedBox(height: 40),

          // English option
          _LanguageOption(
            flag: '🇬🇧',
            title: 'English',
            subtitle: 'Most compatible with other wallets',
            isSelected: _selectedLanguage == MnemonicLanguage.english,
            onTap: () => _selectLanguage(MnemonicLanguage.english),
          ).animate().fadeIn(duration: 300.ms, delay: 200.ms).slideX(begin: -0.1),

          const SizedBox(height: 16),

          // Russian option
          _LanguageOption(
            flag: '🇷🇺',
            title: 'Русский',
            subtitle: 'Native Russian wordlist',
            isSelected: _selectedLanguage == MnemonicLanguage.russian,
            onTap: () => _selectLanguage(MnemonicLanguage.russian),
          ).animate().fadeIn(duration: 300.ms, delay: 300.ms).slideX(begin: -0.1),

          const Spacer(),

          // Info box
          Container(
            padding: const EdgeInsets.all(16),
            decoration: AppStyles.surfaceDecoration(
              borderRadius: 18,
              color: Theme.of(context).primaryColor.withOpacity(0.10),
            ),
            child: Row(
              children: [
                Icon(
                  PhosphorIconsRegular.info,
                  color: Theme.of(context).primaryColor,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Your recovery phrase is the only way to access your account. Store it safely offline.',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.85),
                      fontSize: 13,
                      height: 1.4,
                      fontFamily: AppStyles.fontFamily,
                    ),
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(duration: 300.ms, delay: 400.ms),
        ],
      ),
    );
  }

  Widget _buildProfileSetup() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),

          Text(
            'Set Up Your Profile',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 12),

          Text(
            'Choose a display name that others will see.',
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 15,
            ),
          ),

          const SizedBox(height: 40),

          // Display name field
          Container(
            decoration: AppStyles.surfaceDecoration(borderRadius: 18),
            child: TextField(
              controller: _displayNameController,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontFamily: AppStyles.fontFamily,
              ),
              decoration: InputDecoration(
                labelText: 'Display Name',
                labelStyle: TextStyle(color: Colors.white.withOpacity(0.7), fontFamily: AppStyles.fontFamily),
                hintText: 'e.g. John Doe',
                hintStyle: TextStyle(color: Colors.white.withOpacity(0.3), fontFamily: AppStyles.fontFamily),
                prefixIcon: Icon(
                  PhosphorIconsRegular.user,
                  color: Colors.white.withOpacity(0.5),
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.all(16),
              ),
            ),
          ),

          if (_error != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red.withOpacity(0.5)),
              ),
              child: Row(
                children: [
                  Icon(PhosphorIconsRegular.warningCircle,
                      color: Colors.red.shade300, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _error!,
                      style: TextStyle(color: Colors.red.shade200, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 40),

          // Complete button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _completeRegistration,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                disabledBackgroundColor: Colors.grey.shade800,
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.black,
                      ),
                    )
                  : const Text(
                      'Complete Registration',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Language selection option widget with glass style
class _LanguageOption extends StatelessWidget {
  final String flag;
  final String title;
  final String subtitle;
  final bool isSelected;
  final VoidCallback onTap;

  const _LanguageOption({
    required this.flag,
    required this.title,
    required this.subtitle,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppStyles.animationDuration,
        curve: AppStyles.animationCurve,
        padding: const EdgeInsets.all(20),
        decoration: AppStyles.surfaceDecoration(
          color: isSelected
              ? Theme.of(context).primaryColor.withOpacity(0.10)
              : AppStyles.surfaceDeep,
        ),
        child: Row(
          children: [
                Text(
                  flag,
                  style: const TextStyle(fontSize: 32),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          fontFamily: AppStyles.fontFamily,
                          letterSpacing: -0.4,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.6),
                          fontSize: 13,
                          fontFamily: AppStyles.fontFamily,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isSelected)
                  Icon(
                    PhosphorIconsBold.checkCircle,
                    color: Theme.of(context).primaryColor,
                    size: 22,
                  ),
          ],
        ),
      ),
    );
  }
}

/// Flow for restoring an existing account
class _RestoreAccountFlow extends StatefulWidget {
  const _RestoreAccountFlow();

  @override
  State<_RestoreAccountFlow> createState() => _RestoreAccountFlowState();
}

class _RestoreAccountFlowState extends State<_RestoreAccountFlow> {
  final AuthService _authService = AuthService();
  bool _isLoading = false;
  String? _error;

  Future<void> _onPhraseConfirmed(String phrase, MnemonicLanguage language) async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final result = await _authService.loginWithRecoveryPhrase(
        phrase,
        language: language,
      );

      if (result.success) {
        if (mounted) {
          Navigator.of(context).pushNamedAndRemoveUntil('/home', (route) => false);
        }
      } else {
        setState(() => _error = result.error ?? 'Login failed');
      }
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Ensure background is visible under RecoveryPhraseScreen
        SizedBox.expand(
          child: Container(color: AppStyles.backgroundOled),
        ),

        RecoveryPhraseScreen(
          mode: RecoveryPhraseMode.input,
          onPhraseConfirmed: _onPhraseConfirmed,
          onBack: () => Navigator.of(context).pop(),
        ),

        // Loading overlay
        if (_isLoading)
          Container(
            color: Colors.black.withOpacity(0.7),
            child: const Center(
              child: CircularProgressIndicator(),
            ),
          ),

        // Error toast
        if (_error != null)
          Positioned(
            top: MediaQuery.of(context).padding.top + 20,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: AppStyles.surfaceDecoration(
                borderRadius: 18,
                color: Colors.red.withOpacity(0.12),
              ),
              child: Row(
                children: [
                  Icon(
                    PhosphorIconsRegular.warningCircle,
                    color: Colors.red.shade200,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _error!,
                      style: TextStyle(
                        color: Colors.red.shade100,
                        fontSize: 14,
                        fontFamily: AppStyles.fontFamily,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => setState(() => _error = null),
                    icon: Icon(
                      PhosphorIconsRegular.x,
                      color: Colors.red.shade200,
                      size: 18,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
