import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:mimu/shared/glass_widgets.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:mimu/shared/animated_widgets.dart';
import 'package:mimu/app/theme.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:mimu/features/call_screen.dart';
import 'package:mimu/app/routes.dart';
import 'package:mimu/data/chat_store.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

class ProfileScreen extends StatefulWidget {
  final String userName;
  final String avatarAsset;
  const ProfileScreen({super.key, required this.userName, required this.avatarAsset});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isBlocked = false;
  bool _isIgnored = false;
  String _status = 'в сети';
  final List<String> _mediaFiles = [
    'assets/images/avatar_placeholder.png',
    'assets/images/avatar_placeholder.png',
    'assets/images/avatar_placeholder.png',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(PhosphorIconsBold.caretLeft),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: Icon(PhosphorIconsBold.dotsThreeVertical),
            onPressed: () => _showMoreOptions(context),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(16),
          children: [
            AnimateOnDisplay(
              child: Column(
                children: [
                  Stack(
                    children: [
                      CircleAvatar(
                        radius: 56,
                        backgroundImage: AssetImage(widget.avatarAsset),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.green,
                            border: Border.all(color: Colors.black, width: 2),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(widget.userName, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(_status, style: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.7))),
                ],
              ),
            ),
            const SizedBox(height: 24),
            AnimateOnDisplay(
              delayMs: 100,
              child: GlassContainer(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Описание', style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12)),
                    const SizedBox(height: 8),
                    const Text('Пользователь ещё не добавил описание.'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            AnimateOnDisplay(
              delayMs: 200,
              child: GlassContainer(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    _actionRow(
                      context,
                      PhosphorIconsBold.phone,
                      'Позвонить',
                      () async {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => CallScreen(
                              userName: widget.userName,
                              avatarAsset: widget.avatarAsset,
                              isIncoming: false,
                              isVideoCall: false,
                            ),
                            fullscreenDialog: true,
                          ),
                        );
                        if (result == true && context.mounted) {
                          // Звонок принят, можно добавить сообщение в чат
                        }
                      },
                    ),
                    const Divider(height: 1),
                    _actionRow(
                      context,
                      PhosphorIconsBold.videoCamera,
                      'Видеозвонок',
                      () async {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => CallScreen(
                              userName: widget.userName,
                              avatarAsset: widget.avatarAsset,
                              isIncoming: false,
                              isVideoCall: true,
                            ),
                            fullscreenDialog: true,
                          ),
                        );
                        if (result == true && context.mounted) {
                          // Видеозвонок принят
                        }
                      },
                    ),
                    const Divider(height: 1),
                    _actionRow(
                      context,
                      PhosphorIconsBold.images,
                      'Медиа',
                      () => _showMediaGallery(context),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            AnimateOnDisplay(
              delayMs: 300,
              child: GlassContainer(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    _actionRow(
                      context,
                      PhosphorIconsBold.pencilSimple,
                      'Переименовать в контактах',
                      () => _showRenameDialog(context),
                    ),
                    const Divider(height: 1),
                    _actionRow(
                      context,
                      _isIgnored ? PhosphorIconsBold.eye : PhosphorIconsBold.eyeSlash,
                      _isIgnored ? 'Прекратить игнорировать' : 'Игнорировать',
                      () {
                        setState(() => _isIgnored = !_isIgnored);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(_isIgnored ? 'Пользователь игнорируется' : 'Игнорирование отменено')),
                        );
                      },
                    ),
                    const Divider(height: 1),
                    _actionRow(
                      context,
                      _isBlocked ? PhosphorIconsBold.userPlus : PhosphorIconsBold.userMinus,
                      _isBlocked ? 'Разблокировать' : 'Заблокировать',
                      () => _showBlockDialog(context),
                      isDestructive: !_isBlocked,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _actionRow(BuildContext context, IconData icon, String title, VoidCallback onTap, {bool isDestructive = false}) {
    return ListTile(
      leading: Icon(icon, color: isDestructive ? Colors.redAccent : Theme.of(context).primaryColor),
      title: Text(title, style: TextStyle(color: isDestructive ? Colors.redAccent : null)),
      onTap: onTap,
    );
  }

  void _showMoreOptions(BuildContext context) {
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
                leading: const Icon(PhosphorIconsBold.share),
                title: const Text('Поделиться контактом'),
                onTap: () async {
                  Navigator.of(context).pop();
                  try {
                    await Share.share('Контакт: ${widget.userName}\n@${widget.userName.toLowerCase().replaceAll(' ', '')}');
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Не удалось поделиться контактом')),
                      );
                    }
                  }
                },
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(PhosphorIconsBold.export),
                title: const Text('Экспорт чата'),
                onTap: () async {
                  Navigator.of(context).pop();
                  final chatStore = Provider.of<ChatStore>(context, listen: false);
                  final chat = chatStore.threads.firstWhere(
                    (t) => t.title == widget.userName,
                    orElse: () => chatStore.threads.first,
                  );
                  
                  final exportText = StringBuffer();
                  exportText.writeln('Экспорт чата: ${chat.title}');
                  exportText.writeln('Дата экспорта: ${DateTime.now()}');
                  exportText.writeln('');
                  
                  for (final message in chat.messages) {
                    final time = '${message.timestamp.hour.toString().padLeft(2, '0')}:${message.timestamp.minute.toString().padLeft(2, '0')}';
                    final sender = message.isMe ? 'Вы' : chat.title;
                    exportText.writeln('[$time] $sender: ${message.text ?? ''}');
                  }
                  
                  try {
                    await Share.share(exportText.toString(), subject: 'Экспорт чата ${chat.title}');
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Не удалось экспортировать чат')),
                      );
                    }
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showMediaGallery(BuildContext context) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.5),
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: GlassContainer(
              padding: const EdgeInsets.all(24),
              decoration: Theme.of(context).extension<GlassTheme>()!.baseGlass.copyWith(
                color: Theme.of(context).primaryColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      const Text('Медиа', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(PhosphorIconsBold.x),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 300,
                    child: GridView.builder(
                      shrinkWrap: true,
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                      ),
                      itemCount: _mediaFiles.length,
                      itemBuilder: (context, index) {
                        return GestureDetector(
                          onTap: () => Navigator.of(context).pop(),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.asset(_mediaFiles[index], fit: BoxFit.cover),
                          )
                            .animate()
                            .fadeIn(duration: Duration(milliseconds: 300 + (index * 50)))
                            .scale(begin: const Offset(0.9, 0.9), end: const Offset(1.0, 1.0), duration: const Duration(milliseconds: 300)),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      )
        .animate()
        .fadeIn(duration: const Duration(milliseconds: 300))
        .scale(begin: const Offset(0.9, 0.9), end: const Offset(1.0, 1.0), duration: const Duration(milliseconds: 300), curve: Curves.easeOutCubic),
    );
  }

  void _showRenameDialog(BuildContext context) {
    final controller = TextEditingController(text: widget.userName);
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.5),
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: GlassContainer(
              padding: const EdgeInsets.all(24),
              decoration: Theme.of(context).extension<GlassTheme>()!.baseGlass.copyWith(
                color: Theme.of(context).primaryColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Переименовать', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 20),
                  TextField(
                    controller: controller,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Новое имя',
                      hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.08),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Отмена'),
                      ),
                      const SizedBox(width: 8),
                      GlassButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Имя изменено на ${controller.text}')),
                          );
                        },
                        child: const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: Text('Сохранить'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      )
        .animate()
        .fadeIn(duration: const Duration(milliseconds: 300))
        .scale(begin: const Offset(0.9, 0.9), end: const Offset(1.0, 1.0), duration: const Duration(milliseconds: 300), curve: Curves.easeOutCubic),
    );
  }

  void _showBlockDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.5),
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: GlassContainer(
              padding: const EdgeInsets.all(24),
              decoration: Theme.of(context).extension<GlassTheme>()!.baseGlass.copyWith(
                color: Colors.red.withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(PhosphorIconsBold.warning, color: Colors.redAccent, size: 48),
                  const SizedBox(height: 16),
                  Text(
                    _isBlocked ? 'Разблокировать пользователя?' : 'Заблокировать пользователя?',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _isBlocked
                        ? 'Пользователь снова сможет отправлять вам сообщения'
                        : 'Пользователь не сможет отправлять вам сообщения',
                    style: TextStyle(color: Colors.white.withOpacity(0.7)),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Отмена'),
                      ),
                      const SizedBox(width: 8),
                      GlassButton(
                        onPressed: () {
                          setState(() => _isBlocked = !_isBlocked);
                          Navigator.of(context).pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(_isBlocked ? 'Пользователь заблокирован' : 'Пользователь разблокирован')),
                          );
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: Text(
                            _isBlocked ? 'Разблокировать' : 'Заблокировать',
                            style: const TextStyle(color: Colors.redAccent),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      )
        .animate()
        .fadeIn(duration: const Duration(milliseconds: 300))
        .scale(begin: const Offset(0.9, 0.9), end: const Offset(1.0, 1.0), duration: const Duration(milliseconds: 300), curve: Curves.easeOutCubic),
    );
  }
}

