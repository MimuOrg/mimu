import 'package:flutter/material.dart';
import 'package:mimu/app/routes.dart';
import 'package:mimu/features/shell_ui.dart';
import 'package:mimu/app/navigation_service.dart';
import 'package:mimu/shared/animated_widgets.dart';
import 'package:mimu/shared/glass_widgets.dart';
import 'package:mimu/data/user_service.dart';
import 'package:mimu/data/settings_service.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter/services.dart';
import 'package:mimu/data/services/auth_service.dart';
import 'package:mimu/shared/app_styles.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final PageController _pageController = PageController();
  bool _showCodeVerification = false;
  bool _isLogin = false;
  String _expectedCode = '123456';
  
  // Login fields
  final TextEditingController _loginPrIdController = TextEditingController();
  final TextEditingController _loginPasswordController = TextEditingController();
  final AuthService _authService = AuthService();
  bool _isLoading = false;
  String? _loginError;
  bool _isLoginValid = false;
  
  // Registration fields
  final TextEditingController _regUsernameController = TextEditingController();
  final TextEditingController _regEmailController = TextEditingController();
  final TextEditingController _regPasswordController = TextEditingController();
  final TextEditingController _regRepeatPasswordController = TextEditingController();
  String? _regErrorUsername;
  String? _regErrorEmail;
  String? _regErrorPassword;
  String? _regErrorRepeat;
  bool _isRegisterValid = false;
  bool _optimizeMimu = false;

  @override
  void initState() {
    super.initState();
    _loginPrIdController.addListener(_recomputeLoginValidity);
    _loginPasswordController.addListener(_recomputeLoginValidity);

    _regUsernameController.addListener(_recomputeRegisterValidity);
    _regEmailController.addListener(_recomputeRegisterValidity);
    _regPasswordController.addListener(_recomputeRegisterValidity);
    _regRepeatPasswordController.addListener(_recomputeRegisterValidity);
  }

  @override
  void dispose() {
    _pageController.dispose();
    _loginPrIdController.dispose();
    _loginPasswordController.dispose();
    _regUsernameController.dispose();
    _regEmailController.dispose();
    _regPasswordController.dispose();
    _regRepeatPasswordController.dispose();
    super.dispose();
  }

  // Вспомогательный метод для создания полей ввода
  Widget _buildTextField({
    required TextEditingController controller,
    required IconData icon,
    required String hint,
    String? error,
    bool obscureText = false,
    TextInputType? keyboardType,
  }) {
    final hasError = error != null;
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF2C2C2E).withOpacity(0.8),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: hasError
              ? Colors.redAccent.withOpacity(0.5)
              : Colors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        style: const TextStyle(color: Colors.white, fontSize: 16),
        decoration: InputDecoration(
          prefixIcon: Icon(
            icon,
            color: Colors.white.withOpacity(0.6),
            size: 20,
          ),
          border: InputBorder.none,
          hintText: hint,
          hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }

  bool _isEmail(String value) {
    final emailRegex = RegExp(r'^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$');
    return emailRegex.hasMatch(value);
  }

  bool _isPhone(String value) {
    final digits = value.replaceAll(RegExp(r'[^\d+]'), '');
    return RegExp(r'^\+?\d{10,15}$').hasMatch(digits);
  }

  void _recomputeLoginValidity() {
    final login = _loginPrIdController.text.trim();
    final password = _loginPasswordController.text;
    String? error;
    if (login.isEmpty || password.isEmpty) {
      error = 'Заполните все поля';
    } else if (!(_isEmail(login) || _isPhone(login))) {
      error = 'Введите email или телефон';
    } else if (password.length < 6) {
      error = 'Пароль слишком короткий (мин. 6)';
    }
    setState(() {
      _loginError = error;
      _isLoginValid = error == null;
    });
  }

  void _recomputeRegisterValidity() {
    final username = _regUsernameController.text.trim();
    final email = _regEmailController.text.trim();
    final pass = _regPasswordController.text;
    final repeat = _regRepeatPasswordController.text;

    String? usernameError;
    String? emailError;
    String? passError;
    String? repeatError;

    if (username.isEmpty || username.length < 3) {
      usernameError = 'Имя не короче 3 символов';
    }
    if (!_isEmail(email) && !_isPhone(email)) {
      emailError = 'Email или телефон неверного формата';
    }
    if (pass.length < 8) {
      passError = 'Пароль слишком короткий (мин. 8)';
    }
    if (repeat != pass) {
      repeatError = 'Пароли не совпадают';
    }

    setState(() {
      _regErrorUsername = usernameError;
      _regErrorEmail = emailError;
      _regErrorPassword = passError;
      _regErrorRepeat = repeatError;
      _isRegisterValid = [
        usernameError,
        emailError,
        passError,
        repeatError,
      ].every((e) => e == null);
    });
  }

  void _handleLogin() async {
    if (!_isLoginValid) return;

    setState(() {
      _isLoading = true;
      _loginError = null;
    });

    HapticFeedback.mediumImpact();

    final result = await _authService.loginWithPassword(
      publicId: _loginPrIdController.text.trim(),
      password: _loginPasswordController.text,
    );

    if (!mounted) return;

    setState(() {
      _isLoading = false;
    });

    if (result.success) {
      Navigator.of(context).pushAndRemoveUntil(
        NavigationService.createSlideTransitionRoute(const ShellUI()),
        (route) => false,
      );
    } else {
      setState(() {
        _loginError = result.error ?? 'Неверный логин или пароль.';
      });
    }
  }

  Widget _buildCodeVerification() {
    return CodeVerificationScreen(
      isLogin: _isLogin,
      expectedCode: _expectedCode,
      onVerified: () {
        Navigator.of(context).pushAndRemoveUntil(NavigationService.createSlideTransitionRoute(const ShellUI()), (route) => false);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppStyles.backgroundOled,
      body: Stack(
        children: [
          Container(
            color: AppStyles.backgroundOled,
          ),
          SafeArea(
            child: AnimatedSwitcher(
              duration: AppStyles.animationDuration,
              transitionBuilder: (child, animation) {
                final curved = CurvedAnimation(
                  parent: animation,
                  curve: AppStyles.animationCurve,
                );
                return FadeTransition(
                  opacity: curved,
                  child: child,
                );
              },
              child: _showCodeVerification ? _buildCodeVerification() : _buildAuthForms(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAuthForms() {
    return Column(
      children: [
        const SizedBox(height: 60),
        AnimateOnDisplay(
          child: Column(
            children: [
              Text(
                "Mimu",
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 48,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Общайтесь безопасно и свободно.",
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 40),
        Expanded(
          child: PageView(
            controller: _pageController,
            children: [
              _buildLoginForm(),
              _buildRegisterForm(),
            ],
          ),
        ),
        _buildPageIndicator(),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildLoginForm() {
    return AnimateOnDisplay(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          children: [
            Text(
              "Вход",
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontSize: 28,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 32),
            // Поле ввода в стиле Telegram iOS
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF2C2C2E).withOpacity(0.8),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _loginError != null && !_isLoginValid
                      ? Colors.redAccent.withOpacity(0.5)
                      : Colors.white.withOpacity(0.1),
                  width: 1,
                ),
              ),
              child: TextField(
                controller: _loginPrIdController,
                style: const TextStyle(color: Colors.white, fontSize: 16),
                decoration: InputDecoration(
                  prefixIcon: Icon(
                    CupertinoIcons.person_fill,
                    color: Colors.white.withOpacity(0.6),
                    size: 20,
                  ),
                  border: InputBorder.none,
                  hintText: "Email или телефон",
                  hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                ),
              ),
            ),
            if (_loginError != null)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    _loginError!,
                    style: const TextStyle(color: Colors.redAccent, fontSize: 12),
                  ),
                ),
              ),
            if (_loginError != null)
              Padding(
                padding: const EdgeInsets.only(top: 8, left: 4),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    _loginError!,
                    style: const TextStyle(color: Colors.redAccent, fontSize: 13),
                  ),
                ),
              ),
            const SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF2C2C2E).withOpacity(0.8),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _loginError != null && !_isLoginValid
                      ? Colors.redAccent.withOpacity(0.5)
                      : Colors.white.withOpacity(0.1),
                  width: 1,
                ),
              ),
              child: TextField(
                controller: _loginPasswordController,
                obscureText: true,
                style: const TextStyle(color: Colors.white, fontSize: 16),
                decoration: InputDecoration(
                  prefixIcon: Icon(
                    CupertinoIcons.lock_fill,
                    color: Colors.white.withOpacity(0.6),
                    size: 20,
                  ),
                  border: InputBorder.none,
                  hintText: "Пароль",
                  hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                ),
              ),
            ),
            const SizedBox(height: 32),
            // Кнопка в стиле Telegram iOS
            Material(
              color: _isLoginValid
                  ? Theme.of(context).primaryColor
                  : Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: _isLoginValid && !_isLoading ? _handleLogin : null,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Center(
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text(
                            "Войти",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRegisterForm() {
    return AnimateOnDisplay(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          children: [
            Text(
              "Регистрация",
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontSize: 28,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 32),
            // Поля ввода в стиле Telegram iOS
            _buildTextField(
              controller: _regUsernameController,
              icon: CupertinoIcons.person_fill,
              hint: "Username",
              error: _regErrorUsername,
            ),
            if (_regErrorUsername != null)
              Padding(
                padding: const EdgeInsets.only(top: 8, left: 4),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    _regErrorUsername!,
                    style: const TextStyle(color: Colors.redAccent, fontSize: 13),
                  ),
                ),
              ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _regEmailController,
              icon: CupertinoIcons.mail,
              hint: "Email или телефон",
              keyboardType: TextInputType.emailAddress,
              error: _regErrorEmail,
            ),
            if (_regErrorEmail != null)
              Padding(
                padding: const EdgeInsets.only(top: 8, left: 4),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    _regErrorEmail!,
                    style: const TextStyle(color: Colors.redAccent, fontSize: 13),
                  ),
                ),
              ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _regPasswordController,
              icon: CupertinoIcons.lock_fill,
              hint: "Пароль",
              obscureText: true,
              error: _regErrorPassword,
            ),
            if (_regErrorPassword != null)
              Padding(
                padding: const EdgeInsets.only(top: 8, left: 4),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    _regErrorPassword!,
                    style: const TextStyle(color: Colors.redAccent, fontSize: 13),
                  ),
                ),
              ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _regRepeatPasswordController,
              icon: CupertinoIcons.lock_fill,
              hint: "Повторите пароль",
              obscureText: true,
              error: _regErrorRepeat,
            ),
            if (_regErrorRepeat != null)
              Padding(
                padding: const EdgeInsets.only(top: 8, left: 4),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    _regErrorRepeat!,
                    style: const TextStyle(color: Colors.redAccent, fontSize: 13),
                  ),
                ),
              ),
            const SizedBox(height: 24),
            // Чекбокс в стиле Telegram iOS
            Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () {
                  setState(() {
                    _optimizeMimu = !_optimizeMimu;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2C2C2E).withOpacity(0.8),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.1),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      CupertinoCheckbox(
                        value: _optimizeMimu,
                        onChanged: (value) {
                          setState(() {
                            _optimizeMimu = value ?? false;
                          });
                        },
                        activeColor: Theme.of(context).primaryColor,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          "Оптимизировать Mimu?",
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),
            // Кнопка регистрации
            Material(
              color: _isRegisterValid
                  ? Theme.of(context).primaryColor
                  : Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: _isRegisterValid
                    ? () async {
                        _recomputeRegisterValidity();
                        if (!_isRegisterValid) return;
                        HapticFeedback.mediumImpact();
                        await UserService.init();
                        await SettingsService.init();
                        await SettingsService.setOptimizeMimu(_optimizeMimu);
                        final username = _regUsernameController.text.trim();
                        if (username.isNotEmpty) {
                          await UserService.setUsername(username);
                          await UserService.setDisplayName(username);
                        }
                        final prid = UserService.generateRandomPrId();
                        await UserService.setPrId(prid);
                        setState(() {
                          _isLogin = false;
                          _expectedCode = '123456';
                          _showCodeVerification = true;
                        });
                      }
                    : null,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: const Center(
                    child: Text(
                      "Зарегистрироваться",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPageIndicator() {
    return AnimatedBuilder(
      animation: _pageController,
      builder: (context, child) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(2, (index) {
            double selected = 1.0;
            if (_pageController.hasClients) {
              selected = (_pageController.page ?? 0) - index;
              selected = (1 - (selected.abs() * 0.5)).clamp(0.5, 1.0);
            }
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: 8 * selected,
              height: 8 * selected,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(selected),
              ),
            ).animate().scale(begin: const Offset(0.8, 0.8), end: const Offset(1.0, 1.0), delay: Duration(milliseconds: index * 50), duration: 300.ms, curve: Curves.easeOutCubic);
          }),
        );
      },
    );
  }
}

class CodeVerificationScreen extends StatefulWidget {
  final bool isLogin;
  final VoidCallback onVerified;
  final String expectedCode;

  const CodeVerificationScreen({
    super.key,
    required this.isLogin,
    required this.onVerified,
    required this.expectedCode,
  });

  @override
  State<CodeVerificationScreen> createState() => _CodeVerificationScreenState();
}

class _CodeVerificationScreenState extends State<CodeVerificationScreen>
    with TickerProviderStateMixin {
  final List<TextEditingController> _codeControllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());
  late AnimationController _successController;
  late AnimationController _pulseController;
  bool _isVerified = false;
  bool _isSubmitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _successController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);

    // Auto-focus first field
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNodes[0].requestFocus();
    });
  }

  @override
  void dispose() {
    for (var controller in _codeControllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    _successController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  String _currentCode() => _codeControllers.map((c) => c.text).join();

  Future<void> _submit() async {
    final code = _currentCode();
    if (code.length != 6) {
      setState(() => _error = 'Введите 6 цифр');
      return;
    }
    setState(() {
      _isSubmitting = true;
      _error = null;
    });
    await Future.delayed(const Duration(milliseconds: 400));
    if (code == widget.expectedCode) {
      setState(() {
        _isVerified = true;
        _isSubmitting = false;
      });
      _successController.forward();
      await Future.delayed(const Duration(milliseconds: 900));
      widget.onVerified();
    } else {
      setState(() {
        _isSubmitting = false;
        _error = 'Неверный код. Попробуйте ещё раз';
      });
      for (final controller in _codeControllers) {
        controller.clear();
      }
      _focusNodes[0].requestFocus();
    }
  }

  void _onCodeChanged(int index, String value) {
    if (value.length == 1 && index < 5) {
      _focusNodes[index + 1].requestFocus();
    } else if (value.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
    }

    // Check if all fields are filled
    final code = _codeControllers.map((c) => c.text).join();
    if (code.length == 6 && !_isSubmitting && !_isVerified) {
      _submit();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Animated icon
            AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) {
                return Transform.scale(
                  scale: 1.0 + (_pulseController.value * 0.1),
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          Theme.of(context).primaryColor.withOpacity(0.3),
                          Theme.of(context).primaryColor.withOpacity(0.1),
                        ],
                      ),
                    ),
                    child: Icon(
                      CupertinoIcons.mail,
                      size: 50,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                );
              },
            )
                .animate()
                .fadeIn(duration: 400.ms, curve: Curves.easeOut)
                .scale(begin: const Offset(0.9, 0.9), end: const Offset(1.0, 1.0), delay: 100.ms, duration: 400.ms, curve: Curves.easeOutCubic),
            const SizedBox(height: 32),
            Text(
              widget.isLogin ? "Введите код подтверждения" : "Подтвердите регистрацию",
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            )
                .animate()
                .fadeIn(delay: 200.ms, duration: 400.ms, curve: Curves.easeOut)
                .scale(begin: const Offset(0.95, 0.95), end: const Offset(1.0, 1.0), delay: 200.ms, duration: 400.ms, curve: Curves.easeOutCubic),
            const SizedBox(height: 16),
            Text(
              "Мы отправили код на ваш email",
              style: TextStyle(color: Colors.white.withOpacity(0.7)),
              textAlign: TextAlign.center,
            )
                .animate()
                .fadeIn(delay: 300.ms, duration: 400.ms, curve: Curves.easeOut)
                .scale(begin: const Offset(0.95, 0.95), end: const Offset(1.0, 1.0), delay: 300.ms, duration: 400.ms, curve: Curves.easeOutCubic),
            const SizedBox(height: 48),
            // Code input fields
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(6, (index) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: AnimateOnDisplay(
                    delayMs: 500 + (index * 50),
                    child: Container(
                      width: 48,
                      height: 56,
                      decoration: BoxDecoration(
                        color: const Color(0xFF2C2C2E).withOpacity(0.8),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _focusNodes[index].hasFocus
                              ? Theme.of(context).primaryColor
                              : Colors.white.withOpacity(0.2),
                          width: _focusNodes[index].hasFocus ? 2 : 1,
                        ),
                      ),
                      child: TextField(
                        controller: _codeControllers[index],
                        focusNode: _focusNodes[index],
                        textAlign: TextAlign.center,
                        textAlignVertical: TextAlignVertical.center,
                        maxLength: 1,
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w600,
                          height: 1.0,
                        ),
                        decoration: const InputDecoration(
                          counterText: '',
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                        ),
                        onChanged: (value) => _onCodeChanged(index, value),
                      ),
                    ),
                  ),
                );
              }),
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  _error!,
                  style: const TextStyle(color: Colors.redAccent, fontSize: 13),
                  textAlign: TextAlign.center,
                ),
              ),
            const SizedBox(height: 32),
            // Кнопка подтверждения в стиле Telegram iOS
            Material(
              color: (!_isSubmitting && !_isVerified)
                  ? Theme.of(context).primaryColor
                  : Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: (!_isSubmitting && !_isVerified) ? _submit : null,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (_isSubmitting)
                        const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        ),
                      if (_isSubmitting) const SizedBox(width: 12),
                      Text(
                        _isSubmitting ? 'Проверяем...' : 'Подтвердить',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Success animation
            if (_isVerified)
              AnimatedBuilder(
                animation: _successController,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _successController.value,
                    child: Opacity(
                      opacity: _successController.value,
                      child: Column(
                        children: [
                          Icon(
                            CupertinoIcons.check_mark_circled_solid,
                            size: 64,
                            color: Colors.green,
                          )
                              .animate()
                              .scale(begin: const Offset(0.8, 0.8), end: const Offset(1.0, 1.0), delay: 0.ms, duration: 350.ms, curve: Curves.easeOutCubic)
                              .fadeIn(delay: 0.ms, duration: 300.ms, curve: Curves.easeOut),
                          const SizedBox(height: 16),
                          Text(
                            "Успешно!",
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          )
                              .animate()
                              .fadeIn(delay: 200.ms, duration: 400.ms, curve: Curves.easeOut)
                              .scale(begin: const Offset(0.95, 0.95), end: const Offset(1.0, 1.0), delay: 200.ms, duration: 400.ms, curve: Curves.easeOutCubic),
                        ],
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}
