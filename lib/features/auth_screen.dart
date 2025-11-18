import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:mimu/app/routes.dart';
import 'package:mimu/shared/animated_widgets.dart';
import 'package:mimu/shared/glass_widgets.dart';
import 'package:mimu/data/user_service.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter/services.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final PageController _pageController = PageController();
  bool _showCodeVerification = false;
  bool _isLogin = false;
  
  // Login fields
  final TextEditingController _loginPrIdController = TextEditingController();
  final TextEditingController _loginPasswordController = TextEditingController();
  
  // Registration fields
  final TextEditingController _regUsernameController = TextEditingController();
  final TextEditingController _regEmailController = TextEditingController();
  final TextEditingController _regPasswordController = TextEditingController();
  final TextEditingController _regRepeatPasswordController = TextEditingController();

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

  Widget _buildCodeVerification() {
    return CodeVerificationScreen(
      isLogin: _isLogin,
      onVerified: () {
        Navigator.of(context).pushNamedAndRemoveUntil(AppRoutes.shell, (route) => false);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage("assets/images/background_pattern.png"),
                fit: BoxFit.cover,
              ),
            ),
          ),
          SafeArea(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 500),
              transitionBuilder: (child, animation) => FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0.0, 0.1),
                    end: Offset.zero,
                  ).animate(CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeOutCubic,
                  )),
                  child: child,
                ),
              ),
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
            Text("Вход", style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 24),
            GlassContainer(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: _loginPrIdController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  icon: Icon(PhosphorIconsBold.identificationBadge, color: Colors.white.withOpacity(0.5)),
                  border: InputBorder.none,
                  hintText: "Введите PrID",
                  hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                ),
              ),
            ),
            const SizedBox(height: 16),
            GlassContainer(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: _loginPasswordController,
                obscureText: true,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  icon: Icon(PhosphorIconsBold.password, color: Colors.white.withOpacity(0.5)),
                  border: InputBorder.none,
                  hintText: "Введите пароль",
                  hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                ),
              ),
            ),
            const SizedBox(height: 32),
            GlassButton(
              onPressed: () {
                if (_loginPrIdController.text.isNotEmpty && _loginPasswordController.text.isNotEmpty) {
                  HapticFeedback.mediumImpact();
                  setState(() {
                    _isLogin = true;
                    _showCodeVerification = true;
                  });
                }
              },
              child: const Center(
                child: Text("Войти", style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            )
              .animate()
              .fadeIn(duration: const Duration(milliseconds: 400), delay: const Duration(milliseconds: 200))
              .slideY(begin: 0.2, end: 0, duration: const Duration(milliseconds: 400), delay: const Duration(milliseconds: 200), curve: Curves.easeOutCubic),
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
            Text("Регистрация", style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 24),
            GlassContainer(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: _regUsernameController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  icon: Icon(PhosphorIconsBold.user, color: Colors.white.withOpacity(0.5)),
                  border: InputBorder.none,
                  hintText: "Введите username",
                  hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                ),
              ),
            ),
            const SizedBox(height: 16),
            GlassContainer(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: _regEmailController,
                keyboardType: TextInputType.emailAddress,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  icon: Icon(PhosphorIconsBold.at, color: Colors.white.withOpacity(0.5)),
                  border: InputBorder.none,
                  hintText: "Введите email",
                  hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                ),
              ),
            ),
            const SizedBox(height: 16),
            GlassContainer(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: _regPasswordController,
                obscureText: true,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  icon: Icon(PhosphorIconsBold.password, color: Colors.white.withOpacity(0.5)),
                  border: InputBorder.none,
                  hintText: "Введите пароль",
                  hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                ),
              ),
            ),
            const SizedBox(height: 16),
            GlassContainer(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: _regRepeatPasswordController,
                obscureText: true,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  icon: Icon(PhosphorIconsBold.password, color: Colors.white.withOpacity(0.5)),
                  border: InputBorder.none,
                  hintText: "Повторите пароль",
                  hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                ),
              ),
            ),
            const SizedBox(height: 32),
            GlassButton(
              onPressed: () async {
                if (_regUsernameController.text.isNotEmpty &&
                    _regEmailController.text.isNotEmpty &&
                    _regPasswordController.text.isNotEmpty &&
                    _regRepeatPasswordController.text.isNotEmpty &&
                    _regPasswordController.text == _regRepeatPasswordController.text) {
                  HapticFeedback.mediumImpact();
                  await UserService.init();
                  final username = _regUsernameController.text.trim();
                  if (username.isNotEmpty) {
                    await UserService.setUsername(username);
                    await UserService.setDisplayName(username);
                  }
                  final prid = UserService.generateRandomPrId();
                  await UserService.setPrId(prid);
                  setState(() {
                    _isLogin = false;
                    _showCodeVerification = true;
                  });
                }
              },
              child: const Center(
                child: Text("Зарегистрироваться", style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            )
              .animate()
              .fadeIn(duration: const Duration(milliseconds: 400), delay: const Duration(milliseconds: 200))
              .slideY(begin: 0.2, end: 0, duration: const Duration(milliseconds: 400), delay: const Duration(milliseconds: 200), curve: Curves.easeOutCubic),
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
            ).animate().scale(delay: Duration(milliseconds: index * 100));
          }),
        );
      },
    );
  }
}

