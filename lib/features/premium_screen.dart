import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:mimu/shared/animated_widgets.dart';
import 'package:mimu/shared/glass_widgets.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:mimu/app/theme.dart';
import 'package:mimu/data/settings_service.dart';
import 'package:flutter/services.dart';
import 'package:mimu/shared/app_styles.dart';

class PremiumScreen extends StatefulWidget {
  const PremiumScreen({super.key});

  @override
  State<PremiumScreen> createState() => _PremiumScreenState();
}

class _PremiumScreenState extends State<PremiumScreen> {
  bool _isPremium = false;
  String _premiumType = '';

  @override
  void initState() {
    super.initState();
    _loadPremiumStatus();
  }

  Future<void> _loadPremiumStatus() async {
    await SettingsService.init();
    setState(() {
      _isPremium = SettingsService.getIsPremium();
      _premiumType = SettingsService.getPremiumType();
    });
  }

  Future<void> _purchasePremium(String type) async {
    // Симуляция покупки
    HapticFeedback.mediumImpact();
    await SettingsService.setIsPremium(true);
    await SettingsService.setPremiumType(type);
    setState(() {
      _isPremium = true;
      _premiumType = type;
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$type активирован! Спасибо за поддержку!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppStyles.backgroundOled,
      appBar: AppBar(
        backgroundColor: AppStyles.backgroundOled,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(CupertinoIcons.back, weight: 700),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Container(
        color: AppStyles.backgroundOled,
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Fox illustration
                AnimateOnDisplay(
                  child: Image.asset(
                    'assets/images/fox_premium.png',
                    height: 200,
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(height: 24),
                // Title with checkmark
                AnimateOnDisplay(
                  delayMs: 100,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Купите Mimu Premium',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w700,
                          fontFamily: AppStyles.fontFamily,
                          letterSpacing: AppStyles.letterSpacingSignature,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Theme.of(context).primaryColor,
                          shape: BoxShape.circle,
                        ),
                        child: Image.asset(
                          'assets/images/mimu_premium_check.png',
                          width: 20,
                          height: 20,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                // Three text blocks
                AnimateOnDisplay(
                  delayMs: 200,
                  child: GlassContainer(
                    padding: const EdgeInsets.all(20),
                    child: Text(
                      'Мы знаем, что приватность - это неприкасаемое право каждого человека на земле, и всеми силами пытаемся бороться с активным ущемлением этого права',
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          height: 1.5,
                          fontSize: 15),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                AnimateOnDisplay(
                  delayMs: 300,
                  child: GlassContainer(
                    padding: const EdgeInsets.all(20),
                    child: Text(
                      'Видя активную борьбу с приватностью и свободой, мы создали Mimu - безопасный и защищенный мессенджер, а позже и экосистема с браузером Bloball.',
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          height: 1.5,
                          fontSize: 15),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                AnimateOnDisplay(
                  delayMs: 400,
                  child: GlassContainer(
                    padding: const EdgeInsets.all(20),
                    child: Text(
                      'Проект стал бесплатным. Без рекламы мы будем работать в убыток. Поддержите нас. Купите Mimu Premium',
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          height: 1.5,
                          fontSize: 15),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                // Subscription plans
                AnimateOnDisplay(
                  delayMs: 500,
                  child: Row(
                    children: [
                      Expanded(
                        child: GlassContainer(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Mimu Premium',
                                  style: TextStyle(
                                      fontSize: 16, fontWeight: FontWeight.w600)),
                              const SizedBox(height: 8),
                              GlassButton(
                                onPressed: () => _showPremiumFeatures(context),
                                child: const Padding(
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 8),
                                  child: Text('Функции',
                                      style: TextStyle(fontSize: 12)),
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text('499 рублей/мес',
                                  style: TextStyle(
                                      fontSize: 14, fontWeight: FontWeight.w500)),
                              const SizedBox(height: 12),
                              GlassButton(
                                enabled: !_isPremium || _premiumType != 'Premium',
                                onPressed: _isPremium && _premiumType == 'Premium'
                                    ? null
                                    : () => _purchasePremium('Premium'),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 8),
                                  child: Text(
                                    _isPremium && _premiumType == 'Premium' ? 'Активирован' : 'Купить',
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: GlassContainer(
                          padding: const EdgeInsets.all(16),
                          decoration: Theme.of(context)
                              .extension<GlassTheme>()!
                              .baseGlass
                              .copyWith(
                                border: Border.all(
                                  color: Theme.of(context)
                                      .primaryColor
                                      .withOpacity(0.5),
                                  width: 2,
                                ),
                              ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Mimu Ultra',
                                  style: TextStyle(
                                      fontSize: 16, fontWeight: FontWeight.w600)),
                              const SizedBox(height: 4),
                              Text(
                                'Популярен!',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Theme.of(context).primaryColor,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 8),
                              GlassButton(
                                onPressed: () => _showPremiumFeatures(context),
                                child: const Padding(
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 8),
                                  child: Text('Функции',
                                      style: TextStyle(fontSize: 12)),
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text('899 рублей/мес',
                                  style: TextStyle(
                                      fontSize: 14, fontWeight: FontWeight.w500)),
                              const SizedBox(height: 12),
                              GlassButton(
                                enabled: !_isPremium || _premiumType != 'Ultra',
                                onPressed: _isPremium && _premiumType == 'Ultra'
                                    ? null
                                    : () => _purchasePremium('Ultra'),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 8),
                                  child: Text(
                                    _isPremium && _premiumType == 'Ultra' ? 'Активирован' : 'Купить',
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
                // Bottom message
                AnimateOnDisplay(
                  delayMs: 600,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Мы будем очень благодарны',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.favorite, color: Colors.pink, size: 20),
                      const SizedBox(width: 4),
                      Transform.translate(
                        offset: const Offset(-8, 0),
                        child: const Icon(Icons.favorite,
                            color: Colors.pink, size: 20),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showPremiumFeatures(BuildContext context) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Функции Premium'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildFeatureItem(context, 'Неограниченное облачное хранилище'),
            const SizedBox(height: 12),
            _buildFeatureItem(context, 'Приоритетная поддержка'),
            const SizedBox(height: 12),
            _buildFeatureItem(context, 'Расширенные настройки приватности'),
            const SizedBox(height: 12),
            _buildFeatureItem(context, 'Эксклюзивные темы и стили'),
            const SizedBox(height: 12),
            _buildFeatureItem(context, 'Удаление рекламы'),
          ],
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Понятно'),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureItem(BuildContext context, String text) {
    return Row(
      children: [
        Icon(CupertinoIcons.check_mark_circled_solid,
            color: Theme.of(context).primaryColor, size: 20),
        const SizedBox(width: 12),
        Expanded(
            child: Text(text,
                style: TextStyle(color: Colors.white.withOpacity(0.9)))),
      ],
    );
  }
}

