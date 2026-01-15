import 'dart:ui';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:mimu/shared/glass_widgets.dart';
import 'package:mimu/shared/animated_widgets.dart';
import 'package:mimu/app/theme.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:mimu/features/call_screen.dart';
import 'package:mimu/app/routes.dart';
import 'package:mimu/data/chat_store.dart';
import 'package:mimu/data/models/chat_models.dart';
import 'package:mimu/data/settings_service.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:mimu/shared/cupertino_dialogs.dart';
import 'package:path_provider/path_provider.dart';

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
  String _displayName = '';
  String? _contactId;
  final List<String> _mediaFiles = [
    'assets/images/avatar_placeholder.png',
    'assets/images/avatar_placeholder.png',
    'assets/images/avatar_placeholder.png',
  ];

  @override
  void initState() {
    super.initState();
    _displayName = widget.userName;
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadContactState());
  }

  Future<void> _loadContactState() async {
    final store = context.read<ChatStore>();
    final contact = store.contactByName(widget.userName) ?? store.contactById(widget.userName);
    setState(() {
      _contactId = contact?.id;
      _displayName = contact?.name ?? widget.userName;
      _isBlocked = contact != null ? store.isContactBlocked(contact.id) : false;
      _isIgnored = contact != null ? store.isContactIgnored(contact.id) : false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF1C1C1E).withOpacity(0.95),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(CupertinoIcons.back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(CupertinoIcons.ellipsis),
            onPressed: () => _showMoreOptions(context),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.zero,
          children: [
            // Заголовок профиля в стиле Telegram iOS
            AnimateOnDisplay(
              child: Container(
                padding: const EdgeInsets.all(24),
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
                              border: Border.all(
                                color: const Color(0xFF1C1C1E),
                                width: 3,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _displayName,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _status,
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.white.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            // Описание в стиле Telegram iOS
            AnimateOnDisplay(
              delayMs: 100,
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF2C2C2E),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Описание',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.6),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Пользователь ещё не добавил описание.',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            AnimateOnDisplay(
              delayMs: 200,
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFF2C2C2E),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  children: [
                    _actionRow(
                      context,
                      CupertinoIcons.phone_fill,
                      'Позвонить',
                      () async {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => CallScreen(
                              userName: _displayName,
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
                      CupertinoIcons.videocam_fill,
                      'Видеозвонок',
                      () async {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => CallScreen(
                              userName: _displayName,
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
                      CupertinoIcons.photo_fill,
                      'Медиа',
                      () => _showMediaGallery(context),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            AnimateOnDisplay(
              delayMs: 300,
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFF2C2C2E),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  children: [
                    _actionRow(
                      context,
                      CupertinoIcons.pencil,
                      'Переименовать в контактах',
                      () => _showRenameDialog(context),
                    ),
                    Divider(
                      height: 0.5,
                      thickness: 0.5,
                      indent: 56,
                      color: Colors.white.withOpacity(0.1),
                    ),
                    _actionRow(
                      context,
                      _isIgnored ? CupertinoIcons.eye_fill : CupertinoIcons.eye_slash_fill,
                      _isIgnored ? 'Прекратить игнорировать' : 'Игнорировать',
                      () async {
                        if (_contactId != null) {
                          await context.read<ChatStore>().setContactIgnored(_contactId!, !_isIgnored);
                        }
                        setState(() => _isIgnored = !_isIgnored);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(_isIgnored ? 'Пользователь игнорируется' : 'Игнорирование отменено')),
                        );
                      },
                    ),
                    Divider(
                      height: 0.5,
                      thickness: 0.5,
                      indent: 56,
                      color: Colors.white.withOpacity(0.1),
                    ),
                    _actionRow(
                      context,
                      _isBlocked ? CupertinoIcons.person_add_solid : CupertinoIcons.person_fill,
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
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          if (SettingsService.getVibrationEnabled()) {
            HapticFeedback.lightImpact();
          }
          onTap();
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Icon(
                icon,
                color: isDestructive ? Colors.redAccent : Colors.white.withOpacity(0.9),
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: isDestructive ? Colors.redAccent : Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
              Icon(
                CupertinoIcons.chevron_right,
                color: Colors.white.withOpacity(0.3),
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showMoreOptions(BuildContext context) {
    showCupertinoModalPopup(
      context: context,
      filter: ImageFilter.blur(sigmaX: 0.5, sigmaY: 0.5),
      builder: (context) => buildCupertinoActionSheet(
        context: context,
        actions: [
          CupertinoActionSheetAction(
            onPressed: () async {
              Navigator.of(context).pop();
              try {
                await Share.share('Контакт: $_displayName\n@${_displayName.toLowerCase().replaceAll(' ', '')}');
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Не удалось поделиться контактом')),
                  );
                }
              }
            },
            child: const Text('Поделиться контактом'),
          ),
          CupertinoActionSheetAction(
            onPressed: () async {
              Navigator.of(context).pop();
              _showExportPicker(context);
            },
            child: const Text('Экспорт чата'),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Отмена'),
        ),
      ),
    );
  }

  void _showMediaGallery(BuildContext context) {
    showCupertinoDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 2, sigmaY: 2),
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
                      icon: const Icon(CupertinoIcons.xmark),
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
    );
  }

  void _showRenameDialog(BuildContext context) {
    final controller = TextEditingController(text: _displayName);
    showCupertinoDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => buildCupertinoDialog(
        context: context,
        title: 'Переименовать',
        content: CupertinoTextField(
          controller: controller,
          placeholder: 'Новое имя',
          style: const TextStyle(color: CupertinoColors.white),
          decoration: BoxDecoration(
            color: CupertinoColors.black.withOpacity(0.3),
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Отмена'),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () async {
              Navigator.of(context).pop();
              final newName = controller.text.trim();
              if (newName.isEmpty) return;
              if (_contactId != null) {
                await context.read<ChatStore>().renameContact(_contactId!, newName);
              }
              setState(() => _displayName = newName);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Имя изменено на $newName')),
                );
              }
            },
            child: const Text('Сохранить'),
          ),
        ],
      ),
    );
  }

  void _showBlockDialog(BuildContext context) {
    showCupertinoDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => buildCupertinoDialog(
        context: context,
        title: _isBlocked ? 'Разблокировать пользователя?' : 'Заблокировать пользователя?',
        content: Text(
          _isBlocked
              ? 'Пользователь снова сможет отправлять вам сообщения'
              : 'Пользователь не сможет отправлять вам сообщения',
          style: TextStyle(color: Colors.white.withOpacity(0.7)),
          textAlign: TextAlign.center,
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Отмена'),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () {
              if (_contactId != null) {
                context.read<ChatStore>().setContactBlocked(_contactId!, !_isBlocked);
              }
              setState(() => _isBlocked = !_isBlocked);
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(_isBlocked ? 'Пользователь заблокирован' : 'Пользователь разблокирован')),
              );
            },
            child: Text(_isBlocked ? 'Разблокировать' : 'Заблокировать'),
          ),
        ],
      ),
    );
  }

  Future<void> _showExportPicker(BuildContext context) async {
    final chatStore = context.read<ChatStore>();
    final threads = chatStore.threads;
    if (threads.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Нет чатов для экспорта')),
      );
      return;
    }

    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => GlassContainer(
        child: ListView.separated(
          shrinkWrap: true,
          itemBuilder: (ctx, index) {
            final chat = threads[index];
            return ListTile(
              leading: CircleAvatar(
                backgroundImage: chat.avatarAsset.startsWith('assets/')
                    ? AssetImage(chat.avatarAsset)
                    : const AssetImage('assets/images/avatar_placeholder.png'),
              ),
              title: Text(chat.title),
              subtitle: Text(chat.isGroup ? 'Группа' : 'Диалог'),
              onTap: () async {
                Navigator.of(ctx).pop();
                await _exportChat(chat);
              },
            );
          },
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemCount: threads.length,
        ),
      ),
    );
  }

  Future<void> _exportChat(ChatThread chat) async {
    if (!context.mounted) return;
    
    // Показываем индикатор прогресса
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => WillPopScope(
        onWillPop: () async => false,
        child: Dialog(
          backgroundColor: Colors.transparent,
          child: GlassContainer(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CupertinoActivityIndicator(radius: 16),
                const SizedBox(height: 16),
                Text(
                  'Экспорт чата...',
                  style: TextStyle(color: Colors.white.withOpacity(0.9)),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      final buffer = StringBuffer();
      buffer.writeln('Экспорт чата: ${chat.title}');
      buffer.writeln('Дата экспорта: ${DateTime.now()}');
      buffer.writeln('');
      for (final message in chat.messages) {
        final time =
            '${message.timestamp.hour.toString().padLeft(2, '0')}:${message.timestamp.minute.toString().padLeft(2, '0')}';
        final sender = message.isMe ? 'Вы' : chat.title;
        buffer.writeln('[$time] $sender: ${message.text ?? message.type.name}');
      }

      final dir = await getTemporaryDirectory();
      final filePath =
          '${dir.path}/chat_${chat.id}_${DateTime.now().millisecondsSinceEpoch}.txt';
      final file = File(filePath);
      await file.writeAsString(buffer.toString());
      
      if (context.mounted) {
        Navigator.of(context).pop(); // Закрываем индикатор прогресса
        await Share.shareXFiles([XFile(file.path)],
            text: 'Экспорт чата ${chat.title}');
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.of(context).pop(); // Закрываем индикатор прогресса
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Не удалось экспортировать чат: $e')),
        );
      }
    }
  }
}

