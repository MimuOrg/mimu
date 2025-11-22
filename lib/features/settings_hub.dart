import 'dart:io';
import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:mimu/shared/animated_widgets.dart';
import 'package:mimu/shared/glass_widgets.dart';
import 'package:mimu/data/settings_service.dart';
import 'package:mimu/data/user_service.dart';
import 'package:mimu/app/theme.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:image_picker/image_picker.dart';

class SettingsHub extends StatefulWidget {
  const SettingsHub({super.key});

  @override
  State<SettingsHub> createState() => _SettingsHubState();
}

class _SettingsHubState extends State<SettingsHub> {
  @override
  void initState() {
    super.initState();
    SettingsService.init();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [
          const AnimateOnDisplay(child: _ProfileHeader()),
          const SizedBox(height: 24),
          // Mimu Premium - отдельная категория вверху
          AnimateOnDisplay(
            delayMs: 50,
            child: _SettingsGroup(
              title: "Premium",
              items: [
                _SettingsItem(
                  icon: PhosphorIconsBold.rocketLaunch,
                  title: "Mimu Premium",
                  onTap: () => _openDetail(context, "Mimu Premium"),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          AnimateOnDisplay(
            delayMs: 100,
            child: _SettingsGroup(
              title: "Основные",
              items: [
                _SettingsItem(
                  icon: PhosphorIconsBold.userCircle,
                  title: "Мой аккаунт",
                  onTap: () => _openDetail(context, "Мой аккаунт"),
                ),
                _SettingsItem(
                  icon: PhosphorIconsBold.bell,
                  title: "Уведомления",
                  onTap: () => _openDetail(context, "Уведомления"),
                ),
                _SettingsItem(
                  icon: PhosphorIconsBold.paintBrush,
                  title: "Внешний вид",
                  onTap: () => _openDetail(context, "Внешний вид"),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          AnimateOnDisplay(
            delayMs: 200,
            child: _SettingsGroup(
              title: "Безопасность и Данные",
              items: [
                _SettingsItem(
                  icon: PhosphorIconsBold.shieldCheck,
                  title: "Конфиденциальность и данные",
                  onTap: () => _openDetail(context, "Конфиденциальность"),
                ),
                _SettingsItem(
                  icon: PhosphorIconsBold.plug,
                  title: "Настройка подключения",
                  onTap: () => _openDetail(context, "Настройка подключения"),
                ),
                _SettingsItem(
                  icon: PhosphorIconsBold.database,
                  title: "Данные и Память",
                  onTap: () => _openDetail(context, "Данные и Память"),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          AnimateOnDisplay(
            delayMs: 300,
            child: _SettingsGroup(
              title: "Медиа",
              items: [
                _SettingsItem(
                  icon: PhosphorIconsBold.speakerHigh,
                  title: "Звук",
                  onTap: () => _openDetail(context, "Звук"),
                ),
                _SettingsItem(
                  icon: PhosphorIconsBold.videoCamera,
                  title: "Видео",
                  onTap: () => _openDetail(context, "Видео"),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          AnimateOnDisplay(
            delayMs: 400,
            child: _SettingsGroup(
              title: "Поддержка",
              items: [
                _SettingsItem(
                  icon: PhosphorIconsBold.question,
                  title: "Поддержка",
                  onTap: () => _openDetail(context, "Поддержка"),
                ),
                _SettingsItem(
                  icon: PhosphorIconsBold.info,
                  title: "О приложении",
                  onTap: () => _openDetail(context, "О приложении"),
                ),
                _SettingsItem(
                  icon: PhosphorIconsBold.translate,
                  title: "Язык",
                  onTap: () => _openDetail(context, "Язык"),
                ),
                _SettingsItem(
                  icon: PhosphorIconsBold.cloudArrowUp,
                  title: "Резервное копирование",
                  onTap: () => _openDetail(context, "Резервное копирование"),
                ),
                _SettingsItem(
                  icon: PhosphorIconsBold.chartBar,
                  title: "Статистика",
                  onTap: () => _openDetail(context, "Статистика"),
                ),
              ],
            ),
          ),
          // Добавляем отступ внизу, чтобы нижняя панель не перекрывала последний элемент
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  void _openDetail(BuildContext context, String title) {
    // Анимация соскальзывания как в Telegram - плавное и быстрое
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            _SettingsDetailPage(title: title),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(1.0, 0.0);
          const end = Offset.zero;
          const curve = Curves.easeInOutCubic; // Плавная кривая как в Telegram

          var tween =
              Tween(begin: begin, end: end).chain(CurveTween(curve: curve));

          return SlideTransition(
            position: animation.drive(tween),
            child: child,
          );
        },
        transitionDuration:
            const Duration(milliseconds: 280), // Быстрое как в Telegram
      ),
    );
  }
}

class _ProfileHeader extends StatefulWidget {
  const _ProfileHeader();

  @override
  State<_ProfileHeader> createState() => _ProfileHeaderState();
}

class _ProfileHeaderState extends State<_ProfileHeader> {
  String? _avatarPath;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadAvatar();
  }

  Future<void> _loadAvatar() async {
    await UserService.init();
    setState(() {
      _avatarPath = UserService.getAvatarPath();
    });
  }

  Future<void> _changeAvatar() async {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: const EdgeInsets.all(12.0),
        child: GlassContainer(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(PhosphorIconsBold.images),
                title: const Text('Галерея'),
                onTap: () async {
                  Navigator.of(context).pop();
                  final XFile? file = await _picker.pickImage(
                      source: ImageSource.gallery, imageQuality: 85);
                  if (file != null) {
                    await UserService.setAvatarPath(file.path);
                    setState(() => _avatarPath = file.path);
                  }
                },
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(PhosphorIconsBold.camera),
                title: const Text('Камера'),
                onTap: () async {
                  Navigator.of(context).pop();
                  final XFile? file = await _picker.pickImage(
                      source: ImageSource.camera, imageQuality: 85);
                  if (file != null) {
                    await UserService.setAvatarPath(file.path);
                    setState(() => _avatarPath = file.path);
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final displayName = UserService.getDisplayName();
    final username = UserService.getUsername();

    return Column(
      children: [
        GestureDetector(
          onTap: _changeAvatar,
          child: Stack(
            children: [
              CircleAvatar(
                radius: 50,
                backgroundImage: _avatarPath != null &&
                        File(_avatarPath!).existsSync()
                    ? FileImage(File(_avatarPath!))
                    : const AssetImage("assets/images/avatar_placeholder.png")
                        as ImageProvider,
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: CircleAvatar(
                  radius: 15,
                  backgroundColor: Theme.of(context).primaryColor,
                  child: const Icon(PhosphorIconsBold.pencilSimple,
                      size: 16, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Text(displayName,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center),
        Text("@$username",
            style:
                TextStyle(fontSize: 16, color: Colors.white.withOpacity(0.6)),
            textAlign: TextAlign.center),
      ],
    );
  }
}

class _SettingsDetailPage extends StatelessWidget {
  final String title;
  const _SettingsDetailPage({required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(PhosphorIconsBold.caretLeft),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(title),
      ),
      body: _buildSettingsContent(context),
    );
  }

  Widget _buildSettingsContent(BuildContext context) {
    switch (title) {
      case "Уведомления":
        return _NotificationsSettings();
      case "Внешний вид":
        return _AppearanceSettings();
      case "Звук":
        return _SoundSettings();
      case "Видео":
        return _VideoSettings();
      case "Настройка подключения":
        return _ConnectionSettings();
      case "Конфиденциальность":
        return _PrivacySettings();
      case "Язык":
        return _LanguageSettings();
      case "Резервное копирование":
        return _BackupSettings();
      case "Статистика":
        return _StatisticsSettings();
      case "О приложении":
        return _AboutSettings();
      case "Мой аккаунт":
        return _MyAccountSettings();
      case "Данные и Память":
        return _DataAndStorageSettings();
      case "Mimu Premium":
        return _PremiumSettings();
      case "Поддержка":
        return _SupportSettings();
      default:
        return Center(
          child: Text('Страница "$title" (заглушка)',
              style: const TextStyle(fontSize: 16)),
        );
    }
  }
}

class _NotificationsSettings extends StatefulWidget {
  @override
  State<_NotificationsSettings> createState() => _NotificationsSettingsState();
}

class _NotificationsSettingsState extends State<_NotificationsSettings> {
  bool _notificationsEnabled = true;
  bool _soundEnabled = true;
  bool _vibrationEnabled = true;
  bool _showPreview = true;
  bool _inAppNotifications = true;
  String _notificationSound = 'Mimu';

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final enabled = SettingsService.getNotificationsEnabled();
    final vibration = SettingsService.getVibrationEnabled();
    final soundEnabled = SettingsService.getNotificationSoundEnabled();
    final previewEnabled = SettingsService.getNotificationPreviewEnabled();
    final inAppEnabled = SettingsService.getInAppNotificationsEnabled();
    final soundName = SettingsService.getNotificationSoundName();
    setState(() {
      _notificationsEnabled = enabled;
      _vibrationEnabled = vibration;
      _soundEnabled = soundEnabled;
      _showPreview = previewEnabled;
      _inAppNotifications = inAppEnabled;
      _notificationSound = soundName;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [
          Text('Уведомления',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          GlassContainer(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                ListTile(
                  title: const Text('Включить уведомления'),
                  trailing: Switch(
                    value: _notificationsEnabled,
                    onChanged: (value) async {
                      await SettingsService.setNotificationsEnabled(value);
                      setState(() => _notificationsEnabled = value);
                    },
                  ),
                ),
                Divider(height: 1, color: Colors.white.withOpacity(0.1)),
                ListTile(
                  title: const Text('Звук'),
                  subtitle: Text(_soundEnabled ? 'Включен' : 'Выключен',
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.6), fontSize: 12)),
                  trailing: Switch(
                    value: _soundEnabled,
                    onChanged: _notificationsEnabled
                        ? (value) async {
                            await SettingsService.setNotificationSoundEnabled(
                                value);
                            setState(() => _soundEnabled = value);
                          }
                        : null,
                  ),
                ),
                Divider(height: 1, color: Colors.white.withOpacity(0.1)),
                ListTile(
                  title: const Text('Вибрация'),
                  trailing: Switch(
                    value: _vibrationEnabled,
                    onChanged: _notificationsEnabled
                        ? (value) async {
                            await SettingsService.setVibrationEnabled(value);
                            setState(() => _vibrationEnabled = value);
                            // Вибрация при включении
                            if (value) {
                              HapticFeedback.lightImpact();
                            }
                          }
                        : null,
                  ),
                ),
                Divider(height: 1, color: Colors.white.withOpacity(0.1)),
                ListTile(
                  title: const Text('Показывать превью'),
                  subtitle: Text('Показывать текст сообщения в уведомлении',
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.6), fontSize: 12)),
                  trailing: Switch(
                    value: _showPreview,
                    onChanged: _notificationsEnabled
                        ? (value) async {
                            await SettingsService.setNotificationPreviewEnabled(
                                value);
                            setState(() => _showPreview = value);
                          }
                        : null,
                  ),
                ),
                Divider(height: 1, color: Colors.white.withOpacity(0.1)),
                ListTile(
                  title: const Text('Уведомления в приложении'),
                  trailing: Switch(
                    value: _inAppNotifications,
                    onChanged: _notificationsEnabled
                        ? (value) async {
                            await SettingsService.setInAppNotificationsEnabled(
                                value);
                            setState(() => _inAppNotifications = value);
                          }
                        : null,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text('Звук уведомлений',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          GlassContainer(
            padding: EdgeInsets.zero,
            child: Column(
              children:
                  ['Mimu', 'Ocean', 'Winter cold', 'Классический'].map((sound) {
                final isSelected = _notificationSound == sound;
                return Column(
                  children: [
                    ListTile(
                      title: Text(sound),
                      trailing: isSelected
                          ? Icon(PhosphorIconsBold.check,
                              color: Theme.of(context).primaryColor)
                          : null,
                      onTap: _notificationsEnabled && _soundEnabled
                          ? () async {
                              await SettingsService.setNotificationSoundName(
                                  sound);
                              setState(() => _notificationSound = sound);
                            }
                          : null,
                    ),
                    if (sound != 'Классический')
                      Divider(height: 1, color: Colors.white.withOpacity(0.1)),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _AppearanceSettings extends StatefulWidget {
  @override
  State<_AppearanceSettings> createState() => _AppearanceSettingsState();
}

class _AppearanceSettingsState extends State<_AppearanceSettings> {
  String _selectedTheme = 'Mimu Classical';
  String _selectedFont = 'Inter';
  int _fontSize = 16;
  String _selectedStyle = 'Regular';

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    setState(() {
      _selectedTheme = SettingsService.getTheme();
      _selectedFont = SettingsService.getFont();
      _fontSize = SettingsService.getFontSize();
      _selectedStyle = SettingsService.getFontStyle();
    });
  }

  @override
  Widget build(BuildContext context) {
    final themes = [
      'Mimu Classical',
      'Winter Ocean',
      'Melanholic',
      'Dark Mode',
      'Light Mode',
      'Amoled Black',
      'Ocean Blue',
      'Sunset Orange',
      'Forest Green',
      'Lavender Purple'
    ];
    final fonts = [
      'Inter',
      'Roboto',
      'Open Sans',
      'Lato',
      'Montserrat',
      'Poppins',
      'Nunito',
      'Raleway',
      'Playfair Display',
      'Merriweather',
      'Source Sans Pro',
      'Ubuntu'
    ];
    final sizes = [12, 13, 14, 15, 16, 17, 18, 19, 20, 22, 24];
    final styles = [
      'Regular',
      'Light',
      'Medium',
      'SemiBold',
      'Bold',
      'ExtraBold',
      'Italic',
      'Bold Italic'
    ];
    final accentColors = [
      const Color(0xFF8A2BE2), // BlueViolet
      const Color(0xFF00BCD4), // Cyan
      const Color(0xFF4CAF50), // Green
      const Color(0xFFFF9800), // Orange
      const Color(0xFFE91E63), // Pink
      const Color(0xFF9C27B0), // Purple
      const Color(0xFF2196F3), // Blue
      const Color(0xFFF44336), // Red
      const Color(0xFF00E676), // Light Green
      const Color(0xFFFFC107), // Amber
      const Color(0xFF3F51B5), // Indigo
      const Color(0xFF795548), // Brown
      const Color(0xFF607D8B), // Blue Grey
      const Color(0xFFE1BEE7), // Light Purple
      const Color(0xFFB2DFDB), // Light Teal
      const Color(0xFFFFE082), // Light Yellow
    ];

    return SafeArea(
      child: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [
          Text('Акцентный цвет:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: accentColors.map((color) {
              final themeProvider = Provider.of<ThemeProvider>(context);
              final isSelected =
                  themeProvider.originalAccentColor.value == color.value;
              return GestureDetector(
                onTap: () => themeProvider.changeAccentColor(color),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: color,
                    border: Border.all(
                      color: isSelected ? Colors.white : Colors.transparent,
                      width: isSelected ? 3 : 0,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: color.withOpacity(0.5),
                              blurRadius: 12,
                              spreadRadius: 2,
                            ),
                          ]
                        : null,
                  ),
                  child: isSelected
                      ? const Icon(Icons.check, color: Colors.white, size: 24)
                      : null,
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
          Text('Темы:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          SizedBox(
            height: 120,
            child: ListView.builder(
              physics: const BouncingScrollPhysics(),
              scrollDirection: Axis.horizontal,
              itemCount: themes.length,
              itemBuilder: (context, index) {
                final theme = themes[index];
                final themeProvider = Provider.of<ThemeProvider>(context);
                final isSelected = themeProvider.currentTheme == theme;
                // Цвета для разных тем
                Color themeColor;
                switch (theme) {
                  case 'Mimu Classical':
                    themeColor = const Color(0xFF8A2BE2);
                    break;
                  case 'Winter Ocean':
                    themeColor = const Color(0xFF00BCD4);
                    break;
                  case 'Melanholic':
                    themeColor = const Color(0xFF9C27B0);
                    break;
                  case 'Dark Mode':
                    themeColor = const Color(0xFF8A2BE2);
                    break;
                  case 'Light Mode':
                    themeColor = const Color(0xFF2196F3);
                    break;
                  case 'Amoled Black':
                    themeColor = const Color(0xFF00E676);
                    break;
                  case 'Ocean Blue':
                    themeColor = const Color(0xFF00BCD4);
                    break;
                  case 'Sunset Orange':
                    themeColor = const Color(0xFFFF9800);
                    break;
                  case 'Forest Green':
                    themeColor = const Color(0xFF4CAF50);
                    break;
                  case 'Lavender Purple':
                    themeColor = const Color(0xFFE1BEE7);
                    break;
                  default:
                    themeColor = const Color(0xFF8A2BE2);
                }
                return GestureDetector(
                  onTap: () async {
                    await SettingsService.setTheme(theme);
                    themeProvider.changeTheme(theme);
                    setState(() => _selectedTheme = theme);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeInOut,
                    width: 100,
                    margin: const EdgeInsets.only(right: 12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(
                        color: isSelected
                            ? themeColor
                            : Colors.white.withOpacity(0.2),
                        width: isSelected ? 3 : 1,
                      ),
                      color: themeColor.withOpacity(0.1),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: themeColor.withOpacity(0.3),
                                blurRadius: 12,
                                spreadRadius: 2,
                              ),
                            ]
                          : null,
                    ),
                    child: Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  themeColor.withOpacity(0.3),
                                  themeColor.withOpacity(0.1),
                                ],
                              ),
                            ),
                          ),
                        ),
                        Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (isSelected)
                                Icon(Icons.check_circle,
                                    color: themeColor, size: 20),
                              const SizedBox(height: 4),
                              Text(
                                theme,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: isSelected
                                      ? FontWeight.w600
                                      : FontWeight.normal,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 24),
          Text('Шрифт:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          GlassContainer(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: SizedBox(
              height: 150,
              child: ListView.builder(
                physics: const BouncingScrollPhysics(),
                itemCount: fonts.length,
                itemBuilder: (context, index) {
                  final font = fonts[index];
                  final isSelected = _selectedFont == font;
                  return Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(15),
                      onTap: () async {
                        await SettingsService.setFont(font);
                        Provider.of<FontProvider>(context, listen: false)
                            .setFont(font);
                        setState(() => _selectedFont = font);
                      },
                      child: ListTile(
                        title: Text(font,
                            style: TextStyle(
                                fontWeight: isSelected
                                    ? FontWeight.w600
                                    : FontWeight.normal)),
                        trailing: isSelected
                            ? Icon(PhosphorIconsBold.check,
                                color: Theme.of(context).primaryColor)
                            : null,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text('Размер:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          GlassContainer(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: SizedBox(
              height: 150,
              child: ListView.builder(
                physics: const BouncingScrollPhysics(),
                itemCount: sizes.length,
                itemBuilder: (context, index) {
                  final size = sizes[index];
                  final isSelected = _fontSize == size;
                  return Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(15),
                      onTap: () async {
                        await SettingsService.setFontSize(size);
                        Provider.of<FontProvider>(context, listen: false)
                            .setFontSize(size);
                        setState(() => _fontSize = size);
                      },
                      child: ListTile(
                        title: Text('$size',
                            style: TextStyle(
                                fontWeight: isSelected
                                    ? FontWeight.w600
                                    : FontWeight.normal)),
                        trailing: isSelected
                            ? Icon(PhosphorIconsBold.check,
                                color: Theme.of(context).primaryColor)
                            : null,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text('Стиль:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          GlassContainer(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: SizedBox(
              height: 150,
              child: ListView.builder(
                physics: const BouncingScrollPhysics(),
                itemCount: styles.length,
                itemBuilder: (context, index) {
                  final style = styles[index];
                  final isSelected = _selectedStyle == style;
                  return Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(15),
                      onTap: () async {
                        await SettingsService.setFontStyle(style);
                        Provider.of<FontProvider>(context, listen: false)
                            .setFontStyle(style);
                        setState(() => _selectedStyle = style);
                      },
                      child: ListTile(
                        title: Text(style,
                            style: TextStyle(
                                fontWeight: isSelected
                                    ? FontWeight.w600
                                    : FontWeight.normal)),
                        trailing: isSelected
                            ? Icon(PhosphorIconsBold.check,
                                color: Theme.of(context).primaryColor)
                            : null,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text('Отображение чата',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          GlassContainer(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                ListTile(
                  title: const Text('Компактный режим'),
                  subtitle: Text('Уменьшает отступы между сообщениями',
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.6), fontSize: 12)),
                  trailing: Switch(
                    value: SettingsService.getCompactMode(),
                    onChanged: (value) async {
                      await SettingsService.setCompactMode(value);
                      setState(() {});
                    },
                  ),
                ),
                Divider(height: 1, color: Colors.white.withOpacity(0.1)),
                ListTile(
                  title: const Text('Показывать время'),
                  subtitle: Text('Отображать время отправки сообщений',
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.6), fontSize: 12)),
                  trailing: Switch(
                    value: SettingsService.getShowTimestamps(),
                    onChanged: (value) async {
                      await SettingsService.setShowTimestamps(value);
                      setState(() {});
                    },
                  ),
                ),
                Divider(height: 1, color: Colors.white.withOpacity(0.1)),
                ListTile(
                  title: const Text('Статусы прочтения'),
                  subtitle: Text('Показывать галочки прочтения сообщений',
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.6), fontSize: 12)),
                  trailing: Switch(
                    value: SettingsService.getShowReadReceipts(),
                    onChanged: (value) async {
                      await SettingsService.setShowReadReceipts(value);
                      setState(() {});
                    },
                  ),
                ),
                Divider(height: 1, color: Colors.white.withOpacity(0.1)),
                ListTile(
                  title: const Text('Онлайн статус'),
                  subtitle: Text('Показывать когда пользователь онлайн',
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.6), fontSize: 12)),
                  trailing: Switch(
                    value: SettingsService.getShowOnlineStatus(),
                    onChanged: (value) async {
                      await SettingsService.setShowOnlineStatus(value);
                      setState(() {});
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text('Жесты и интерактивность',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          GlassContainer(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                ListTile(
                  title: const Text('Свайп навигация'),
                  subtitle: Text(
                      'Свайп влево-вправо для переключения между вкладками',
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.6), fontSize: 12)),
                  trailing: Switch(
                    value: SettingsService.getSwipeNavigation(),
                    onChanged: (value) async {
                      await SettingsService.setSwipeNavigation(value);
                      setState(() {});
                    },
                  ),
                ),
                Divider(height: 1, color: Colors.white.withOpacity(0.1)),
                ListTile(
                  title: const Text('Свайп для ответа'),
                  subtitle: Text('Свайп влево для быстрого ответа',
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.6), fontSize: 12)),
                  trailing: Switch(
                    value: SettingsService.getSwipeToReply(),
                    onChanged: (value) async {
                      await SettingsService.setSwipeToReply(value);
                      setState(() {});
                    },
                  ),
                ),
                Divider(height: 1, color: Colors.white.withOpacity(0.1)),
                ListTile(
                  title: const Text('Двойной тап для лайка'),
                  subtitle: Text(
                      'Двойной тап по сообщению для добавления реакции',
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.6), fontSize: 12)),
                  trailing: Switch(
                    value: SettingsService.getDoubleTapToLike(),
                    onChanged: (value) async {
                      await SettingsService.setDoubleTapToLike(value);
                      setState(() {});
                    },
                  ),
                ),
                Divider(height: 1, color: Colors.white.withOpacity(0.1)),
                ListTile(
                  title: const Text('Анимации сообщений'),
                  subtitle: Text('Плавные анимации при отправке сообщений',
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.6), fontSize: 12)),
                  trailing: Switch(
                    value: SettingsService.getMessageAnimations(),
                    onChanged: (value) async {
                      await SettingsService.setMessageAnimations(value);
                      setState(() {});
                    },
                  ),
                ),
                Divider(height: 1, color: Colors.white.withOpacity(0.1)),
                ListTile(
                  title: const Text('Тактильная отдача'),
                  subtitle: Text('Вибрация при взаимодействии',
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.6), fontSize: 12)),
                  trailing: Switch(
                    value: SettingsService.getHapticFeedback(),
                    onChanged: (value) async {
                      await SettingsService.setHapticFeedback(value);
                      setState(() {});
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text('Медиа',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          GlassContainer(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                ListTile(
                  title: const Text('Автовоспроизведение'),
                  subtitle: Text('Автоматически воспроизводить медиа',
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.6), fontSize: 12)),
                  trailing: Switch(
                    value: SettingsService.getAutoPlayMedia(),
                    onChanged: (value) async {
                      await SettingsService.setAutoPlayMedia(value);
                      setState(() {});
                    },
                  ),
                ),
                Divider(height: 1, color: Colors.white.withOpacity(0.1)),
                ListTile(
                  title: const Text('Сохранять в галерею'),
                  subtitle: Text('Автоматически сохранять медиа в галерею',
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.6), fontSize: 12)),
                  trailing: Switch(
                    value: SettingsService.getSaveMediaToGallery(),
                    onChanged: (value) async {
                      await SettingsService.setSaveMediaToGallery(value);
                      setState(() {});
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text('Стиль сообщений',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          GlassContainer(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                ListTile(
                  title: const Text('Градиентные пузыри'),
                  subtitle: Text('Использовать градиент для сообщений',
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.6), fontSize: 12)),
                  trailing: Switch(
                    value: SettingsService.getGradientBubbles(),
                    onChanged: (value) async {
                      await SettingsService.setGradientBubbles(value);
                      setState(() {});
                    },
                  ),
                ),
                Divider(height: 1, color: Colors.white.withOpacity(0.1)),
                ListTile(
                  title: const Text('Скругление углов'),
                  subtitle: Text('Настройка скругления пузырей сообщений',
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.6), fontSize: 12)),
                  trailing: Icon(PhosphorIconsBold.caretRight,
                      color: Colors.white.withOpacity(0.5)),
                  onTap: () {
                    _showBubbleRadiusDialog(context);
                  },
                ),
                Divider(height: 1, color: Colors.white.withOpacity(0.1)),
                ListTile(
                  title: const Text('Тень сообщений'),
                  subtitle: Text('Добавлять тень к пузырям сообщений',
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.6), fontSize: 12)),
                  trailing: Switch(
                    value: SettingsService.getMessageShadow(),
                    onChanged: (value) async {
                      await SettingsService.setMessageShadow(value);
                      setState(() {});
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text('Фон чата',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          GlassContainer(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                ListTile(
                  title: const Text('Декоративные иконки'),
                  subtitle: Text('Показывать декоративные иконки на фоне',
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.6), fontSize: 12)),
                  trailing: Switch(
                    value: SettingsService.getDecorativeIcons(),
                    onChanged: (value) async {
                      await SettingsService.setDecorativeIcons(value);
                      setState(() {});
                    },
                  ),
                ),
                Divider(height: 1, color: Colors.white.withOpacity(0.1)),
                ListTile(
                  title: const Text('Прозрачность фона'),
                  subtitle: Text('Настройка прозрачности фона чата',
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.6), fontSize: 12)),
                  trailing: Icon(PhosphorIconsBold.caretRight,
                      color: Colors.white.withOpacity(0.5)),
                  onTap: () {
                    _showBackgroundOpacityDialog(context);
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text('Оптимизация',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          GlassContainer(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                ListTile(
                  title: const Text('Энергосбережение'),
                  subtitle: Text(
                      'Снижает производительность для экономии батареи',
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.6), fontSize: 12)),
                  trailing: Switch(
                    value: SettingsService.getPowerSaving(),
                    onChanged: (value) async {
                      await SettingsService.setPowerSaving(value);
                      setState(() {});
                    },
                  ),
                ),
                Divider(height: 1, color: Colors.white.withOpacity(0.1)),
                ListTile(
                  title: const Text('Отключить анимации'),
                  subtitle: Text(
                      'Улучшает производительность на слабых устройствах',
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.6), fontSize: 12)),
                  trailing: Switch(
                    value: !SettingsService.getAnimationsEnabled(),
                    onChanged: (value) async {
                      await SettingsService.setAnimationsEnabled(!value);
                      setState(() {});
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SoundSettings extends StatefulWidget {
  @override
  State<_SoundSettings> createState() => _SoundSettingsState();
}

class _SoundSettingsState extends State<_SoundSettings> {
  String _selectedProfile = 'Mimu';
  String _audioInput = 'Default';
  String _audioOutput = 'Default';

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    setState(() {
      _selectedProfile = SettingsService.getSoundProfile();
      _audioInput = SettingsService.getAudioInput();
      _audioOutput = SettingsService.getAudioOutput();
    });
  }

  @override
  Widget build(BuildContext context) {
    final profiles = ['Mimu', 'Ocean', 'Winter cold'];
    final devices = ['Default', 'Device 1', 'Device 2'];

    return SafeArea(
      child: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [
          Text('Звук',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          SizedBox(
            height: 120,
            child: ListView.builder(
              physics: const BouncingScrollPhysics(),
              scrollDirection: Axis.horizontal,
              itemCount: profiles.length,
              itemBuilder: (context, index) {
                final profile = profiles[index];
                final isSelected = _selectedProfile == profile;
                return GestureDetector(
                  onTap: () async {
                    await SettingsService.setSoundProfile(profile);
                    setState(() => _selectedProfile = profile);
                  },
                  child: Container(
                    width: 100,
                    margin: const EdgeInsets.only(right: 12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? Theme.of(context).primaryColor
                            : Colors.white.withOpacity(0.2),
                        width: isSelected ? 3 : 1,
                      ),
                      color: Colors.white.withOpacity(0.03),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (isSelected)
                            Container(
                              width: 8,
                              height: 8,
                              margin: const EdgeInsets.only(bottom: 8),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Theme.of(context).primaryColor,
                              ),
                            ),
                          Text(profile, style: TextStyle(fontSize: 12)),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 24),
          Text('Устройство ввода аудио:', style: TextStyle(fontSize: 16)),
          const SizedBox(height: 8),
          GlassContainer(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: DropdownButton<String>(
              value: _audioInput,
              isExpanded: true,
              dropdownColor: const Color(0xFF2C1A3E),
              style: TextStyle(color: Colors.white.withOpacity(0.9)),
              underline: Container(),
              items: devices.map((device) {
                return DropdownMenuItem(
                  value: device,
                  child: Text(device),
                );
              }).toList(),
              onChanged: (value) async {
                if (value != null) {
                  await SettingsService.setAudioInput(value);
                  setState(() => _audioInput = value);
                }
              },
            ),
          ),
          const SizedBox(height: 16),
          Text('Устройство вывода аудио:', style: TextStyle(fontSize: 16)),
          const SizedBox(height: 8),
          GlassContainer(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: DropdownButton<String>(
              value: _audioOutput,
              isExpanded: true,
              dropdownColor: const Color(0xFF2C1A3E),
              style: TextStyle(color: Colors.white.withOpacity(0.9)),
              underline: Container(),
              items: devices.map((device) {
                return DropdownMenuItem(
                  value: device,
                  child: Text(device),
                );
              }).toList(),
              onChanged: (value) async {
                if (value != null) {
                  await SettingsService.setAudioOutput(value);
                  setState(() => _audioOutput = value);
                }
              },
            ),
          ),
          const SizedBox(height: 32),
          Text('Кастомные звуки',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          _buildCustomSoundField(
            context,
            'Получение нового сообщения',
            'Выберите файл звука для уведомлений о новых сообщениях',
            () async {
              // Placeholder for file picker
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('Выберите звуковой файл (.mp3, .wav)')),
              );
            },
          ),
          const SizedBox(height: 12),
          _buildCustomSoundField(
            context,
            'Входящий звонок',
            'Выберите файл звука для входящих звонков',
            () async {
              // Placeholder for file picker
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('Выберите звуковой файл (.mp3, .wav)')),
              );
            },
          ),
          const SizedBox(height: 12),
          _buildCustomSoundField(
            context,
            'Исходящий звонок',
            'Выберите файл звука для исходящих звонков',
            () async {
              // Placeholder for file picker
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('Выберите звуковой файл (.mp3, .wav)')),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCustomSoundField(
    BuildContext context,
    String title,
    String hint,
    VoidCallback onTap,
  ) {
    return GlassContainer(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style:
                  const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Text(
            hint,
            style:
                TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 12),
          ),
          const SizedBox(height: 12),
          GlassButton(
            onPressed: onTap,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(PhosphorIconsBold.upload,
                    color: Theme.of(context).primaryColor, size: 20),
                const SizedBox(width: 8),
                const Text('Загрузить файл', style: TextStyle(fontSize: 14)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _VideoSettings extends StatefulWidget {
  @override
  State<_VideoSettings> createState() => _VideoSettingsState();
}

class _VideoSettingsState extends State<_VideoSettings> {
  bool _autoDownload = false;
  bool _trafficSaving = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    setState(() {
      _autoDownload = SettingsService.getAutoDownloadVideo();
      _trafficSaving = SettingsService.getTrafficSaving();
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [
          GlassContainer(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                ListTile(
                  title: const Text('Загружать видео автоматически'),
                  trailing: Switch(
                    value: _autoDownload,
                    onChanged: (value) async {
                      await SettingsService.setAutoDownloadVideo(value);
                      setState(() => _autoDownload = value);
                    },
                  ),
                ),
                Divider(height: 1, color: Colors.white.withOpacity(0.1)),
                ListTile(
                  title: const Text('Экономия трафика'),
                  trailing: Switch(
                    value: _trafficSaving,
                    onChanged: (value) async {
                      await SettingsService.setTrafficSaving(value);
                      setState(() => _trafficSaving = value);
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ConnectionSettings extends StatefulWidget {
  @override
  State<_ConnectionSettings> createState() => _ConnectionSettingsState();
}

class _ConnectionSettingsState extends State<_ConnectionSettings> {
  String _connection = 'Default';
  bool _useProxy = false;
  bool _autoConnect = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    setState(() {
      _connection = SettingsService.getConnection();
      _useProxy = SettingsService.getUseProxy();
      _autoConnect = SettingsService.getAutoConnect();
    });
  }

  @override
  Widget build(BuildContext context) {
    final connections = ['Default', 'Connection 1', 'Connection 2'];

    return SafeArea(
      child: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [
          Text('Тип подключения',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          GlassContainer(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                ListTile(
                  leading: Icon(PhosphorIconsBold.plug,
                      color: Theme.of(context).primaryColor),
                  title: const Text('Текущее подключение'),
                  subtitle: Text(_connection,
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.6), fontSize: 12)),
                  trailing: Icon(PhosphorIconsBold.caretRight,
                      color: Colors.white.withOpacity(0.5)),
                  onTap: () {
                    showDialog(
                      context: context,
                      barrierColor: Colors.black.withOpacity(0.5),
                      builder: (context) => TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0.0, end: 1.0),
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeOutCubic,
                        builder: (context, value, child) {
                          return Transform.scale(
                            scale: 0.9 + (value * 0.1),
                            child: Opacity(
                              opacity: value,
                              child: Dialog(
                                backgroundColor: Colors.transparent,
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(20),
                                  child: BackdropFilter(
                                    filter:
                                        ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                                    child: GlassContainer(
                                      padding: const EdgeInsets.all(24),
                                      decoration: Theme.of(context)
                                          .extension<GlassTheme>()!
                                          .baseGlass
                                          .copyWith(
                                            color: Theme.of(context)
                                                .primaryColor
                                                .withOpacity(0.12),
                                            borderRadius:
                                                BorderRadius.circular(20),
                                          ),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Text('Выберите подключение',
                                              style: TextStyle(
                                                  fontSize: 20,
                                                  fontWeight: FontWeight.bold)),
                                          const SizedBox(height: 20),
                                          ...connections.map((conn) {
                                            return ListTile(
                                              title: Text(conn),
                                              trailing: _connection == conn
                                                  ? Icon(
                                                      PhosphorIconsBold.check,
                                                      color: Theme.of(context)
                                                          .primaryColor)
                                                  : null,
                                              onTap: () async {
                                                await SettingsService
                                                    .setConnection(conn);
                                                setState(
                                                    () => _connection = conn);
                                                Navigator.of(context).pop();
                                              },
                                            );
                                          }).toList(),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
                Divider(height: 1, color: Colors.white.withOpacity(0.1)),
                ListTile(
                  leading: Icon(PhosphorIconsBold.plus,
                      color: Theme.of(context).primaryColor),
                  title: const Text('Добавить подключение'),
                  trailing: Icon(PhosphorIconsBold.caretRight,
                      color: Colors.white.withOpacity(0.5)),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Добавление нового подключения')),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text('Настройки',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          GlassContainer(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                ListTile(
                  title: const Text('Использовать прокси'),
                  subtitle: Text('Подключение через прокси-сервер',
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.6), fontSize: 12)),
                  trailing: Switch(
                    value: _useProxy,
                    onChanged: (value) async {
                      await SettingsService.setUseProxy(value);
                      setState(() => _useProxy = value);
                    },
                  ),
                ),
                Divider(height: 1, color: Colors.white.withOpacity(0.1)),
                ListTile(
                  title: const Text('Автоподключение'),
                  subtitle: Text('Автоматически подключаться при запуске',
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.6), fontSize: 12)),
                  trailing: Switch(
                    value: _autoConnect,
                    onChanged: (value) async {
                      await SettingsService.setAutoConnect(value);
                      setState(() => _autoConnect = value);
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PrivacySettings extends StatefulWidget {
  @override
  State<_PrivacySettings> createState() => _PrivacySettingsState();
}

class _PrivacySettingsState extends State<_PrivacySettings> {
  bool _lastSeenEnabled = true;
  bool _readReceiptsEnabled = true;
  bool _profilePhotoVisible = true;
  bool _statusVisible = true;
  String _whoCanAddMe = 'Все';
  bool _twoFactorEnabled = false;
  bool _screenLockEnabled = false;
  bool _selfDestructMessages = false;
  bool _encryptionEnabled = true;
  bool _searchByUsername = true;
  bool _autoDeleteMessages = false;
  int _autoDeleteTime = 24;
  bool _hideLastSeenTime = false;
  bool _hideTypingStatus = false;
  bool _screenshotProtection = false;
  bool _hideForwarding = false;
  bool _hideCopying = false;
  bool _hidePhoneNumber = false;
  bool _cloudSync = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    setState(() {
      _lastSeenEnabled = SettingsService.getLastSeenEnabled();
      _readReceiptsEnabled = SettingsService.getReadReceiptsEnabled();
      _profilePhotoVisible = SettingsService.getProfilePhotoVisible();
      _statusVisible = SettingsService.getStatusVisible();
      _whoCanAddMe = SettingsService.getWhoCanAddMe();
      _twoFactorEnabled = SettingsService.getTwoFactorEnabled();
      _screenLockEnabled = SettingsService.getScreenLockEnabled();
      _selfDestructMessages = SettingsService.getSelfDestructMessages();
      _encryptionEnabled = SettingsService.getEncryptionEnabled();
      _searchByUsername = SettingsService.getSearchByUsername();
      _autoDeleteMessages = SettingsService.getAutoDeleteMessages();
      _autoDeleteTime = SettingsService.getAutoDeleteTime();
      _hideLastSeenTime = SettingsService.getHideLastSeenTime();
      _hideTypingStatus = SettingsService.getHideTypingStatus();
      _screenshotProtection = SettingsService.getScreenshotProtection();
      _hideForwarding = SettingsService.getHideForwarding();
      _hideCopying = SettingsService.getHideCopying();
      _hidePhoneNumber = SettingsService.getHidePhoneNumber();
      _cloudSync = SettingsService.getCloudSync();
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [
          Text('Видимость',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          GlassContainer(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                ListTile(
                  title: const Text('Последний раз в сети'),
                  subtitle: Text(_lastSeenEnabled ? 'Все' : 'Никто',
                      style: TextStyle(color: Colors.white.withOpacity(0.6))),
                  trailing: Switch(
                    value: _lastSeenEnabled,
                    onChanged: (value) async {
                      await SettingsService.setLastSeenEnabled(value);
                      setState(() => _lastSeenEnabled = value);
                    },
                  ),
                ),
                Divider(height: 1, color: Colors.white.withOpacity(0.1)),
                ListTile(
                  title: const Text('Чтение сообщений'),
                  subtitle: Text(
                      _readReceiptsEnabled ? 'Включено' : 'Выключено',
                      style: TextStyle(color: Colors.white.withOpacity(0.6))),
                  trailing: Switch(
                    value: _readReceiptsEnabled,
                    onChanged: (value) async {
                      await SettingsService.setReadReceiptsEnabled(value);
                      setState(() => _readReceiptsEnabled = value);
                    },
                  ),
                ),
                Divider(height: 1, color: Colors.white.withOpacity(0.1)),
                ListTile(
                  title: const Text('Фото профиля'),
                  subtitle: Text(
                      _profilePhotoVisible ? 'Все' : 'Только контакты',
                      style: TextStyle(color: Colors.white.withOpacity(0.6))),
                  trailing: Switch(
                    value: _profilePhotoVisible,
                    onChanged: (value) async {
                      await SettingsService.setProfilePhotoVisible(value);
                      setState(() => _profilePhotoVisible = value);
                    },
                  ),
                ),
                Divider(height: 1, color: Colors.white.withOpacity(0.1)),
                ListTile(
                  title: const Text('Статус'),
                  subtitle: Text(_statusVisible ? 'Все' : 'Только контакты',
                      style: TextStyle(color: Colors.white.withOpacity(0.6))),
                  trailing: Switch(
                    value: _statusVisible,
                    onChanged: (value) async {
                      await SettingsService.setStatusVisible(value);
                      setState(() => _statusVisible = value);
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text('Кто может...',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          GlassContainer(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                ListTile(
                  title: const Text('Добавлять меня в группы'),
                  subtitle: Text(_whoCanAddMe,
                      style: TextStyle(color: Colors.white.withOpacity(0.6))),
                  trailing: Icon(PhosphorIconsBold.caretRight,
                      color: Colors.white.withOpacity(0.5)),
                  onTap: () {
                    showDialog(
                      context: context,
                      barrierColor: Colors.black.withOpacity(0.5),
                      builder: (context) => TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0.0, end: 1.0),
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeOutCubic,
                        builder: (context, value, child) {
                          return Transform.scale(
                            scale: 0.9 + (value * 0.1),
                            child: Opacity(
                              opacity: value,
                              child: Dialog(
                                backgroundColor: Colors.transparent,
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(20),
                                  child: BackdropFilter(
                                    filter:
                                        ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                                    child: GlassContainer(
                                      padding: const EdgeInsets.all(24),
                                      decoration: Theme.of(context)
                                          .extension<GlassTheme>()!
                                          .baseGlass
                                          .copyWith(
                                            color: Theme.of(context)
                                                .primaryColor
                                                .withOpacity(0.12),
                                            borderRadius:
                                                BorderRadius.circular(20),
                                          ),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Text('Кто может добавлять',
                                              style: TextStyle(
                                                  fontSize: 20,
                                                  fontWeight: FontWeight.bold)),
                                          const SizedBox(height: 20),
                                          ...['Все', 'Только контакты', 'Никто']
                                              .map((option) {
                                            return ListTile(
                                              title: Text(option),
                                              trailing: _whoCanAddMe == option
                                                  ? Icon(
                                                      PhosphorIconsBold.check,
                                                      color: Theme.of(context)
                                                          .primaryColor)
                                                  : null,
                                              onTap: () async {
                                                await SettingsService
                                                    .setWhoCanAddMe(option);
                                                setState(() =>
                                                    _whoCanAddMe = option);
                                                Navigator.of(context).pop();
                                              },
                                            );
                                          }).toList(),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text('Поиск и обнаружение',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          GlassContainer(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                ListTile(
                  title: const Text('Поиск по юзернейму'),
                  subtitle: Text(
                      _searchByUsername
                          ? 'Другие могут найти вас по @username'
                          : 'Вас нельзя найти по @username',
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.6), fontSize: 12)),
                  trailing: Switch(
                    value: _searchByUsername,
                    onChanged: (value) async {
                      await SettingsService.setSearchByUsername(value);
                      setState(() => _searchByUsername = value);
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text('Безопасность',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          GlassContainer(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                ListTile(
                  title: const Text('Двухфакторная аутентификация'),
                  subtitle: Text(_twoFactorEnabled ? 'Включена' : 'Выключена',
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.6), fontSize: 12)),
                  trailing: Switch(
                    value: _twoFactorEnabled,
                    onChanged: (value) async {
                      await SettingsService.setTwoFactorEnabled(value);
                      setState(() => _twoFactorEnabled = value);
                      if (value) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text(
                                  'Двухфакторная аутентификация включена')),
                        );
                      }
                    },
                  ),
                ),
                Divider(height: 1, color: Colors.white.withOpacity(0.1)),
                ListTile(
                  title: const Text('Блокировка экрана'),
                  subtitle: Text(_screenLockEnabled ? 'Включена' : 'Выключена',
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.6), fontSize: 12)),
                  trailing: Switch(
                    value: _screenLockEnabled,
                    onChanged: (value) async {
                      await SettingsService.setScreenLockEnabled(value);
                      setState(() => _screenLockEnabled = value);
                      if (value) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Блокировка экрана включена')),
                        );
                      }
                    },
                  ),
                ),
                Divider(height: 1, color: Colors.white.withOpacity(0.1)),
                ListTile(
                  title: const Text('Шифрование сообщений'),
                  subtitle: Text(
                      _encryptionEnabled
                          ? 'End-to-end шифрование активно'
                          : 'Шифрование выключено',
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.6), fontSize: 12)),
                  trailing: Switch(
                    value: _encryptionEnabled,
                    onChanged: (value) async {
                      await SettingsService.setEncryptionEnabled(value);
                      setState(() => _encryptionEnabled = value);
                    },
                  ),
                ),
                Divider(height: 1, color: Colors.white.withOpacity(0.1)),
                ListTile(
                  title: const Text('Самоуничтожающиеся сообщения'),
                  subtitle: Text(
                      _selfDestructMessages ? 'Включено' : 'Выключено',
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.6), fontSize: 12)),
                  trailing: Switch(
                    value: _selfDestructMessages,
                    onChanged: (value) async {
                      await SettingsService.setSelfDestructMessages(value);
                      setState(() => _selfDestructMessages = value);
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text('Автоудаление сообщений',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          GlassContainer(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                ListTile(
                  title: const Text('Включить автоудаление'),
                  subtitle: Text(
                      _autoDeleteMessages
                          ? 'Сообщения будут удаляться через $_autoDeleteTime ${_autoDeleteTime == 1 ? 'час' : _autoDeleteTime < 5 ? 'часа' : 'часов'}'
                          : 'Сообщения не будут удаляться автоматически',
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.6), fontSize: 12)),
                  trailing: Switch(
                    value: _autoDeleteMessages,
                    onChanged: (value) async {
                      await SettingsService.setAutoDeleteMessages(value);
                      setState(() => _autoDeleteMessages = value);
                    },
                  ),
                ),
                if (_autoDeleteMessages) ...[
                  Divider(height: 1, color: Colors.white.withOpacity(0.1)),
                  ListTile(
                    title: const Text('Время до удаления'),
                    subtitle: Text(
                        '$_autoDeleteTime ${_autoDeleteTime == 1 ? 'час' : _autoDeleteTime < 5 ? 'часа' : 'часов'}',
                        style: TextStyle(
                            color: Colors.white.withOpacity(0.6),
                            fontSize: 12)),
                    trailing: Icon(PhosphorIconsBold.caretRight,
                        color: Colors.white.withOpacity(0.5)),
                    onTap: () {
                      _showAnimatedDialog(
                        context: context,
                        title: 'Время до удаления',
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [1, 6, 12, 24, 48, 72, 168].map((hours) {
                            final isSelected = _autoDeleteTime == hours;
                            String label;
                            if (hours == 1) {
                              label = '1 час';
                            } else if (hours < 24) {
                              label = '$hours часов';
                            } else if (hours == 24) {
                              label = '1 день';
                            } else if (hours == 48) {
                              label = '2 дня';
                            } else if (hours == 72) {
                              label = '3 дня';
                            } else {
                              label = '${hours ~/ 24} дней';
                            }
                            return ListTile(
                              title: Text(label),
                              trailing: isSelected
                                  ? Icon(PhosphorIconsBold.check,
                                      color: Theme.of(context).primaryColor)
                                  : null,
                              onTap: () async {
                                await SettingsService.setAutoDeleteTime(hours);
                                setState(() => _autoDeleteTime = hours);
                                Navigator.of(context).pop();
                              },
                            );
                          }).toList(),
                        ),
                        actions: [
                          GlassButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: const Padding(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 10),
                              child: Text('Отмена'),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text('Дополнительно',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          GlassContainer(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                ListTile(
                  title: const Text('Скрыть номер телефона'),
                  subtitle: Text('Скрыть номер от других пользователей',
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.6), fontSize: 12)),
                  trailing: Switch(
                    value: _hidePhoneNumber,
                    onChanged: (value) async {
                      await SettingsService.setHidePhoneNumber(value);
                      setState(() => _hidePhoneNumber = value);
                    },
                  ),
                ),
                Divider(height: 1, color: Colors.white.withOpacity(0.1)),
                ListTile(
                  title: const Text('Блокировка контактов'),
                  subtitle: Text('Управление заблокированными контактами',
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.6), fontSize: 12)),
                  trailing: Icon(PhosphorIconsBold.caretRight,
                      color: Colors.white.withOpacity(0.5)),
                  onTap: () {
                    _showBlockedContacts(context);
                  },
                ),
                Divider(height: 1, color: Colors.white.withOpacity(0.1)),
                ListTile(
                  title: const Text('Активные сессии'),
                  subtitle: Text('Управление активными устройствами',
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.6), fontSize: 12)),
                  trailing: Icon(PhosphorIconsBold.caretRight,
                      color: Colors.white.withOpacity(0.5)),
                  onTap: () {
                    _showActiveSessions(context);
                  },
                ),
                Divider(height: 1, color: Colors.white.withOpacity(0.1)),
                ListTile(
                  title: const Text('Скрыть время последнего посещения'),
                  subtitle: Text('Скрыть время последнего посещения от всех',
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.6), fontSize: 12)),
                  trailing: Switch(
                    value: _hideLastSeenTime,
                    onChanged: (value) async {
                      await SettingsService.setHideLastSeenTime(value);
                      setState(() => _hideLastSeenTime = value);
                    },
                  ),
                ),
                Divider(height: 1, color: Colors.white.withOpacity(0.1)),
                ListTile(
                  title: const Text('Скрыть статус "печатает"'),
                  subtitle: Text('Не показывать когда вы печатаете',
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.6), fontSize: 12)),
                  trailing: Switch(
                    value: _hideTypingStatus,
                    onChanged: (value) async {
                      await SettingsService.setHideTypingStatus(value);
                      setState(() => _hideTypingStatus = value);
                    },
                  ),
                ),
                Divider(height: 1, color: Colors.white.withOpacity(0.1)),
                ListTile(
                  title: const Text('Защита скриншотов'),
                  subtitle: Text('Блокировать создание скриншотов',
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.6), fontSize: 12)),
                  trailing: Switch(
                    value: _screenshotProtection,
                    onChanged: (value) async {
                      await SettingsService.setScreenshotProtection(value);
                      setState(() => _screenshotProtection = value);
                      if (value) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Защита скриншотов включена')),
                        );
                      }
                    },
                  ),
                ),
                Divider(height: 1, color: Colors.white.withOpacity(0.1)),
                ListTile(
                  title: const Text('Скрыть пересылку сообщений'),
                  subtitle: Text('Запретить пересылку ваших сообщений',
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.6), fontSize: 12)),
                  trailing: Switch(
                    value: _hideForwarding,
                    onChanged: (value) async {
                      await SettingsService.setHideForwarding(value);
                      setState(() => _hideForwarding = value);
                    },
                  ),
                ),
                Divider(height: 1, color: Colors.white.withOpacity(0.1)),
                ListTile(
                  title: const Text('Скрыть копирование сообщений'),
                  subtitle: Text('Запретить копирование ваших сообщений',
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.6), fontSize: 12)),
                  trailing: Switch(
                    value: _hideCopying,
                    onChanged: (value) async {
                      await SettingsService.setHideCopying(value);
                      setState(() => _hideCopying = value);
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text('Данные и синхронизация',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          GlassContainer(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                ListTile(
                  title: const Text('Синхронизация облака'),
                  subtitle: Text('Синхронизировать данные с облаком',
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.6), fontSize: 12)),
                  trailing: Switch(
                    value: _cloudSync,
                    onChanged: (value) async {
                      await SettingsService.setCloudSync(value);
                      setState(() => _cloudSync = value);
                    },
                  ),
                ),
                Divider(height: 1, color: Colors.white.withOpacity(0.1)),
                ListTile(
                  title: const Text('Экспорт данных'),
                  subtitle: Text('Экспортировать все данные аккаунта',
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.6), fontSize: 12)),
                  trailing: Icon(PhosphorIconsBold.caretRight,
                      color: Colors.white.withOpacity(0.5)),
                  onTap: () {
                    _showExportDataDialog(context);
                  },
                ),
                Divider(height: 1, color: Colors.white.withOpacity(0.1)),
                ListTile(
                  title: const Text('Удалить все данные'),
                  subtitle: Text('Полное удаление всех данных аккаунта',
                      style: TextStyle(
                          color: Colors.redAccent.withOpacity(0.8),
                          fontSize: 12)),
                  trailing: Icon(PhosphorIconsBold.trash,
                      color: Colors.redAccent, size: 20),
                  onTap: () {
                    _showDeleteAllDataDialog(context);
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LanguageSettings extends StatefulWidget {
  @override
  State<_LanguageSettings> createState() => _LanguageSettingsState();
}

class _LanguageSettingsState extends State<_LanguageSettings> {
  String _selectedLanguage = 'Русский';
  final List<String> _languages = [
    'Русский',
    'English',
    'Deutsch',
    'Français',
    'Español',
    '中文'
  ];

  @override
  void initState() {
    super.initState();
    _selectedLanguage = SettingsService.getLanguage();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [
          Text('Язык интерфейса',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          GlassContainer(
            padding: EdgeInsets.zero,
            child: Column(
              children: _languages.map((lang) {
                final isSelected = _selectedLanguage == lang;
                return Column(
                  children: [
                    ListTile(
                      title: Text(lang),
                      trailing: isSelected
                          ? Icon(PhosphorIconsBold.check,
                              color: Theme.of(context).primaryColor)
                          : null,
                      onTap: () async {
                        await SettingsService.setLanguage(lang);
                        setState(() => _selectedLanguage = lang);
                      },
                    ),
                    if (lang != _languages.last)
                      Divider(height: 1, color: Colors.white.withOpacity(0.1)),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _BackupSettings extends StatefulWidget {
  @override
  State<_BackupSettings> createState() => _BackupSettingsState();
}

class _BackupSettingsState extends State<_BackupSettings> {
  bool _autoBackup = true;

  @override
  void initState() {
    super.initState();
    _autoBackup = SettingsService.getAutoBackupEnabled();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [
          Text('Резервное копирование',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          GlassContainer(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                ListTile(
                  leading: Icon(PhosphorIconsBold.cloudArrowUp,
                      color: Theme.of(context).primaryColor),
                  title: const Text('Создать резервную копию'),
                  subtitle: Text('Последнее: 2 дня назад',
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.6), fontSize: 12)),
                  trailing: Icon(PhosphorIconsBold.caretRight,
                      color: Colors.white.withOpacity(0.5)),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Резервная копия создана')),
                    );
                  },
                ),
                Divider(height: 1, color: Colors.white.withOpacity(0.1)),
                ListTile(
                  leading: Icon(PhosphorIconsBold.cloudArrowDown,
                      color: Theme.of(context).primaryColor),
                  title: const Text('Восстановить из копии'),
                  trailing: Icon(PhosphorIconsBold.caretRight,
                      color: Colors.white.withOpacity(0.5)),
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        backgroundColor: Colors.black87,
                        title: const Text('Восстановление'),
                        content: const Text(
                            'Выберите файл резервной копии для восстановления'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: const Text('Отмена'),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text('Данные восстановлены')),
                              );
                            },
                            child: const Text('Восстановить'),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                Divider(height: 1, color: Colors.white.withOpacity(0.1)),
                ListTile(
                  leading: Icon(PhosphorIconsBold.clock,
                      color: Theme.of(context).primaryColor),
                  title: const Text('Автоматическое копирование'),
                  subtitle: Text('Каждые 7 дней',
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.6), fontSize: 12)),
                  trailing: Switch(
                    value: _autoBackup,
                    onChanged: (value) async {
                      await SettingsService.setAutoBackupEnabled(value);
                      setState(() => _autoBackup = value);
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatisticsSettings extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [
          Text('Статистика',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          GlassContainer(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildStatRow('Отправлено сообщений', '1,234'),
                const SizedBox(height: 12),
                _buildStatRow('Получено сообщений', '3,456'),
                const SizedBox(height: 12),
                _buildStatRow('Медиа файлов', '567'),
                const SizedBox(height: 12),
                _buildStatRow('Использовано места', '2.3 ГБ'),
                const SizedBox(height: 12),
                _buildStatRow('Активных чатов', '12'),
              ],
            ),
          ),
          const SizedBox(height: 16),
          GlassButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Статистика экспортирована')),
              );
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(PhosphorIconsBold.export,
                    color: Theme.of(context).primaryColor, size: 20),
                const SizedBox(width: 8),
                const Text('Экспортировать статистику',
                    style: TextStyle(fontSize: 16)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: Colors.white.withOpacity(0.7))),
        Text(value,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
      ],
    );
  }
}

class _AboutSettings extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [
          Center(
            child: Column(
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Theme.of(context).primaryColor.withOpacity(0.2),
                  ),
                  child: Icon(PhosphorIconsBold.chatCircle,
                      size: 40, color: Theme.of(context).primaryColor),
                ),
                const SizedBox(height: 16),
                const Text('Mimu',
                    style:
                        TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                Text('Версия 1.0.0',
                    style: TextStyle(color: Colors.white.withOpacity(0.6))),
              ],
            ),
          ),
          const SizedBox(height: 32),
          GlassContainer(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                ListTile(
                  title: const Text('Лицензия'),
                  trailing: Icon(PhosphorIconsBold.caretRight,
                      color: Colors.white.withOpacity(0.5)),
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        backgroundColor: Colors.black87,
                        title: const Text('Лицензия'),
                        content: const SingleChildScrollView(
                          child: Text(
                            'Mimu - безопасный мессенджер\n\n'
                            'Copyright © 2024 Mimu\n\n'
                            'Все права защищены.\n\n'
                            'Это программное обеспечение распространяется под лицензией MIT.',
                            style: TextStyle(color: Colors.white70),
                          ),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: const Text('Закрыть'),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                Divider(height: 1, color: Colors.white.withOpacity(0.1)),
                ListTile(
                  title: const Text('Политика конфиденциальности'),
                  trailing: Icon(PhosphorIconsBold.caretRight,
                      color: Colors.white.withOpacity(0.5)),
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        backgroundColor: Colors.black87,
                        title: const Text('Политика конфиденциальности'),
                        content: const SingleChildScrollView(
                          child: Text(
                            'Mimu серьезно относится к вашей приватности.\n\n'
                            '• Все сообщения зашифрованы\n'
                            '• Мы не собираем личные данные\n'
                            '• Ваши данные хранятся локально\n'
                            '• Мы не передаем информацию третьим лицам\n\n'
                            'Подробная политика доступна на нашем сайте.',
                            style: TextStyle(color: Colors.white70),
                          ),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: const Text('Закрыть'),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                Divider(height: 1, color: Colors.white.withOpacity(0.1)),
                ListTile(
                  title: const Text('Условия использования'),
                  trailing: Icon(PhosphorIconsBold.caretRight,
                      color: Colors.white.withOpacity(0.5)),
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        backgroundColor: Colors.black87,
                        title: const Text('Условия использования'),
                        content: const SingleChildScrollView(
                          child: Text(
                            'Условия использования Mimu:\n\n'
                            '1. Используйте приложение ответственно\n'
                            '2. Не нарушайте права других пользователей\n'
                            '3. Запрещено распространение незаконного контента\n'
                            '4. Мы оставляем за собой право блокировать аккаунты\n\n'
                            'Полные условия доступны на нашем сайте.',
                            style: TextStyle(color: Colors.white70),
                          ),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: const Text('Закрыть'),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MyAccountSettings extends StatefulWidget {
  @override
  State<_MyAccountSettings> createState() => _MyAccountSettingsState();
}

class _MyAccountSettingsState extends State<_MyAccountSettings> {
  String? _avatarPath;
  String _displayName = 'Username';
  String _username = 'usermimu';
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    await UserService.init();
    setState(() {
      _displayName = UserService.getDisplayName();
      _username = UserService.getUsername();
      _avatarPath = UserService.getAvatarPath();
    });
  }

  Future<void> _changeAvatar() async {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: const EdgeInsets.all(12.0),
        child: GlassContainer(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(PhosphorIconsBold.images),
                title: const Text('Галерея'),
                onTap: () async {
                  Navigator.of(context).pop();
                  final XFile? file = await _picker.pickImage(
                      source: ImageSource.gallery, imageQuality: 85);
                  if (file != null) {
                    await UserService.setAvatarPath(file.path);
                    setState(() => _avatarPath = file.path);
                  }
                },
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(PhosphorIconsBold.camera),
                title: const Text('Камера'),
                onTap: () async {
                  Navigator.of(context).pop();
                  final XFile? file = await _picker.pickImage(
                      source: ImageSource.camera, imageQuality: 85);
                  if (file != null) {
                    await UserService.setAvatarPath(file.path);
                    setState(() => _avatarPath = file.path);
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [
          Center(
            child: Column(
              children: [
                GestureDetector(
                  onTap: _changeAvatar,
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundImage: _avatarPath != null &&
                                File(_avatarPath!).existsSync()
                            ? FileImage(File(_avatarPath!))
                            : const AssetImage(
                                    "assets/images/avatar_placeholder.png")
                                as ImageProvider,
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: CircleAvatar(
                          radius: 16,
                          backgroundColor: Theme.of(context).primaryColor,
                          child: const Icon(PhosphorIconsBold.pencilSimple,
                              size: 16, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Text(_displayName,
                    style: const TextStyle(
                        fontSize: 22, fontWeight: FontWeight.bold)),
                Text("@$_username",
                    style: TextStyle(
                        fontSize: 16, color: Colors.white.withOpacity(0.6))),
              ],
            ),
          ),
          const SizedBox(height: 24),
          GlassContainer(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                ListTile(
                  leading: Icon(PhosphorIconsBold.user,
                      color: Theme.of(context).primaryColor),
                  title: const Text('Изменить имя'),
                  trailing: Icon(PhosphorIconsBold.caretRight,
                      color: Colors.white.withOpacity(0.5)),
                  onTap: () {
                    final controller =
                        TextEditingController(text: _displayName);
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        backgroundColor: Colors.black87,
                        title: const Text('Изменить имя'),
                        content: TextField(
                          controller: controller,
                          style: const TextStyle(color: Colors.white),
                          decoration: const InputDecoration(
                            hintText: 'Новое имя',
                            hintStyle: TextStyle(color: Colors.white54),
                          ),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: const Text('Отмена'),
                          ),
                          TextButton(
                            onPressed: () async {
                              await UserService.setDisplayName(
                                  controller.text.trim());
                              setState(
                                  () => _displayName = controller.text.trim());
                              Navigator.of(context).pop();
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Имя изменено')),
                              );
                            },
                            child: const Text('Сохранить'),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                Divider(height: 1, color: Colors.white.withOpacity(0.1)),
                ListTile(
                  leading: Icon(PhosphorIconsBold.at,
                      color: Theme.of(context).primaryColor),
                  title: const Text('Изменить username'),
                  subtitle: Text('@$_username',
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.6), fontSize: 12)),
                  trailing: Icon(PhosphorIconsBold.caretRight,
                      color: Colors.white.withOpacity(0.5)),
                  onTap: () {
                    final controller = TextEditingController(text: _username);
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        backgroundColor: Colors.black87,
                        title: const Text('Изменить username'),
                        content: TextField(
                          controller: controller,
                          style: const TextStyle(color: Colors.white),
                          decoration: const InputDecoration(
                            hintText: 'Новый username',
                            hintStyle: TextStyle(color: Colors.white54),
                            prefixText: '@',
                          ),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: const Text('Отмена'),
                          ),
                          TextButton(
                            onPressed: () async {
                              await UserService.setUsername(
                                  controller.text.trim());
                              setState(
                                  () => _username = controller.text.trim());
                              Navigator.of(context).pop();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                    content: Text(
                                        'Username изменен на @${controller.text.trim()}')),
                              );
                            },
                            child: const Text('Сохранить'),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                Divider(height: 1, color: Colors.white.withOpacity(0.1)),
                ListTile(
                  leading: Icon(PhosphorIconsBold.lock,
                      color: Theme.of(context).primaryColor),
                  title: const Text('Изменить пароль'),
                  trailing: Icon(PhosphorIconsBold.caretRight,
                      color: Colors.white.withOpacity(0.5)),
                  onTap: () {
                    final oldPasswordController = TextEditingController();
                    final newPasswordController = TextEditingController();
                    final confirmPasswordController = TextEditingController();
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        backgroundColor: Colors.black87,
                        title: const Text('Изменить пароль'),
                        content: SingleChildScrollView(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              TextField(
                                controller: oldPasswordController,
                                obscureText: true,
                                style: const TextStyle(color: Colors.white),
                                decoration: const InputDecoration(
                                  hintText: 'Текущий пароль',
                                  hintStyle: TextStyle(color: Colors.white54),
                                ),
                              ),
                              const SizedBox(height: 12),
                              TextField(
                                controller: newPasswordController,
                                obscureText: true,
                                style: const TextStyle(color: Colors.white),
                                decoration: const InputDecoration(
                                  hintText: 'Новый пароль',
                                  hintStyle: TextStyle(color: Colors.white54),
                                ),
                              ),
                              const SizedBox(height: 12),
                              TextField(
                                controller: confirmPasswordController,
                                obscureText: true,
                                style: const TextStyle(color: Colors.white),
                                decoration: const InputDecoration(
                                  hintText: 'Подтвердите пароль',
                                  hintStyle: TextStyle(color: Colors.white54),
                                ),
                              ),
                            ],
                          ),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: const Text('Отмена'),
                          ),
                          TextButton(
                            onPressed: () {
                              if (newPasswordController.text ==
                                  confirmPasswordController.text) {
                                Navigator.of(context).pop();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text('Пароль изменен')),
                                );
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text('Пароли не совпадают')),
                                );
                              }
                            },
                            child: const Text('Сохранить'),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DataAndStorageSettings extends StatefulWidget {
  @override
  State<_DataAndStorageSettings> createState() =>
      _DataAndStorageSettingsState();
}

class _DataAndStorageSettingsState extends State<_DataAndStorageSettings> {
  bool _autoCleanMedia = true;
  bool _autoCleanCache = false;

  @override
  void initState() {
    super.initState();
    _autoCleanMedia = SettingsService.getAutoCleanMedia();
    _autoCleanCache = SettingsService.getAutoCleanCache();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [
          Text('Использование памяти',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          GlassContainer(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildStorageRow(context, 'Медиа и файлы', '1.2 ГБ', 0.6),
                const SizedBox(height: 12),
                _buildStorageRow(context, 'Сообщения', '450 МБ', 0.3),
                const SizedBox(height: 12),
                _buildStorageRow(context, 'Кэш', '120 МБ', 0.1),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text('Автоматическая очистка',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          GlassContainer(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                ListTile(
                  title: const Text('Очищать старые медиа'),
                  subtitle: Text('Старше 3 месяцев',
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.6), fontSize: 12)),
                  trailing: Switch(
                    value: _autoCleanMedia,
                    onChanged: (value) async {
                      await SettingsService.setAutoCleanMedia(value);
                      setState(() => _autoCleanMedia = value);
                    },
                  ),
                ),
                Divider(height: 1, color: Colors.white.withOpacity(0.1)),
                ListTile(
                  title: const Text('Очищать кэш автоматически'),
                  trailing: Switch(
                    value: _autoCleanCache,
                    onChanged: (value) async {
                      await SettingsService.setAutoCleanCache(value);
                      setState(() => _autoCleanCache = value);
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          GlassButton(
            onPressed: () {
              _showAnimatedDialog(
                context: context,
                title: 'Очистить кэш?',
                content: const Text(
                  'Это действие нельзя отменить',
                  style: TextStyle(color: Colors.white70),
                ),
                actions: [
                  GlassButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Padding(
                      padding:
                          EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      child: Text('Отмена'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  GlassButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Кэш очищен')),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      child: Text(
                        'Очистить',
                        style: TextStyle(color: Colors.redAccent),
                      ),
                    ),
                  ),
                ],
              );
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(PhosphorIconsBold.trash,
                    color: Colors.redAccent, size: 20),
                const SizedBox(width: 8),
                const Text('Очистить кэш',
                    style: TextStyle(color: Colors.redAccent, fontSize: 16)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStorageRow(
      BuildContext context, String label, String size, double progress) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: TextStyle(color: Colors.white.withOpacity(0.7))),
            Text(size, style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: progress,
          backgroundColor: Colors.white.withOpacity(0.1),
          valueColor:
              AlwaysStoppedAnimation<Color>(Theme.of(context).primaryColor),
        ),
      ],
    );
  }
}

class _PremiumSettings extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SafeArea(
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
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      PhosphorIconsBold.check,
                      color: Colors.white,
                      size: 20,
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
    );
  }

  void _showPremiumFeatures(BuildContext context) {
    _showAnimatedDialog(
      context: context,
      title: 'Функции Premium',
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
        GlassButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Center(child: Text('Понятно')),
          ),
        ),
      ],
    );
  }

  Widget _buildFeatureItem(BuildContext context, String text) {
    return Row(
      children: [
        Icon(PhosphorIconsBold.checkCircle,
            color: Theme.of(context).primaryColor, size: 20),
        const SizedBox(width: 12),
        Expanded(
            child: Text(text,
                style: TextStyle(color: Colors.white.withOpacity(0.9)))),
      ],
    );
  }
}

class _SupportSettings extends StatelessWidget {
  Widget _buildFAQItem(String question, String answer) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          question,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        const SizedBox(height: 4),
        Text(
          answer,
          style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [
          Text('Помощь и поддержка',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          GlassContainer(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                ListTile(
                  leading: Icon(PhosphorIconsBold.chatCircle,
                      color: Theme.of(context).primaryColor),
                  title: const Text('Написать в поддержку'),
                  trailing: Icon(PhosphorIconsBold.caretRight,
                      color: Colors.white.withOpacity(0.5)),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Открытие чата поддержки')),
                    );
                  },
                ),
                Divider(height: 1, color: Colors.white.withOpacity(0.1)),
                ListTile(
                  leading: Icon(PhosphorIconsBold.book,
                      color: Theme.of(context).primaryColor),
                  title: const Text('Часто задаваемые вопросы'),
                  trailing: Icon(PhosphorIconsBold.caretRight,
                      color: Colors.white.withOpacity(0.5)),
                  onTap: () {
                    _showAnimatedDialog(
                      context: context,
                      title: 'Часто задаваемые вопросы',
                      content: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _buildFAQItem('Как изменить тему?',
                                'Перейдите в Настройки > Внешний вид > Темы'),
                            const SizedBox(height: 12),
                            _buildFAQItem('Как переслать сообщение?',
                                'Долгое нажатие на сообщение > Переслать'),
                            const SizedBox(height: 12),
                            _buildFAQItem('Как создать группу?',
                                'Нажмите + в чатах > Новая группа'),
                            const SizedBox(height: 12),
                            _buildFAQItem('Как включить уведомления?',
                                'Настройки > Уведомления'),
                            const SizedBox(height: 12),
                            _buildFAQItem('Как изменить акцентный цвет?',
                                'Настройки > Внешний вид > Акцентный цвет'),
                            const SizedBox(height: 12),
                            _buildFAQItem('Как очистить кэш?',
                                'Настройки > Данные и Память > Очистить кэш'),
                          ],
                        ),
                      ),
                      actions: [
                        GlassButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Padding(
                            padding: EdgeInsets.symmetric(
                                horizontal: 16, vertical: 10),
                            child: Text('Закрыть'),
                          ),
                        ),
                      ],
                    );
                  },
                ),
                Divider(height: 1, color: Colors.white.withOpacity(0.1)),
                ListTile(
                  leading: Icon(PhosphorIconsBold.bug,
                      color: Theme.of(context).primaryColor),
                  title: const Text('Сообщить об ошибке'),
                  trailing: Icon(PhosphorIconsBold.caretRight,
                      color: Colors.white.withOpacity(0.5)),
                  onTap: () {
                    final controller = TextEditingController();
                    _showAnimatedDialog(
                      context: context,
                      title: 'Сообщить об ошибке',
                      content: TextField(
                        controller: controller,
                        style: const TextStyle(color: Colors.white),
                        maxLines: 5,
                        decoration: InputDecoration(
                          hintText: 'Опишите проблему...',
                          hintStyle:
                              TextStyle(color: Colors.white.withOpacity(0.5)),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                                color: Colors.white.withOpacity(0.2)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                                color: Theme.of(context).primaryColor),
                          ),
                        ),
                      ),
                      actions: [
                        GlassButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Padding(
                            padding: EdgeInsets.symmetric(
                                horizontal: 16, vertical: 10),
                            child: Text('Отмена'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        GlassButton(
                          onPressed: () {
                            if (controller.text.trim().isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content:
                                        Text('Пожалуйста, опишите проблему')),
                              );
                              return;
                            }
                            Navigator.of(context).pop();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text(
                                      'Спасибо! Ваше сообщение отправлено')),
                            );
                          },
                          child: const Padding(
                            padding: EdgeInsets.symmetric(
                                horizontal: 16, vertical: 10),
                            child: Text('Отправить'),
                          ),
                        ),
                      ],
                    );
                  },
                ),
                Divider(height: 1, color: Colors.white.withOpacity(0.1)),
                ListTile(
                  leading: Icon(PhosphorIconsBold.lightbulb,
                      color: Theme.of(context).primaryColor),
                  title: const Text('Предложить функцию'),
                  trailing: Icon(PhosphorIconsBold.caretRight,
                      color: Colors.white.withOpacity(0.5)),
                  onTap: () {
                    final controller = TextEditingController();
                    _showAnimatedDialog(
                      context: context,
                      title: 'Предложить функцию',
                      content: TextField(
                        controller: controller,
                        style: const TextStyle(color: Colors.white),
                        maxLines: 5,
                        decoration: InputDecoration(
                          hintText: 'Опишите вашу идею...',
                          hintStyle:
                              TextStyle(color: Colors.white.withOpacity(0.5)),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                                color: Colors.white.withOpacity(0.2)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                                color: Theme.of(context).primaryColor),
                          ),
                        ),
                      ),
                      actions: [
                        GlassButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Padding(
                            padding: EdgeInsets.symmetric(
                                horizontal: 16, vertical: 10),
                            child: Text('Отмена'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        GlassButton(
                          onPressed: () {
                            if (controller.text.trim().isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content:
                                        Text('Пожалуйста, опишите вашу идею')),
                              );
                              return;
                            }
                            Navigator.of(context).pop();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text('Спасибо за предложение!')),
                            );
                          },
                          child: const Padding(
                            padding: EdgeInsets.symmetric(
                                horizontal: 16, vertical: 10),
                            child: Text('Отправить'),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text('Полезные ссылки',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          GlassContainer(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                ListTile(
                  leading: Icon(PhosphorIconsBold.globe,
                      color: Theme.of(context).primaryColor),
                  title: const Text('Официальный сайт'),
                  trailing: Icon(PhosphorIconsBold.arrowSquareOut,
                      color: Colors.white.withOpacity(0.5)),
                  onTap: () async {
                    final uri = Uri.parse('https://mimu.app');
                    if (await canLaunchUrl(uri)) {
                      await launchUrl(uri,
                          mode: LaunchMode.externalApplication);
                    } else {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Не удалось открыть сайт')),
                        );
                      }
                    }
                  },
                ),
                Divider(height: 1, color: Colors.white.withOpacity(0.1)),
                ListTile(
                  leading: Icon(PhosphorIconsBold.chatCircle,
                      color: Theme.of(context).primaryColor),
                  title: const Text('Telegram канал'),
                  trailing: Icon(PhosphorIconsBold.arrowSquareOut,
                      color: Colors.white.withOpacity(0.5)),
                  onTap: () async {
                    final uri = Uri.parse('https://t.me/mimu_channel');
                    if (await canLaunchUrl(uri)) {
                      await launchUrl(uri,
                          mode: LaunchMode.externalApplication);
                    } else {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Не удалось открыть Telegram')),
                        );
                      }
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsGroup extends StatelessWidget {
  final String title;
  final List<_SettingsItem> items;
  const _SettingsGroup({required this.title, required this.items});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 16.0, bottom: 8.0),
          child: Text(title,
              style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontWeight: FontWeight.bold)),
        ),
        GlassContainer(
          padding: EdgeInsets.zero,
          child: Column(
            children: List.generate(items.length, (index) {
              return Column(
                children: [
                  items[index],
                  if (index != items.length - 1)
                    Divider(
                        height: 1,
                        indent: 56,
                        color: Colors.white.withOpacity(0.1)),
                ],
              );
            }),
          ),
        ),
      ],
    );
  }
}

class _SettingsItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _SettingsItem(
      {required this.icon, required this.title, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(15),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child:
                    Icon(icon, color: Theme.of(context).primaryColor, size: 20),
              ),
              const SizedBox(width: 16),
              Expanded(
                  child: Text(title,
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w500))),
              Icon(PhosphorIconsBold.caretRight,
                  color: Colors.white.withOpacity(0.5), size: 18),
            ],
          ),
        ),
      ),
    );
  }
}

// Helper function to build FAQ item for support settings
Widget _buildFAQItem(String question, String answer) {
  return Builder(
    builder: (context) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(PhosphorIconsBold.question,
                size: 16, color: Theme.of(context).primaryColor),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                question,
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.only(left: 24),
          child: Text(
            answer,
            style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 12,
                height: 1.4),
          ),
        ),
      ],
    ),
  );
}

// Helper function for animated dialogs with fakeglass
void _showAnimatedDialog({
  required BuildContext context,
  required String title,
  required Widget content,
  required List<Widget> actions,
}) {
  showDialog(
    context: context,
    barrierColor: Colors.black.withOpacity(0.5),
    builder: (context) {
      return TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.0, end: 1.0),
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        builder: (context, value, child) {
          return Transform.scale(
            scale: 0.9 + (value * 0.1),
            child: Opacity(
              opacity: value,
              child: Dialog(
                backgroundColor: Colors.transparent,
                insetPadding: const EdgeInsets.all(24),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                    child: GlassContainer(
                      padding: const EdgeInsets.all(24),
                      decoration: Theme.of(context)
                          .extension<GlassTheme>()!
                          .baseGlass
                          .copyWith(
                            color: Theme.of(context)
                                .primaryColor
                                .withOpacity(0.12),
                            borderRadius: BorderRadius.circular(20),
                          ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                                fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 16),
                          content,
                          const SizedBox(height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: actions,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      );
    },
  );
}

// Blocked contacts screen
void _showBlockedContacts(BuildContext context) {
  Navigator.of(context).push(
    MaterialPageRoute(
      builder: (context) => Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: GlassIconButton(
            icon: PhosphorIconsBold.caretLeft,
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: const Text('Заблокированные контакты'),
        ),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              GlassContainer(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Icon(PhosphorIconsBold.userMinus,
                        size: 48, color: Colors.white.withOpacity(0.5)),
                    const SizedBox(height: 16),
                    Text(
                      'Нет заблокированных контактов',
                      style: TextStyle(color: Colors.white.withOpacity(0.7)),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Контакты, которых вы заблокируете, не смогут отправлять вам сообщения',
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.5), fontSize: 12),
                      textAlign: TextAlign.center,
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

// Active sessions screen
void _showActiveSessions(BuildContext context) {
  Navigator.of(context).push(
    MaterialPageRoute(
      builder: (context) => Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: GlassIconButton(
            icon: PhosphorIconsBold.caretLeft,
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: const Text('Активные сессии'),
        ),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              GlassContainer(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    ListTile(
                      leading: Icon(PhosphorIconsBold.deviceMobile,
                          color: Theme.of(context).primaryColor),
                      title: const Text('Это устройство'),
                      subtitle: Text('Текущая сессия',
                          style:
                              TextStyle(color: Colors.white.withOpacity(0.6))),
                      trailing: Icon(PhosphorIconsBold.check,
                          color: Theme.of(context).primaryColor),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Завершить все другие сессии',
                style: TextStyle(color: Colors.redAccent, fontSize: 14),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

// Export data dialog
void _showExportDataDialog(BuildContext context) {
  _showAnimatedDialog(
    context: context,
    title: 'Экспорт данных',
    content: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Все ваши данные будут экспортированы в JSON файл. Это может занять некоторое время.',
          style: TextStyle(color: Colors.white.withOpacity(0.8)),
        ),
        const SizedBox(height: 16),
        Text(
          'Будут экспортированы:',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text('• Сообщения',
            style: TextStyle(color: Colors.white.withOpacity(0.7))),
        Text('• Контакты',
            style: TextStyle(color: Colors.white.withOpacity(0.7))),
        Text('• Настройки',
            style: TextStyle(color: Colors.white.withOpacity(0.7))),
        Text('• Медиафайлы (ссылки)',
            style: TextStyle(color: Colors.white.withOpacity(0.7))),
      ],
    ),
    actions: [
      GlassButton(
        onPressed: () => Navigator.of(context).pop(),
        child: const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Text('Отмена'),
        ),
      ),
      const SizedBox(width: 12),
      GlassButton(
        onPressed: () {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text(
                    'Экспорт данных начат. Файл будет сохранен в загрузки.')),
          );
        },
        child: const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Text('Экспортировать'),
        ),
      ),
    ],
  );
}

// Delete all data dialog
void _showDeleteAllDataDialog(BuildContext context) {
  _showAnimatedDialog(
    context: context,
    title: 'Удалить все данные?',
    content: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Это действие нельзя отменить. Все ваши данные будут безвозвратно удалены:',
          style: TextStyle(color: Colors.white.withOpacity(0.8)),
        ),
        const SizedBox(height: 16),
        Text('• Все сообщения',
            style: TextStyle(color: Colors.redAccent.withOpacity(0.8))),
        Text('• Все контакты',
            style: TextStyle(color: Colors.redAccent.withOpacity(0.8))),
        Text('• Все настройки',
            style: TextStyle(color: Colors.redAccent.withOpacity(0.8))),
        Text('• Все медиафайлы',
            style: TextStyle(color: Colors.redAccent.withOpacity(0.8))),
        const SizedBox(height: 16),
        Text(
          'Вы уверены?',
          style:
              TextStyle(fontWeight: FontWeight.bold, color: Colors.redAccent),
        ),
      ],
    ),
    actions: [
      GlassButton(
        onPressed: () => Navigator.of(context).pop(),
        child: const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Text('Отмена'),
        ),
      ),
      const SizedBox(width: 12),
      GlassButton(
        onPressed: () {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Все данные удалены'),
              backgroundColor: Colors.redAccent,
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Text(
            'Удалить',
            style: TextStyle(color: Colors.redAccent),
          ),
        ),
      ),
    ],
  );
}

// Bubble radius dialog
void _showBubbleRadiusDialog(BuildContext context) {
  double currentRadius = SettingsService.getBubbleRadius();
  _showAnimatedDialog(
    context: context,
    title: 'Скругление углов',
    content: StatefulBuilder(
      builder: (context, setState) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '${currentRadius.toInt()}px',
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Slider(
            value: currentRadius,
            min: 0,
            max: 30,
            divisions: 30,
            label: '${currentRadius.toInt()}px',
            onChanged: (value) {
              setState(() => currentRadius = value);
            },
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              TextButton(
                onPressed: () {
                  setState(() => currentRadius = 0);
                },
                child: const Text('0px'),
              ),
              TextButton(
                onPressed: () {
                  setState(() => currentRadius = 8);
                },
                child: const Text('8px'),
              ),
              TextButton(
                onPressed: () {
                  setState(() => currentRadius = 16);
                },
                child: const Text('16px'),
              ),
              TextButton(
                onPressed: () {
                  setState(() => currentRadius = 30);
                },
                child: const Text('30px'),
              ),
            ],
          ),
        ],
      ),
    ),
    actions: [
      GlassButton(
        onPressed: () => Navigator.of(context).pop(),
        child: const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Text('Отмена'),
        ),
      ),
      const SizedBox(width: 12),
      GlassButton(
        onPressed: () async {
          await SettingsService.setBubbleRadius(currentRadius);
          if (context.mounted) {
            Navigator.of(context).pop();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Скругление углов обновлено')),
            );
          }
        },
        child: const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Text('Применить'),
        ),
      ),
    ],
  );
}

// Background opacity dialog
void _showBackgroundOpacityDialog(BuildContext context) {
  double currentOpacity = SettingsService.getChatBackgroundOpacity();
  _showAnimatedDialog(
    context: context,
    title: 'Прозрачность фона',
    content: StatefulBuilder(
      builder: (context, setState) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '${(currentOpacity * 100).toInt()}%',
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Slider(
            value: currentOpacity,
            min: 0.0,
            max: 1.0,
            divisions: 20,
            label: '${(currentOpacity * 100).toInt()}%',
            onChanged: (value) {
              setState(() => currentOpacity = value);
            },
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              TextButton(
                onPressed: () {
                  setState(() => currentOpacity = 0.0);
                },
                child: const Text('0%'),
              ),
              TextButton(
                onPressed: () {
                  setState(() => currentOpacity = 0.3);
                },
                child: const Text('30%'),
              ),
              TextButton(
                onPressed: () {
                  setState(() => currentOpacity = 0.5);
                },
                child: const Text('50%'),
              ),
              TextButton(
                onPressed: () {
                  setState(() => currentOpacity = 1.0);
                },
                child: const Text('100%'),
              ),
            ],
          ),
        ],
      ),
    ),
    actions: [
      GlassButton(
        onPressed: () => Navigator.of(context).pop(),
        child: const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Text('Отмена'),
        ),
      ),
      const SizedBox(width: 12),
      GlassButton(
        onPressed: () async {
          await SettingsService.setChatBackgroundOpacity(currentOpacity);
          if (context.mounted) {
            Navigator.of(context).pop();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Прозрачность фона обновлена')),
            );
          }
        },
        child: const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Text('Применить'),
        ),
      ),
    ],
  );
}