class CodeVerificationScreen extends StatefulWidget {
  final bool isLogin;
  final VoidCallback onVerified;

  const CodeVerificationScreen({
    super.key,
    required this.isLogin,
    required this.onVerified,
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

  void _onCodeChanged(int index, String value) {
    if (value.length == 1 && index < 5) {
      _focusNodes[index + 1].requestFocus();
    } else if (value.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
    }

    // Check if all fields are filled
    final code = _codeControllers.map((c) => c.text).join();
    if (code.length == 6) {
      _verifyCode(code);
    }
  }

  void _verifyCode(String code) {
    // Simulate verification
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) {
        setState(() => _isVerified = true);
        _successController.forward();
        Future.delayed(const Duration(milliseconds: 1500), () {
          widget.onVerified();
        });
      }
    });
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
                      PhosphorIconsBold.envelope,
                      size: 50,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                );
              },
            )
                .animate()
                .fadeIn(duration: 500.ms)
                .scale(delay: 200.ms, duration: 600.ms, curve: Curves.easeOutBack),
            const SizedBox(height: 32),
            Text(
              widget.isLogin ? "Введите код подтверждения" : "Подтвердите регистрацию",
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            )
                .animate()
                .fadeIn(delay: 300.ms, duration: 500.ms)
                .slideY(begin: 0.2, end: 0, delay: 300.ms),
            const SizedBox(height: 16),
            Text(
              "Мы отправили код на ваш email",
              style: TextStyle(color: Colors.white.withOpacity(0.7)),
              textAlign: TextAlign.center,
            )
                .animate()
                .fadeIn(delay: 400.ms, duration: 500.ms)
                .slideY(begin: 0.2, end: 0, delay: 400.ms),
            const SizedBox(height: 48),
            // Code input fields
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(6, (index) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: AnimateOnDisplay(
                    delayMs: 500 + (index * 50),
                    child: GlassContainer(
                      padding: EdgeInsets.zero,
                      child: SizedBox(
                        width: 42,
                        height: 52,
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
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            height: 1.0,
                          ),
                          decoration: InputDecoration(
                            counterText: '',
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.zero,
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: Theme.of(context).primaryColor,
                                width: 2,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: Colors.white.withOpacity(0.2),
                                width: 1,
                              ),
                            ),
                          ),
                          onChanged: (value) => _onCodeChanged(index, value),
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 32),
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
                            PhosphorIconsBold.checkCircle,
                            size: 64,
                            color: Colors.green,
                          )
                              .animate()
                              .scale(delay: 0.ms, duration: 300.ms, curve: Curves.easeOutCubic) // iOS стиль
                              .fadeIn(delay: 0.ms, duration: 200.ms), // iOS стиль
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
                              .fadeIn(delay: 400.ms, duration: 500.ms),
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
