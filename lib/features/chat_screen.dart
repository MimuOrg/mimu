import 'dart:ui';
import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/gestures.dart';
import 'package:mimu/data/chat_store.dart';
import 'package:mimu/data/models/chat_models.dart';
import 'package:mimu/shared/animated_widgets.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:mimu/shared/glass_widgets.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import 'package:mimu/app/theme.dart';
import 'package:mimu/features/call_screen.dart';
import 'package:mimu/features/group_settings_screen.dart';
import 'package:mimu/app/routes.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:mimu/data/settings_service.dart';

class ChatScreen extends StatefulWidget {
  final String chatId;

  const ChatScreen({super.key, required this.chatId});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with TickerProviderStateMixin {
  final ImagePicker _picker = ImagePicker();
  final AudioRecorder _recorder = AudioRecorder();
  final AudioPlayer _player = AudioPlayer();
  bool _isRecording = false;
  DateTime? _recordStart;
  Duration _recordDuration = Duration.zero;
  bool _isTyping = false;
  String? _replyToMessageId;
  String? _replyToMessageText;
  final ScrollController _scrollController = ScrollController();
  final Set<String> _sentFiles = {}; // Предотвращение повторной отправки
  Timer? _recordTimer;
  late AnimationController _avatarGlowController;
  bool _isChatSearchActive = false;
  final TextEditingController _chatSearchController = TextEditingController();
  bool _isDialogOpen = false; // Отслеживание открытых диалогов/меню
  bool _isEmojiPanelVisible = false; // Видимость панели эмодзи

  @override
  void initState() {
    super.initState();
    _avatarGlowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _recordTimer?.cancel();
    _avatarGlowController.dispose();
    _player.dispose();
    _recorder.dispose();
    _scrollController.dispose();
    _chatSearchController.dispose();
    super.dispose();
  }

  Future<void> _addTextMessage(String text) async {
    final store = context.read<ChatStore>();
    final now = DateTime.now();
    final message = ChatMessage(
      id: now.millisecondsSinceEpoch.toString(),
      type: ChatMessageType.text,
        text: text,
        isMe: true,
      timestamp: now,
      isRead: true,
    );
    await store.addMessage(widget.chatId, message);
    _scrollToBottom();
  }

  Future<void> _addImageMessage(String path, {String? caption}) async {
    final store = context.read<ChatStore>();
    final now = DateTime.now();
    final message = ChatMessage(
      id: now.millisecondsSinceEpoch.toString(),
      type: ChatMessageType.image,
        mediaPath: path,
        text: caption,
        isMe: true,
      timestamp: now,
      isRead: true,
    );
    await store.addMessage(widget.chatId, message);
    _scrollToBottom();
  }

  Future<void> _addVoiceMessage(String audioPath, Duration duration) async {
    final store = context.read<ChatStore>();
    final now = DateTime.now();
    final message = ChatMessage(
      id: now.millisecondsSinceEpoch.toString(),
      type: ChatMessageType.voice,
        mediaPath: audioPath,
      voiceDurationSeconds: duration.inSeconds,
        isMe: true,
      timestamp: now,
      isRead: true,
    );
    await store.addMessage(widget.chatId, message);
    // Анимация отправки с вибрацией
    HapticFeedback.lightImpact();
    _scrollToBottom();
  }

  Future<void> _addFileMessage(String path, String fileName, {String? caption}) async {
    // Предотвращение повторной отправки
    final fileKey = '$path|$fileName';
    if (_sentFiles.contains(fileKey)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Этот файл уже был отправлен')),
      );
      return;
    }
    
    final store = context.read<ChatStore>();
    final now = DateTime.now();
    final message = ChatMessage(
      id: now.millisecondsSinceEpoch.toString(),
      type: ChatMessageType.file,
        mediaPath: path,
        text: caption ?? fileName,
        isMe: true,
      timestamp: now,
      isRead: true,
    );
    await store.addMessage(widget.chatId, message);
    _sentFiles.add(fileKey);
    _scrollToBottom();
  }

  Future<void> _addCallMessage(bool isIncoming, bool isVideoCall) async {
    final store = context.read<ChatStore>();
    final now = DateTime.now();
    final message = ChatMessage(
      id: now.millisecondsSinceEpoch.toString(),
      type: ChatMessageType.call,
      text: isIncoming 
          ? (isVideoCall ? 'Входящий видеозвонок' : 'Входящий звонок')
          : (isVideoCall ? 'Исходящий видеозвонок' : 'Исходящий звонок'),
      isMe: !isIncoming,
      timestamp: now,
      isRead: true,
    );
    await store.addMessage(widget.chatId, message);
    _scrollToBottom();
  }

  Future<void> _addLocationMessage() async {
    final store = context.read<ChatStore>();
    final now = DateTime.now();
    final message = ChatMessage(
      id: now.millisecondsSinceEpoch.toString(),
      type: ChatMessageType.location,
      text: 'Моё местоположение',
      isMe: true,
      timestamp: now,
      isRead: true,
    );
    await store.addMessage(widget.chatId, message);
    _scrollToBottom();
  }

  void _showPollDialog() {
    final questionController = TextEditingController();
    final optionControllers = [TextEditingController(), TextEditingController()];

    _showAnimatedDialog(
      context: context,
      builder: (context) {
        return GlassContainer(
          padding: const EdgeInsets.all(24),
          decoration: Theme.of(context).extension<GlassTheme>()!.baseGlass.copyWith(
                color: Theme.of(context).primaryColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(20),
              ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Создать опрос', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: questionController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Вопрос',
                        hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.08),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    ...optionControllers.map((controller) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: TextField(
                            controller: controller,
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              hintText: 'Вариант ответа',
                              hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                              filled: true,
                              fillColor: Colors.white.withOpacity(0.08),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
                              ),
                            ),
                          ),
                        )),
                  ],
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
                    onPressed: () async {
                      final question = questionController.text.trim();
                      final options = optionControllers.map((c) => c.text.trim()).where((s) => s.isNotEmpty).join('\n');
                      if (question.isNotEmpty && options.isNotEmpty) {
                        Navigator.of(context).pop();
                        await _addPollMessage(question, options);
                      }
                    },
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Text('Создать'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _showAnimatedDialog({required BuildContext context, required WidgetBuilder builder}) {
    setState(() => _isDialogOpen = true);
    return showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.5),
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(24),
          child: builder(context),
        )
            .animate()
            .fadeIn(duration: 300.ms, curve: Curves.easeOutCubic)
            .scale(begin: const Offset(0.9, 0.9), duration: 300.ms, curve: Curves.easeOutCubic);
      },
    ).then((_) => setState(() => _isDialogOpen = false));
  }

  Future<void> _addPollMessage(String question, String options) async {
    final store = context.read<ChatStore>();
    final now = DateTime.now();
    final message = ChatMessage(
      id: now.millisecondsSinceEpoch.toString(),
      type: ChatMessageType.poll,
      text: '$question\n$options',
      isMe: true,
      timestamp: now,
      isRead: true,
    );
    await store.addMessage(widget.chatId, message);
    _scrollToBottom();
  }

  void _showStickerPicker() {
    final stickers = ['🎭', '😎', '🔥', '💯', '🎉', '❤️', '👍', '👎', '😂', '😢', '😮', '🤔'];
    _showAnimatedDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.black87,
        title: const Text('Выберите стикер'),
        content: Wrap(
          spacing: 16,
          runSpacing: 16,
          children: stickers.map((sticker) {
            return GestureDetector(
              onTap: () async {
                Navigator.of(context).pop();
                await _addStickerMessage(sticker);
              },
              child: Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(sticker, style: const TextStyle(fontSize: 32)),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Future<void> _addStickerMessage(String sticker) async {
    final store = context.read<ChatStore>();
    final now = DateTime.now();
    final message = ChatMessage(
      id: now.millisecondsSinceEpoch.toString(),
      type: ChatMessageType.sticker,
      text: sticker,
      isMe: true,
      timestamp: now,
      isRead: true,
    );
    await store.addMessage(widget.chatId, message);
    _scrollToBottom();
  }

  void _showCaptionDialog(String path, {required bool isImage, String? fileName}) {
    final captionController = TextEditingController();
    _showAnimatedDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.black87,
        title: Text(isImage ? 'Добавить подпись к фото' : 'Добавить подпись к файлу'),
        content: TextField(
          controller: captionController,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: isImage ? 'Подпись (необязательно)' : 'Подпись (необязательно)',
            hintStyle: const TextStyle(color: Colors.white54),
            suffixIcon: IconButton(
              icon: const Icon(PhosphorIconsBold.x, size: 18),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
          maxLines: 3,
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () {
              final caption = captionController.text.trim();
              Navigator.of(context).pop();
              if (isImage) {
                _addImageMessage(path, caption: caption.isEmpty ? null : caption);
              } else {
                _addFileMessage(path, fileName ?? 'Файл', caption: caption.isEmpty ? fileName : caption);
              }
            },
            child: const Text('Отправить'),
          ),
        ],
      ),
    );
  }

  Future<void> _editMessage(String messageId, String newText) async {
    await context.read<ChatStore>().editMessage(widget.chatId, messageId, newText);
      }

  Future<void> _deleteMessage(String messageId) async {
    await context.read<ChatStore>().deleteMessage(widget.chatId, messageId);
  }

  Future<void> _addReaction(String messageId, String emoji) async {
    await context.read<ChatStore>().addReaction(widget.chatId, messageId, emoji);
    if (SettingsService.getHapticFeedback()) {
      HapticFeedback.selectionClick();
    }
  }

  void _replyToMessage(ChatMessage message) {
    // Set reply context for message input
    setState(() {
      _replyToMessageId = message.id;
      _replyToMessageText = message.text ?? '';
    });
    // Scroll to input field
    _scrollToBottom();
    if (SettingsService.getHapticFeedback()) {
      HapticFeedback.lightImpact();
    }
  }

  void _forwardMessage(ChatMessage message) {
    final parentContext = context;
    _showAnimatedBottomSheet(
      context: context,
      builder: (dialogContext) {
        final chatStore = dialogContext.read<ChatStore>();
        final threads = chatStore.threads.where((t) => t.id != widget.chatId).toList();
        return GlassContainer(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    const Text('Переслать сообщение', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(PhosphorIconsBold.x),
                      onPressed: () => Navigator.of(dialogContext).pop(),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Flexible(
                child: threads.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.all(32.0),
                        child: Text('Нет других чатов для пересылки',
                            style: TextStyle(color: Colors.white.withOpacity(0.6))),
                      )
                    : ListView.builder(
                        shrinkWrap: true,
                        itemCount: threads.length,
                        itemBuilder: (context, index) {
                          final thread = threads[index];
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundImage: thread.avatarAsset.startsWith('assets/')
                                  ? AssetImage(thread.avatarAsset)
                                  : FileImage(File(thread.avatarAsset)) as ImageProvider,
                            ),
                            title: Text(thread.title),
                            subtitle: thread.isGroup ? const Text('Группа') : null,
                            onTap: () async {
                              await chatStore.forwardMessage(widget.chatId, message.id, thread.id);
                              Navigator.of(dialogContext).pop();
                              if (parentContext.mounted) {
                                ScaffoldMessenger.of(parentContext).showSnackBar(
                                  SnackBar(content: Text('Сообщение переслано в ${thread.title}')),
                                );
                              }
                            },
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<T?> _showAnimatedBottomSheet<T>({required BuildContext context, required WidgetBuilder builder}) {
    setState(() => _isDialogOpen = true);
    return showModalBottomSheet<T>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(12.0),
          child: builder(context)
              .animate()
              .fadeIn(duration: 400.ms, curve: Curves.easeOutCubic)
              .slideY(begin: 0.1, end: 0, duration: 400.ms, curve: Curves.easeOutCubic),
        );
      },
    ).then((value) {
      setState(() => _isDialogOpen = false);
      return value;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ChatStore>(
      builder: (context, chatStore, _) {
        final chat = chatStore.threadById(widget.chatId);
        if (chat == null) {
          return Scaffold(
            appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
            body: const Center(child: Text('Чат не найден')),
          );
        }
        final messages = chat.messages;
        List<ChatMessage> reversedMessages = messages.reversed.toList();

        if (_isChatSearchActive && _chatSearchController.text.isNotEmpty) {
          final query = _chatSearchController.text.toLowerCase();
          reversedMessages = reversedMessages.where((m) {
            return m.text?.toLowerCase().contains(query) ?? false;
          }).toList();
        }

        final totalItems = reversedMessages.length + (_isTyping ? 1 : 0);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: GlassIconButton(
          icon: PhosphorIconsBold.caretLeft,
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: _isChatSearchActive
            ? TextField(
                controller: _chatSearchController,
                autofocus: true,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Поиск в этом чате...',
                  border: InputBorder.none,
                  hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                ),
                onChanged: (value) => setState(() {}),
              )
            : GestureDetector(
          onTap: () {
                Navigator.of(context).pushNamed(
                  AppRoutes.profile,
                  arguments: {'userName': chat.title, 'avatarAsset': chat.avatarAsset},
                );
          },
          child: Column(
                mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  Hero(
                    tag: 'avatar-${chat.id}',
                    child: ClipOval(
                      child: SizedBox(
                        width: 44,
                        height: 44,
                        child: Image(
                          image: _avatarProvider(chat.avatarAsset),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                  // Убрано свечение от аватарки
                ],
              ),
              const SizedBox(height: 6),
                  Text(chat.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        margin: const EdgeInsets.only(right: 4),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.green,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.green.withOpacity(0.5),
                              blurRadius: 4,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                      ),
                      Text('в сети', style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.7))),
                    ],
                  ),
            ],
          ),
        ),
        centerTitle: true,
        actions: _isChatSearchActive
            ? [
                GlassIconButton(
                  icon: Icons.close,
                  onPressed: () => setState(() {
                    _isChatSearchActive = false;
                    _chatSearchController.clear();
                  }),
                )
              ]
            : [
                Builder(
                  builder: (buttonContext) => GlassIconButton(
                    icon: PhosphorIconsBold.dotsThreeVertical,
                    onPressed: () {
                      _showCustomMenu(buttonContext, chatStore, chat);
                    },
                  ),
                )
              ],
        flexibleSpace: ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
            child: Container(color: Colors.transparent),
          ),
        ),
      ),
      body: Stack(
        children: [
          Consumer<ThemeProvider>(
            builder: (context, themeProvider, child) {
              return Container(
                decoration: BoxDecoration(
                  image: DecorationImage(
                        image: AssetImage(themeProvider.backgroundImage ?? 'assets/images/background_pattern.png'),
                    fit: BoxFit.cover,
                  ),
                ),
              );
            },
          ),
          Column(
            children: [
              Expanded(
                child: ListView.builder(
                      controller: _scrollController,
                  reverse: true,
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.only(top: 96, bottom: 72),
                      itemCount: totalItems,
                  itemBuilder: (context, index) {
                    if (_isTyping && index == 0) {
                      return _TypingIndicator();
                    }
                    final messageIndex = _isTyping ? index - 1 : index;
                    final message = reversedMessages[messageIndex];
                    
                    // Показываем дату перед первым сообщением или при смене дня
                    final showDate = messageIndex == reversedMessages.length - 1 || 
                        (messageIndex < reversedMessages.length - 1 && 
                         reversedMessages[messageIndex + 1].timestamp.day != message.timestamp.day);
                    
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (showDate) _buildDateHeader(message.timestamp),
                        GestureDetector(
                      onDoubleTap: SettingsService.getDoubleTapToLike()
                          ? () {
                              _addReaction(message.id, '❤️');
                              if (SettingsService.getHapticFeedback()) {
                                HapticFeedback.mediumImpact();
                              }
                            }
                          : null,
                      child: Dismissible(
                        key: Key(message.id),
                        direction: SettingsService.getSwipeToReply()
                            ? (message.isMe
                                ? DismissDirection.startToEnd
                                : DismissDirection.endToStart)
                            : DismissDirection.none,
                        background: Container(
                          alignment: message.isMe
                              ? Alignment.centerLeft
                              : Alignment.centerRight,
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Icon(
                            PhosphorIconsBold.arrowBendUpLeft,
                            color: Theme.of(context).primaryColor,
                            size: 24,
                          ),
                        ),
                        onDismissed: (direction) {
                          // Не удаляем сообщение, только отвечаем
                          if (SettingsService.getSwipeToReply()) {
                            _replyToMessage(message);
                          }
                        },
                        confirmDismiss: (direction) async {
                          // Предотвращаем удаление, только отвечаем
                          if (SettingsService.getSwipeToReply()) {
                            _replyToMessage(message);
                            return false; // Не удаляем сообщение
                          }
                          return false;
                        },
                        child: LongPressDraggable<ChatMessage>(
                          data: message,
                          feedback: Material(
                            color: Colors.transparent,
                            child: Transform.scale(
                              scale: 1.03,
                              child: Opacity(
                                opacity: 0.92,
                                child: _MessageBubble(
                                  message: message,
                                  onEdit: _editMessage,
                                  onDelete: _deleteMessage,
                                  onReaction: _addReaction,
                                  onForward: _forwardMessage,
                                ),
                              ),
                            ),
                          ),
                          child: _MessageBubble(
                            message: message,
                            onEdit: _editMessage,
                            onDelete: _deleteMessage,
                            onReaction: _addReaction,
                            onForward: _forwardMessage,
                          ),
                        ),
                      ),
                    )
                        .animate(delay: (30 * messageIndex).ms)
                        .fadeIn(duration: 400.ms, curve: Curves.easeOutCubic)
                        .slideY(begin: 0.1, end: 0, curve: Curves.easeOutCubic),
                      ],
                    );
                  },
                ),
              ),
              AnimatedSlide(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                // Исправлен баг: панель не скрывается при открытии настроек через Navigator
                offset: (_isDialogOpen && ModalRoute.of(context)?.isCurrent == true) ? const Offset(0, 1) : Offset.zero,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Эмодзи панель
                    AnimatedSize(
                      duration: const Duration(milliseconds: 280),
                      curve: Curves.easeInOutCubic,
                      child: _isEmojiPanelVisible ? _buildEmojiPanel() : const SizedBox.shrink(),
                    ),
                    AnimateOnDisplay(
                      delayMs: 50,
                      child: DragTarget<ChatMessage>(
                        builder: (context, candidate, rejected) => _MessageInputField(
                          onSendText: _addTextMessage,
                          onTypingChanged: (typing) => setState(() => _isTyping = typing),
                          onPickImage: () {
                            _showImagePicker(ImageSource.gallery);
                          },
                          onToggleRecord: _onToggleRecord,
                          replyToMessageId: _replyToMessageId,
                          replyToMessageText: _replyToMessageText,
                          onCancelReply: () {
                            setState(() {
                              _replyToMessageId = null;
                              _replyToMessageText = null;
                            });
                          },
                        ),
                        onAccept: (message) {
                          _replyToMessage(message);
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
        },
    );
  }

  void _showCustomMenu(BuildContext context, ChatStore chatStore, ChatThread chat) {
    setState(() => _isDialogOpen = true);
    
    // Получаем позицию кнопки
    final RenderBox? buttonBox = context.findRenderObject() as RenderBox?;
    if (buttonBox == null || !buttonBox.attached) return;
    
    final RenderBox overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
    final buttonPosition = buttonBox.localToGlobal(Offset.zero, ancestor: overlay);
    final buttonSize = buttonBox.size;
    
    // Позиционируем меню под кнопкой, выравнивая по правому краю
    final screenWidth = overlay.size.width;
    final menuWidth = 200.0; // Примерная ширина меню
    
    final position = RelativeRect.fromLTRB(
      screenWidth - menuWidth - 16, // Справа с отступом
      buttonPosition.dy + buttonSize.height + 8, // Под кнопкой с небольшим отступом
      menuWidth + 16,
      overlay.size.height - buttonPosition.dy - buttonSize.height - 8,
    );

    showMenu<String>(
      context: context,
      position: position,
      color: const Color(0xFF2C1A3E),
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      items: [
        _buildMenuItem('call', 'Звонок', PhosphorIconsBold.phone),
        _buildMenuItem('video', 'Видеозвонок', PhosphorIconsBold.videoCamera),
        const PopupMenuDivider(),
        _buildMenuItem('search', 'Поиск в чате', PhosphorIconsBold.magnifyingGlass),
        _buildMenuItem('media', 'Медиафайлы', PhosphorIconsBold.images),
        _buildMenuItem('files', 'Файлы', PhosphorIconsBold.file),
        const PopupMenuDivider(),
        _buildMenuItem('mute', 'Отключить уведомления', PhosphorIconsBold.bellSlash),
        _buildMenuItem('pin', 'Закрепить чат', PhosphorIconsBold.pushPin),
        _buildMenuItem('clear', 'Очистить историю', PhosphorIconsBold.trash, isDestructive: true),
      ],
    ).then((value) {
      setState(() => _isDialogOpen = false);
      if (value == null) return;
      _handleMenuSelection(value, chatStore, chat);
    });
  }

  PopupMenuItem<String> _buildMenuItem(String value, String text, IconData icon, {bool isDestructive = false}) {
    return PopupMenuItem<String>(
      value: value,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            Icon(icon, size: 18, color: isDestructive ? Colors.redAccent : Theme.of(context).primaryColor),
            const SizedBox(width: 12),
            Expanded(
              child: Text(text, style: TextStyle(color: isDestructive ? Colors.redAccent : Colors.white.withOpacity(0.9))),
            ),
          ],
        ),
      ),
    );
  }

  void _handleMenuSelection(String value, ChatStore chatStore, ChatThread chat) async {
    switch (value) {
      case 'call':
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CallScreen(
              userName: chat.title,
              avatarAsset: chat.avatarAsset,
              isIncoming: false,
              isVideoCall: false,
            ),
            fullscreenDialog: true,
          ),
        );
        if (result == true) {
          await _addCallMessage(false, false);
        }
        break;
      case 'video':
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CallScreen(
              userName: chat.title,
              avatarAsset: chat.avatarAsset,
              isIncoming: false,
              isVideoCall: true,
            ),
            fullscreenDialog: true,
          ),
        );
        if (result == true) {
          await _addCallMessage(false, true);
        }
        break;
      case 'search':
        _showSearchInChat(context);
        break;
      case 'media':
        _showMediaFiles(context);
        break;
      case 'files':
        _showFiles(context);
        break;
      case 'mute':
        final isMuted = SettingsService.isChatMuted(widget.chatId);
        await SettingsService.setChatMuted(widget.chatId, !isMuted);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(!isMuted ? 'Уведомления отключены' : 'Уведомления включены')),
        );
        break;
      case 'pin':
        final isPinned = SettingsService.isChatPinned(widget.chatId);
        await SettingsService.setChatPinned(widget.chatId, !isPinned);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(!isPinned ? 'Чат закреплен' : 'Чат откреплен')),
        );
        chatStore.notifyListeners();
        break;
      case 'clear':
        _showAnimatedDialog(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: Colors.black87,
            title: const Text('Очистить историю'),
            content: const Text('Вы уверены, что хотите удалить всю историю переписки?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Отмена'),
              ),
              TextButton(
                onPressed: () async {
                  await chatStore.clearChatHistory(widget.chatId);
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('История очищена')),
                  );
                },
                child: const Text('Очистить', style: TextStyle(color: Colors.redAccent)),
              ),
            ],
          ),
        );
        break;
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 240),
        curve: Curves.easeOutCubic,
      );
    });
  }

  String _formatTimestamp(DateTime time) {
    final hours = time.hour.toString().padLeft(2, '0');
    final minutes = time.minute.toString().padLeft(2, '0');
    return '$hours:$minutes';
  }

  String _formatDate(DateTime date) {
    final months = ['января', 'февраля', 'марта', 'апреля', 'мая', 'июня', 
                    'июля', 'августа', 'сентября', 'октября', 'ноября', 'декабря'];
    return '${date.day} ${months[date.month - 1]}';
  }

  Widget _buildDateHeader(DateTime date) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            _formatDate(date),
            style: TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmojiPanel() {
    final inputState = context.findAncestorStateOfType<_MessageInputFieldState>();
    final emojiCategories = {
      'Часто используемые': ['😀', '😂', '❤️', '😍', '🤔', '👍', '👎', '🙏', '🔥', '💯', '🎉', '😢'],
      'Эмоции': ['😀', '😃', '😄', '😁', '😆', '😅', '🤣', '😂', '🙂', '🙃', '😉', '😊', '😇', '🥰', '😍', '🤩', '😘', '😗', '😚', '😙', '😋', '😛', '😜', '🤪', '😝', '🤑', '🤗', '🤭', '🤫', '🤔'],
      'Жесты': ['👋', '🤚', '🖐', '✋', '🖖', '👌', '🤏', '✌️', '🤞', '🤟', '🤘', '🤙', '👈', '👉', '👆', '🖕', '👇', '☝️', '👍', '👎', '✊', '👊', '🤛', '🤜', '👏', '🙌', '👐', '🤲', '🤝', '🙏'],
      'Предметы': ['📱', '💻', '⌚', '📷', '📹', '🎥', '📺', '📻', '🎙', '🎚', '🎛', '⏱', '⏲', '⏰', '🕰', '⌛', '⏳', '📡', '🔋', '🔌', '💡', '🔦', '🕯', '🪔', '🧯', '🛢', '💸', '💵', '💴', '💶'],
      'Еда': ['🍎', '🍊', '🍋', '🍌', '🍉', '🍇', '🍓', '🍈', '🍒', '🍑', '🥭', '🍍', '🥥', '🥝', '🍅', '🍆', '🥑', '🥦', '🥬', '🥒', '🌶', '🌽', '🥕', '🥔', '🍠', '🥐', '🥯', '🍞', '🥖', '🥨'],
    };

    return Container(
      height: 250,
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        children: [
          // Категории эмодзи
          Container(
            height: 40,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: emojiCategories.length,
              itemBuilder: (context, index) {
                final category = emojiCategories.keys.elementAt(index);
                final isSelected = inputState?._selectedEmojiCategory == category;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: GlassButton(
                    onPressed: () {
                      inputState?.setState(() {
                        inputState._selectedEmojiCategory = category;
                      });
                    },
                    minWidth: 60,
                    minHeight: 32,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    child: Text(
                      category,
                      style: TextStyle(
                        fontSize: 12, 
                        color: isSelected 
                          ? Colors.white 
                          : Colors.white.withOpacity(0.8),
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const Divider(height: 1, color: Colors.white12),
          // Эмодзи
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(8),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 8,
                mainAxisSpacing: 4,
                crossAxisSpacing: 4,
              ),
              itemCount: inputState != null 
                ? (emojiCategories[inputState._selectedEmojiCategory]?.length ?? 0)
                : emojiCategories.values.expand((x) => x).length,
              itemBuilder: (context, index) {
                final emojis = inputState != null
                  ? (emojiCategories[inputState._selectedEmojiCategory] ?? [])
                  : emojiCategories.values.expand((x) => x).toList();
                if (index >= emojis.length) return const SizedBox();
                final emoji = emojis[index];
                return GlassButton(
                  onPressed: () {
                    final chatScreenState = context.findAncestorStateOfType<_ChatScreenState>();
                    final inputState = context.findAncestorStateOfType<_MessageInputFieldState>();
                    if (inputState != null) {
                      inputState._controller.text += emoji;
                    }
                  },
                  minWidth: 40,
                  minHeight: 40,
                  padding: EdgeInsets.zero,
                  child: Center(
                    child: Text(emoji, style: const TextStyle(fontSize: 24)),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    ).animate()
      .slideY(begin: 0.3, end: 0, duration: const Duration(milliseconds: 280), curve: Curves.easeOutCubic)
      .fadeIn(duration: const Duration(milliseconds: 250));
  }

  void _showSearchInChat(BuildContext context) {
    setState(() => _isDialogOpen = true);
    final searchController = TextEditingController();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: const EdgeInsets.all(12.0),
          child: GlassContainer(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      const Text('Поиск в чате', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(PhosphorIconsBold.x),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: TextField(
                    controller: searchController,
                    autofocus: true,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Введите текст для поиска...',
                      hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                      prefixIcon: Icon(PhosphorIconsBold.magnifyingGlass, color: Colors.white.withOpacity(0.7)),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.white.withOpacity(0.2)),
                      ),
                    ),
                    onChanged: (query) {
                      setModalState(() {});
                    },
                  ),
                ),
                const SizedBox(height: 16),
                Flexible(
                  child: Builder(
                    builder: (context) {
                      if (searchController.text.isEmpty) {
                        return Padding(
                          padding: const EdgeInsets.all(32.0),
                          child: Text('Введите текст для поиска', 
                              style: TextStyle(color: Colors.white.withOpacity(0.6))),
                        );
                      }
                      final results = context.read<ChatStore>().searchInChat(widget.chatId, searchController.text);
                      if (results.isEmpty) {
                        return Padding(
                          padding: const EdgeInsets.all(32.0),
                          child: Text('Ничего не найдено', 
                              style: TextStyle(color: Colors.white.withOpacity(0.6))),
                        );
                      }
                      return ListView.builder(
                        shrinkWrap: true,
                        itemCount: results.length,
                        itemBuilder: (context, index) {
                          final message = results[index];
                          return ListTile(
                            leading: Icon(
                              message.type == ChatMessageType.text 
                                  ? PhosphorIconsBold.chatCircle 
                                  : PhosphorIconsBold.image,
                              color: Theme.of(context).primaryColor,
                            ),
                            title: Text(message.text ?? '', 
                                style: const TextStyle(fontSize: 14)),
                            subtitle: Text(_formatTimestamp(message.timestamp),
                                style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12)),
                            onTap: () {
                              Navigator.of(context).pop();
                            },
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ).then((_) => setState(() => _isDialogOpen = false));
  }

  void _showMediaFiles(BuildContext context) {
    setState(() => _isDialogOpen = true);
    final mediaMessages = context.read<ChatStore>().getMediaMessages(widget.chatId);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: const EdgeInsets.all(12.0),
        child: GlassContainer(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    const Text('Медиафайлы', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const Spacer(),
                    Text('${mediaMessages.length}', 
                        style: TextStyle(color: Colors.white.withOpacity(0.6))),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(PhosphorIconsBold.x),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Flexible(
                child: mediaMessages.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.all(32.0),
                        child: Text('Нет медиафайлов', 
                            style: TextStyle(color: Colors.white.withOpacity(0.6))),
                      )
                    : GridView.builder(
                        shrinkWrap: true,
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: 4,
                          mainAxisSpacing: 4,
                        ),
                        itemCount: mediaMessages.length,
                        itemBuilder: (context, index) {
                          final message = mediaMessages[index];
                          if (message.type == ChatMessageType.image && message.mediaPath != null) {
                            return GestureDetector(
                              onTap: () {
                                showDialog(
                                  context: context,
                                  builder: (_) => Dialog(
                                    insetPadding: const EdgeInsets.all(8),
                                    backgroundColor: Colors.transparent,
                                    child: InteractiveViewer(
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(16),
                                        child: message.mediaPath!.startsWith('assets/')
                                            ? Image.asset(message.mediaPath!, fit: BoxFit.contain)
                                            : Image.file(File(message.mediaPath!), fit: BoxFit.contain),
                                      ),
                                    ),
                                  ),
                                );
                              },
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: message.mediaPath!.startsWith('assets/')
                                    ? Image.asset(message.mediaPath!, fit: BoxFit.cover)
                                    : Image.file(File(message.mediaPath!), fit: BoxFit.cover),
                              ),
                            );
                          }
                          return Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Center(
                              child: Icon(
                                message.type == ChatMessageType.voice 
                                    ? PhosphorIconsBold.microphone 
                                    : PhosphorIconsBold.sticker,
                                color: Colors.white.withOpacity(0.5),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    ).then((_) => setState(() => _isDialogOpen = false));
  }

  void _showFiles(BuildContext context) {
    setState(() => _isDialogOpen = true);
    final fileMessages = context.read<ChatStore>().getFileMessages(widget.chatId);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: const EdgeInsets.all(12.0),
        child: GlassContainer(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    const Text('Файлы', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const Spacer(),
                    Text('${fileMessages.length}', 
                        style: TextStyle(color: Colors.white.withOpacity(0.6))),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(PhosphorIconsBold.x),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Flexible(
                child: fileMessages.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.all(32.0),
                        child: Text('Нет файлов', 
                            style: TextStyle(color: Colors.white.withOpacity(0.6))),
                      )
                    : ListView.builder(
                        shrinkWrap: true,
                        itemCount: fileMessages.length,
                        itemBuilder: (context, index) {
                          final message = fileMessages[index];
                          return ListTile(
                            leading: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Theme.of(context).primaryColor.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(PhosphorIconsBold.file, 
                                  color: Theme.of(context).primaryColor, size: 20),
                            ),
                            title: Text(message.text ?? 'Файл', 
                                style: const TextStyle(fontWeight: FontWeight.w600)),
                            subtitle: Text(_formatTimestamp(message.timestamp),
                                style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12)),
                            trailing: IconButton(
                              icon: Icon(PhosphorIconsBold.download, 
                                  color: Colors.white.withOpacity(0.7)),
                              onPressed: () {
                                if (message.mediaPath != null) {
                                  final file = File(message.mediaPath!);
                                  if (file.existsSync()) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Открыть файл: ${message.text}')),
                                    );
                                  }
                                }
                              },
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    ).then((_) => setState(() => _isDialogOpen = false));
  }

  ImageProvider _avatarProvider(String path) {
    if (path.startsWith('assets/')) {
      return AssetImage(path);
    }
    final file = File(path);
    if (file.existsSync()) {
      return FileImage(file);
    }
    return const AssetImage('assets/images/avatar_placeholder.png');
  }

  Future<void> _showImagePicker(ImageSource source) async {
    final XFile? pickedFile = await _picker.pickImage(source: source);
    if (pickedFile != null) {
      _showCaptionDialog(pickedFile.path, isImage: true);
    }
  }

  void _showAttachmentMenu(BuildContext context) {
    showGlassBottomSheet(
      context: context,
      initialChildSize: 0.4,
      minChildSize: 0.3,
      maxChildSize: 0.6,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Icon(PhosphorIconsBold.paperclip, color: Theme.of(context).primaryColor, size: 24),
                const SizedBox(width: 12),
                const Text('Отправить', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const Spacer(),
                IconButton(
                  icon: const Icon(PhosphorIconsBold.x),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: GridView.count(
              crossAxisCount: 3,
              padding: const EdgeInsets.all(16),
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              children: [
                _buildAttachmentOption(
                  context,
                  icon: PhosphorIconsBold.image,
                  label: 'Фото',
                  onTap: () {
                    Navigator.of(context).pop();
                    _showImagePicker(ImageSource.gallery);
                  },
                ),
                _buildAttachmentOption(
                  context,
                  icon: PhosphorIconsBold.camera,
                  label: 'Камера',
                  onTap: () {
                    Navigator.of(context).pop();
                    _showImagePicker(ImageSource.camera);
                  },
                ),
                _buildAttachmentOption(
                  context,
                  icon: PhosphorIconsBold.file,
                  label: 'Файл',
                  onTap: () async {
                    Navigator.of(context).pop();
                    final result = await FilePicker.platform.pickFiles();
                    if (result != null && result.files.single.path != null) {
                      _showCaptionDialog(result.files.single.path!, isImage: false, fileName: result.files.single.name);
                    }
                  },
                ),
                _buildAttachmentOption(
                  context,
                  icon: PhosphorIconsBold.videoCamera,
                  label: 'Видео',
                  onTap: () async {
                    Navigator.of(context).pop();
                    final XFile? video = await _picker.pickVideo(source: ImageSource.gallery);
                    if (video != null) {
                      _showCaptionDialog(video.path, isImage: false, fileName: 'Видео');
                    }
                  },
                ),
                _buildAttachmentOption(
                  context,
                  icon: PhosphorIconsBold.mapPin,
                  label: 'Местоположение',
                  onTap: () {
                    Navigator.of(context).pop();
                    _addLocationMessage();
                  },
                ),
                _buildAttachmentOption(
                  context,
                  icon: PhosphorIconsBold.chartBar,
                  label: 'Опрос',
                  onTap: () {
                    Navigator.of(context).pop();
                    _showPollDialog();
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttachmentOption(BuildContext context, {required IconData icon, required String label, required VoidCallback onTap}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: GlassContainer(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Theme.of(context).primaryColor, size: 32),
              const SizedBox(height: 8),
              Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
            ],
          ),
        ),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final ChatMessage message;
  final Function(String, String)? onEdit;
  final Function(String)? onDelete;
  final Function(String, String)? onReaction;
  final Function(ChatMessage)? onForward;
  const _MessageBubble({
    required this.message,
    this.onEdit,
    this.onDelete,
    this.onReaction,
    this.onForward,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final alignment = message.isMe ? Alignment.centerRight : Alignment.centerLeft;
    
    // Telegram iOS style colors with Liquid Glass effect
    final userBubbleColor = theme.primaryColor; // Dark purple for gradient
    final interlocutorBubbleColor = Colors.white; // White for gradient (will be made transparent)

    return Align(
      alignment: alignment,
      child: GestureDetector(
        onLongPress: () => _showMessageMenu(context),
          child: Container(
          constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.72),
          margin: EdgeInsets.only(
            left: message.isMe ? 48 : 10,
            right: message.isMe ? 10 : 48,
            top: 1.5,
            bottom: 1.5,
          ),
          child: message.isMe
              ? _buildUserBubble(context, userBubbleColor, theme)
              : _buildInterlocutorBubble(context, interlocutorBubbleColor, theme),
        ),
      ),
    );
  }

  Widget _buildUserBubble(BuildContext context, Color color, ThemeData theme) {
    // Фиолетовый градиент как на скриншоте
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF8B5CF6), // Фиолетовый
            Color(0xFF7C3AED), // Более темный фиолетовый
            Color(0xFF6D28D9), // Еще темнее
          ],
        ),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(14),
          topRight: Radius.circular(14),
          bottomLeft: Radius.circular(14),
          bottomRight: Radius.circular(4),
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0xFF8B5CF6).withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildMessageContent(context, message),
          if (message.reactions.isNotEmpty) ...[
            const SizedBox(height: 6),
            _buildReactions(context),
          ],
          const SizedBox(height: 4),
          Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (message.isEdited)
                Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: Text(
                    'изменено',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.white.withOpacity(0.8),
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              if (SettingsService.getShowTimestamps())
                Text(
                  _formatTimestamp(message.timestamp),
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.white.withOpacity(0.9),
                    fontWeight: FontWeight.w400,
                  ),
                ),
              if (SettingsService.getShowTimestamps() && SettingsService.getShowReadReceipts())
                const SizedBox(width: 4),
              if (SettingsService.getShowReadReceipts())
                Icon(
                  message.isRead ? Icons.done_all : Icons.done,
                  size: 14,
                  color: message.isRead ? Colors.white : Colors.white.withOpacity(0.7),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInterlocutorBubble(BuildContext context, Color color, ThemeData theme) {
    final baseColor = const Color(0xFF2C1A3E).withOpacity(0.09);
    final lighterColor = Color.fromRGBO(
      ((baseColor.red * 255) + (255 - baseColor.red * 255) * 0.01).round().clamp(0, 255),
      ((baseColor.green * 255) + (255 - baseColor.green * 255) * 0.01).round().clamp(0, 255),
      ((baseColor.blue * 255) + (255 - baseColor.blue * 255) * 0.01).round().clamp(0, 255),
      0.09, // Прозрачность 9%
    );
    return ClipRRect(
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(4),
        topRight: Radius.circular(14),
        bottomLeft: Radius.circular(14),
        bottomRight: Radius.circular(14),
      ),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: Container(
          decoration: BoxDecoration(
            color: lighterColor,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(4),
              topRight: Radius.circular(14),
              bottomLeft: Radius.circular(14),
              bottomRight: Radius.circular(14),
            ),
            border: Border.all(
              color: Colors.white.withOpacity(0.08),
              width: 0.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildMessageContent(context, message),
              if (message.reactions.isNotEmpty) ...[
                const SizedBox(height: 6),
                _buildReactions(context),
              ],
              const SizedBox(height: 4),
              Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  if (message.isEdited)
                    Padding(
                      padding: const EdgeInsets.only(right: 4),
                      child: Text(
                        'изменено',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.white.withOpacity(0.6),
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  if (SettingsService.getShowTimestamps())
                    Text(
                      _formatTimestamp(message.timestamp),
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.white.withOpacity(0.65),
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReactions(BuildContext context) {
    return Wrap(
      spacing: 6,
      runSpacing: 4,
      children: message.reactions.entries.map((entry) {
        return GestureDetector(
          onTap: () => onReaction?.call(message.id, entry.key),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Theme.of(context).primaryColor.withOpacity(0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(entry.key, style: const TextStyle(fontSize: 14)),
                const SizedBox(width: 4),
                Text('${entry.value}', style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.8))),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  void _showMessageMenu(BuildContext context) {
    final chatScreenState = context.findAncestorStateOfType<_ChatScreenState>();
    chatScreenState?.setState(() => chatScreenState._isDialogOpen = true);
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: const EdgeInsets.all(12.0),
        child: GlassContainer(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (message.type == ChatMessageType.text)
                ListTile(
                  leading: Icon(PhosphorIconsBold.copy, color: Theme.of(context).primaryColor),
                  title: const Text('Копировать'),
                  onTap: () {
                    if (message.text != null) {
                      Clipboard.setData(ClipboardData(text: message.text!));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Скопировано в буфер обмена')),
                      );
                    }
                    Navigator.of(context).pop();
                    chatScreenState?.setState(() => chatScreenState._isDialogOpen = false);
                  },
                ),
              if (message.type == ChatMessageType.text && message.isMe)
                ListTile(
                  leading: Icon(PhosphorIconsBold.pencilSimple, color: Theme.of(context).primaryColor),
                  title: const Text('Редактировать'),
                  onTap: () {
                    Navigator.of(context).pop();
                    chatScreenState?.setState(() => chatScreenState._isDialogOpen = false);
                    _showEditDialog(context);
                  },
                ),
              ListTile(
                leading: Icon(PhosphorIconsBold.arrowSquareOut, color: Theme.of(context).primaryColor),
                title: const Text('Переслать'),
                onTap: () {
                  Navigator.of(context).pop();
                  chatScreenState?.setState(() => chatScreenState._isDialogOpen = false);
                  onForward?.call(message);
                },
              ),
              ListTile(
                leading: Icon(PhosphorIconsBold.smiley, color: Theme.of(context).primaryColor),
                title: const Text('Добавить реакцию'),
                onTap: () {
                  Navigator.of(context).pop();
                  chatScreenState?.setState(() => chatScreenState._isDialogOpen = false);
                  _showReactionPicker(context);
                },
              ),
              if (message.type == ChatMessageType.text)
                ListTile(
                  leading: Icon(PhosphorIconsBold.arrowBendUpLeft, color: Theme.of(context).primaryColor),
                  title: const Text('Ответить'),
                  onTap: () {
                    Navigator.of(context).pop();
                    chatScreenState?.setState(() => chatScreenState._isDialogOpen = false);
                    // TODO: Implement reply functionality
                  },
                ),
              if (message.isMe) ...[
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(PhosphorIconsBold.trash, color: Colors.redAccent),
                  title: const Text('Удалить', style: TextStyle(color: Colors.redAccent)),
                  onTap: () {
                    Navigator.of(context).pop();
                    chatScreenState?.setState(() => chatScreenState._isDialogOpen = false);
                    onDelete?.call(message.id);
                  },
                ),
              ],
            ],
          ),
        ),
      ),
    ).then((_) {
      chatScreenState?.setState(() => chatScreenState._isDialogOpen = false);
    });
  }

  void _showEditDialog(BuildContext context) {
    final chatScreenState = context.findAncestorStateOfType<_ChatScreenState>();
    chatScreenState?.setState(() => chatScreenState._isDialogOpen = true);
    
    final controller = TextEditingController(text: message.text);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.black87,
        title: const Text('Редактировать сообщение'),
        content: TextField(
          controller: controller,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: 'Введите новый текст',
            hintStyle: TextStyle(color: Colors.white54),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              chatScreenState?.setState(() => chatScreenState._isDialogOpen = false);
            },
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () {
              onEdit?.call(message.id, controller.text);
              Navigator.of(context).pop();
              chatScreenState?.setState(() => chatScreenState._isDialogOpen = false);
            },
            child: const Text('Сохранить'),
          ),
        ],
      ),
    ).then((_) {
      chatScreenState?.setState(() => chatScreenState._isDialogOpen = false);
    });
  }

  void _showReactionPicker(BuildContext context) {
    final chatScreenState = context.findAncestorStateOfType<_ChatScreenState>();
    chatScreenState?.setState(() => chatScreenState._isDialogOpen = true);
    
    final reactions = ['👍', '❤️', '😂', '😮', '😢', '🙏'];
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.black87,
        title: const Text('Выберите реакцию'),
        content: Wrap(
          spacing: 16,
          runSpacing: 16,
          children: reactions.map((emoji) {
            return GestureDetector(
              onTap: () {
                onReaction?.call(message.id, emoji);
                Navigator.of(context).pop();
                chatScreenState?.setState(() => chatScreenState._isDialogOpen = false);
              },
              child: Text(emoji, style: const TextStyle(fontSize: 32)),
            );
          }).toList(),
        ),
      ),
    ).then((_) {
      chatScreenState?.setState(() => chatScreenState._isDialogOpen = false);
    });
  }

  Widget _buildMessageContent(BuildContext context, ChatMessage message) {
    switch (message.type) {
      case ChatMessageType.text:
        return _FormattedText(text: message.text ?? '');
      case ChatMessageType.image:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            GestureDetector(
              onTap: () {
                showDialog(
                  context: context,
                  builder: (_) => Dialog(
                    insetPadding: const EdgeInsets.all(8),
                    backgroundColor: Colors.transparent,
                    child: InteractiveViewer(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: (message.mediaPath != null && !message.mediaPath!.startsWith('assets/'))
                            ? Image.file(File(message.mediaPath!), fit: BoxFit.contain)
                            : Image.asset(message.mediaPath ?? '', fit: BoxFit.contain),
                      ),
                    ),
                  ),
                );
              },
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: (message.mediaPath != null && !message.mediaPath!.startsWith('assets/'))
                    ? Image.file(File(message.mediaPath!), width: MediaQuery.of(context).size.width * 0.65, fit: BoxFit.cover)
                    : Image.asset(message.mediaPath ?? '', width: MediaQuery.of(context).size.width * 0.65, fit: BoxFit.cover),
              ),
            ),
            if (message.text != null && message.text!.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                message.text!,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 14,
                ),
              ),
            ],
          ],
        );
      case ChatMessageType.voice:
        return _VoiceBubble(
          duration: Duration(seconds: message.voiceDurationSeconds ?? 0),
          sourcePath: message.mediaPath,
        );
      case ChatMessageType.file:
        return _FileBubble(fileName: message.text ?? 'Файл', filePath: message.mediaPath);
      case ChatMessageType.location:
        return _LocationBubble(
          text: message.text ?? '',
        );
      case ChatMessageType.poll:
        return _PollBubble(
          text: message.text ?? '',
        );
      case ChatMessageType.sticker:
        return _StickerBubble(
          text: message.text ?? '',
        );
      case ChatMessageType.call:
        return _CallBubble(
          text: message.text ?? '',
          isIncoming: !message.isMe,
        );
    }
  }

  String _formatTimestamp(DateTime time) {
    final hours = time.hour.toString().padLeft(2, '0');
    final minutes = time.minute.toString().padLeft(2, '0');
    return '$hours:$minutes';
  }
}


class _MessageInputField extends StatefulWidget {
  final void Function(String text) onSendText;
  final VoidCallback onPickImage;
  final Future<void> Function() onToggleRecord;
  final Function(bool)? onTypingChanged;
  final String? replyToMessageId;
  final String? replyToMessageText;
  final VoidCallback? onCancelReply;
  const _MessageInputField({
    super.key,
    required this.onSendText,
    required this.onPickImage,
    required this.onToggleRecord,
    this.onTypingChanged,
    this.replyToMessageId,
    this.replyToMessageText,
    this.onCancelReply,
  });
  @override
  State<_MessageInputField> createState() => _MessageInputFieldState();
}

class _MessageInputFieldState extends State<_MessageInputField> {
  final TextEditingController _controller = TextEditingController();
  bool _wasTyping = false;
  String _selectedEmojiCategory = 'Часто используемые';

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      if (mounted) setState(() {}); // Обновляем UI при изменении текста
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _send(BuildContext context) {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    _controller.clear();
    widget.onTypingChanged?.call(false);
    _wasTyping = false;
    // Вибрация при отправке сообщения (если включена)
    if (SettingsService.getVibrationEnabled()) {
      HapticFeedback.selectionClick();
    }
    widget.onSendText(text);
  }

  void _onTextChanged(String text) {
    // Убрано изменение состояния печатания - исправляет баг с тремя точками
    // final isTyping = text.trim().isNotEmpty;
    // if (isTyping != _wasTyping) {
    //   widget.onTypingChanged?.call(isTyping);
    //   _wasTyping = isTyping;
    // }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.all(6.0),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Theme.of(context).primaryColor.withOpacity(0.3), width: 1.5),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Панель цитирования (уменьшена)
                  if (widget.replyToMessageText != null)
                    Container(
                      margin: const EdgeInsets.only(bottom: 6),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border(
                          left: BorderSide(
                            color: Theme.of(context).primaryColor,
                            width: 2,
                          ),
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              widget.replyToMessageText ?? '',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.7),
                                fontSize: 11,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: Icon(PhosphorIconsBold.x, size: 14, color: Colors.white.withOpacity(0.6)),
                            onPressed: widget.onCancelReply,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ],
                      ),
                    ).animate()
                      .slideY(begin: -0.2, end: 0, duration: const Duration(milliseconds: 250), curve: Curves.easeOutCubic)
                      .fadeIn(duration: const Duration(milliseconds: 200)),
                  Row(
                    children: [
                      // Кнопка скрепки с меню
                      Builder(
                        builder: (context) {
                          final chatScreenState = context.findAncestorStateOfType<_ChatScreenState>();
                          return GlassButton(
                            onPressed: () {
                              chatScreenState?._showAttachmentMenu(context);
                            },
                            minWidth: 36,
                            minHeight: 36,
                            padding: const EdgeInsets.all(8),
                            child: Icon(PhosphorIconsBold.paperclip, color: Colors.white.withOpacity(0.9), size: 20),
                          );
                        },
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                    child: Builder(
                      builder: (context) {
                        final chatScreenState = context.findAncestorStateOfType<_ChatScreenState>();
                        if (chatScreenState?._isRecording != true) {
                          return TextField(
                            controller: _controller,
                            style: const TextStyle(color: Colors.white, fontSize: 16),
                            decoration: InputDecoration(
                              hintText: "Сообщение...",
                              border: InputBorder.none,
                              hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            ),
                            onChanged: _onTextChanged,
                            onSubmitted: (_) => _send(context),
                          );
                        }
                        final recordDuration = chatScreenState!._recordDuration;
                        final minutes = (recordDuration.inSeconds ~/ 60).toString().padLeft(2, '0');
                        final seconds = (recordDuration.inSeconds % 60).toString().padLeft(2, '0');
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.red.withOpacity(0.4), width: 1.5),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.red,
                                ),
                              )
                                .animate(onPlay: (controller) => controller.repeat())
                                .scale(begin: const Offset(1.0, 1.0), end: const Offset(1.3, 1.3), duration: const Duration(milliseconds: 500), curve: Curves.easeInOut)
                                .then()
                                .scale(begin: const Offset(1.3, 1.3), end: const Offset(1.0, 1.0), duration: const Duration(milliseconds: 500), curve: Curves.easeInOut),
                              const SizedBox(width: 8),
                              Text(
                                '$minutes:$seconds',
                                style: const TextStyle(
                                  color: Colors.red,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        )
                          .animate()
                          .fadeIn(duration: const Duration(milliseconds: 200))
                          .slideX(begin: -0.2, end: 0, duration: const Duration(milliseconds: 300), curve: Curves.easeOutCubic);
                      },
                    ),
                  ),
                  Builder(
                    builder: (context) {
                      final chatScreenState = context.findAncestorStateOfType<_ChatScreenState>();
                      final isRecording = chatScreenState?._isRecording ?? false;
                      
                      return Stack(
                        alignment: Alignment.center,
                        children: [
                              if (isRecording)
                                TweenAnimationBuilder<double>(
                                  tween: Tween(begin: 0.0, end: 1.0),
                                  duration: const Duration(milliseconds: 1000),
                                  builder: (context, value, child) {
                                    return Container(
                                      width: 40 + (value * 8),
                                      height: 40 + (value * 8),
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: Colors.red.withOpacity(0.2 - (value * 0.15)),
                                      ),
                                    );
                                  },
                                  onEnd: () {
                                    if (mounted && isRecording) {
                                      setState(() {});
                                    }
                                  },
                                ),
                              GlassContainer(
                                padding: EdgeInsets.zero,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(10),
                                  color: isRecording ? Colors.red.withOpacity(0.3) : Colors.white.withOpacity(0.1),
                                ),
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(10),
                                    onTap: () => widget.onToggleRecord(),
                                    onLongPress: () => widget.onToggleRecord(),
                                    child: Container(
                                      width: 36,
                                      height: 36,
                                      alignment: Alignment.center,
                                      child: AnimatedContainer(
                                        duration: const Duration(milliseconds: 200),
                                        curve: Curves.easeInOut,
                                        child: Icon(
                                          isRecording ? PhosphorIconsBold.microphone : PhosphorIconsBold.microphoneSlash,
                                          color: isRecording ? Colors.red : Colors.white.withOpacity(0.9),
                                          size: 18,
                                        )
                                          .animate(target: isRecording ? 1 : 0)
                                          .scale(begin: const Offset(1.0, 1.0), end: const Offset(1.15, 1.15), duration: const Duration(milliseconds: 300))
                                          .then()
                                          .scale(begin: const Offset(1.15, 1.15), end: const Offset(1.0, 1.0), duration: const Duration(milliseconds: 300)),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          );
                    },
                  ),
                  const SizedBox(width: 6),
                  GlassButton(
                    onPressed: () => _send(context),
                    minWidth: 36,
                    minHeight: 36,
                    padding: const EdgeInsets.all(8),
                    child: Icon(
                      PhosphorIconsBold.paperPlaneRight, 
                      color: _controller.text.trim().isNotEmpty 
                          ? Colors.white
                          : Colors.white.withOpacity(0.5), 
                      size: 18,
                    ),
                  ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ).animate().slideY(begin: 0.2, duration: Duration(milliseconds: 350), curve: Curves.easeOutCubic).fadeIn(duration: Duration(milliseconds: 300));
  }
}

// Text formatting: **bold**, *italic*, ||spoiler||
class _FormattedText extends StatelessWidget {
  final String text;
  const _FormattedText({required this.text});

  @override
  Widget build(BuildContext context) {
    final spans = _parse(text, context);
    return RichText(text: TextSpan(children: spans, style: const TextStyle(fontSize: 14, color: Colors.white)));
  }

  List<InlineSpan> _parse(String input, BuildContext context) {
    final List<InlineSpan> spans = [];
    int i = 0;
    while (i < input.length) {
      // Жирный текст: **text** или __text__
      if (input.startsWith('**', i) || input.startsWith('__', i)) {
        final marker = input.substring(i, i + 2);
        final end = input.indexOf(marker, i + 2);
        if (end != -1) {
          final content = input.substring(i + 2, end);
          spans.add(TextSpan(text: content, style: const TextStyle(fontWeight: FontWeight.w700)));
          i = end + 2;
          continue;
        }
      }
      // Курсив: *text* или _text_
      if (input.startsWith('*', i) && !input.startsWith('**', i)) {
        final end = input.indexOf('*', i + 1);
        if (end != -1 && (end == i + 1 || input[end - 1] != '*')) {
          final content = input.substring(i + 1, end);
          spans.add(TextSpan(text: content, style: const TextStyle(fontStyle: FontStyle.italic)));
          i = end + 1;
          continue;
        }
      }
      if (input.startsWith('_', i) && !input.startsWith('__', i)) {
        final end = input.indexOf('_', i + 1);
        if (end != -1 && (end == i + 1 || input[end - 1] != '_')) {
          final content = input.substring(i + 1, end);
          spans.add(TextSpan(text: content, style: const TextStyle(fontStyle: FontStyle.italic)));
          i = end + 1;
          continue;
        }
      }
      // Зачеркнутый: ~~text~~
      if (input.startsWith('~~', i)) {
        final end = input.indexOf('~~', i + 2);
        if (end != -1) {
          final content = input.substring(i + 2, end);
          spans.add(TextSpan(text: content, style: const TextStyle(decoration: TextDecoration.lineThrough)));
          i = end + 2;
          continue;
        }
      }
      // Моноширинный: `text`
      if (input.startsWith('`', i)) {
        final end = input.indexOf('`', i + 1);
        if (end != -1) {
          final content = input.substring(i + 1, end);
          spans.add(TextSpan(text: content, style: TextStyle(fontFamily: 'monospace', backgroundColor: Colors.white.withOpacity(0.1))));
          i = end + 1;
          continue;
        }
      }
      // Скрытый текст: ||text||
      if (input.startsWith('||', i)) {
        final end = input.indexOf('||', i + 2);
        if (end != -1) {
          final content = input.substring(i + 2, end);
          spans.add(WidgetSpan(
            alignment: PlaceholderAlignment.baseline,
            baseline: TextBaseline.alphabetic,
            child: _Spoiler(text: content),
          ));
          i = end + 2;
          continue;
        }
      }
      spans.add(TextSpan(text: input[i]));
      i++;
    }
    return spans;
  }
}

class _Spoiler extends StatefulWidget {
  final String text;
  const _Spoiler({required this.text});
  @override
  State<_Spoiler> createState() => _SpoilerState();
}

class _SpoilerState extends State<_Spoiler> {
  bool _revealed = false;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => setState(() => _revealed = true),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(_revealed ? 0.0 : 0.12),
          borderRadius: BorderRadius.circular(4),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
        child: Text(
          _revealed ? widget.text : 'спойлер',
          style: TextStyle(color: Colors.white.withOpacity(_revealed ? 1.0 : 0.0)),
        ),
      ),
    );
  }
}

// Recording control (in ChatScreen state)
extension on _ChatScreenState {
  Future<void> _onToggleRecord() async {
    if (_isRecording) {
      _recordTimer?.cancel();
      final path = await _recorder.stop();
      final dur = _recordDuration;
      if (dur.inSeconds < 1) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Запись слишком короткая')),
        );
      }
      setState(() {
        _isRecording = false;
        _recordStart = null;
        _recordDuration = Duration.zero;
      });
      if (path != null && dur.inSeconds >= 1) {
        // Анимация отправки
        HapticFeedback.mediumImpact();
        _addVoiceMessage(path, dur);
      }
      return;
    }
    if (await _recorder.hasPermission()) {
      final path = await _createRecordingPath();
      await _recorder.start(
        const RecordConfig(
          encoder: AudioEncoder.aacLc,
          bitRate: 128000,
          sampleRate: 44100,
        ),
        path: path,
      );
      final startTime = DateTime.now();
      setState(() {
        _isRecording = true;
        _recordStart = startTime;
        _recordDuration = Duration.zero;
      });
      HapticFeedback.mediumImpact();
      _recordTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
        if (mounted && _isRecording) {
          setState(() {
            _recordDuration = DateTime.now().difference(_recordStart!);
          });
        } else {
          timer.cancel();
        }
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Нет доступа к микрофону')));
    }
  }
}

extension _RecorderPath on _ChatScreenState {
  Future<String> _createRecordingPath() async {
    final directory = await getTemporaryDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return '${directory.path}/mimu_record_$timestamp.m4a';
  }
}

class _VoiceBubble extends StatefulWidget {
  final Duration duration;
  final String? sourcePath;
  const _VoiceBubble({required this.duration, this.sourcePath});
  @override
  State<_VoiceBubble> createState() => _VoiceBubbleState();
}

class _VoiceBubbleState extends State<_VoiceBubble> with SingleTickerProviderStateMixin {
  bool _playing = false;
  Duration _position = Duration.zero;
  final AudioPlayer _player = AudioPlayer();
  late AnimationController _waveController;
  final List<double> _waveHeights = [0.3, 0.6, 0.4, 0.8, 0.5, 0.7, 0.4];

  @override
  void initState() {
    super.initState();
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat();
    _player.onPositionChanged.listen((position) {
      if (mounted) setState(() => _position = position);
    });
    _player.onPlayerComplete.listen((_) {
      if (mounted) {
        setState(() {
          _playing = false;
          _position = Duration.zero;
        });
      }
    });
  }

  @override
  void dispose() {
    _player.dispose();
    _waveController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    String two(int n) => n.toString().padLeft(2, '0');
    final totalMins = two(widget.duration.inMinutes);
    final totalSecs = two(widget.duration.inSeconds % 60);
    final currentMins = two(_position.inMinutes);
    final currentSecs = two(_position.inSeconds % 60);
    final progress = widget.duration.inMilliseconds > 0 
        ? _position.inMilliseconds / widget.duration.inMilliseconds 
        : 0.0;

    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (_playing)
                  SizedBox(
                    width: 70,
                    height: 24,
                    child: AnimatedBuilder(
                      animation: _waveController,
                      builder: (context, child) {
                        return Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: _waveHeights.asMap().entries.map((entry) {
                            final phase = (_waveController.value * 2 * 3.14159) + (entry.key * 0.5);
                            final height = entry.value * (0.6 + 0.4 * (0.5 + 0.5 * (math.sin(phase) + 1)));
                            return AnimatedContainer(
                              duration: const Duration(milliseconds: 100),
                              width: 3.5,
                              height: 24 * height.clamp(0.3, 1.0),
                              decoration: BoxDecoration(
                                color: Theme.of(context).primaryColor,
                                borderRadius: BorderRadius.circular(2),
                                boxShadow: [
                                  BoxShadow(
                                    color: Theme.of(context).primaryColor.withOpacity(0.5),
                                    blurRadius: 4,
                                    spreadRadius: 0.5,
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        );
                      },
                    ),
                  )
                  .animate()
                  .fadeIn(duration: const Duration(milliseconds: 300))
                  .scale(begin: const Offset(0.8, 0.8), end: const Offset(1.0, 1.0), duration: const Duration(milliseconds: 300), curve: Curves.easeOutCubic)
                else
                  Container(
                    width: 140,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(2),
                    ),
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: progress.clamp(0.0, 1.0),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Theme.of(context).primaryColor,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  _position.inSeconds > 0 ? "$currentMins:$currentSecs" : "$totalMins:$totalSecs",
                  style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 11),
                ),
                Text(
                  ' / $totalMins:$totalSecs',
                  style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 11),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(width: 12),
        GestureDetector(
          onTap: () async {
            if (widget.sourcePath == null) return;
            if (_playing) {
              await _player.pause();
              setState(() => _playing = false);
            } else {
              await _player.play(DeviceFileSource(widget.sourcePath!));
              setState(() => _playing = true);
            }
          },
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Theme.of(context).primaryColor.withOpacity(0.2),
            ),
            child: Icon(
              _playing ? Icons.pause : Icons.play_arrow,
              color: Theme.of(context).primaryColor,
              size: 24,
            ),
          ),
        ),
      ],
    );
  }
}

class _FileBubble extends StatelessWidget {
  final String fileName;
  final String? filePath;
  const _FileBubble({required this.fileName, this.filePath});

  Future<void> _openFile(BuildContext context) async {
    if (filePath == null) return;
    final file = File(filePath!);
    if (!file.existsSync()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Файл не найден')),
      );
      return;
    }
    
    try {
      final uri = Uri.file(filePath!);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Не удалось открыть файл: $fileName')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка открытия файла: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _openFile(context),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              PhosphorIconsBold.file,
              color: Theme.of(context).primaryColor,
              size: 32,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    fileName,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Нажмите, чтобы открыть',
                    style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.6)),
                  ),
                ],
              ),
            ),
            Icon(
              PhosphorIconsBold.download,
              color: Colors.white.withOpacity(0.5),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

class _CallBubble extends StatelessWidget {
  final String text;
  final bool isIncoming;
  const _CallBubble({required this.text, required this.isIncoming});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          text.contains('видео') ? PhosphorIconsBold.videoCamera : PhosphorIconsBold.phone,
          color: Colors.white.withOpacity(0.8),
          size: 18,
        ),
        const SizedBox(width: 8),
        Text(
          text,
          style: TextStyle(
            color: Colors.white.withOpacity(0.9),
            fontSize: 14,
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
  }
}

class _LocationBubble extends StatelessWidget {
  final String text;
  const _LocationBubble({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(PhosphorIconsBold.mapPin, color: Theme.of(context).primaryColor, size: 32),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  text.isNotEmpty ? text : 'Местоположение',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 4),
                Text(
                  'Нажмите, чтобы открыть в картах',
                  style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.6)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PollBubble extends StatelessWidget {
  final String text;
  const _PollBubble({required this.text});

  @override
  Widget build(BuildContext context) {
    final options = text.split('\n').where((s) => s.isNotEmpty).toList();
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(PhosphorIconsBold.chartBar, color: Theme.of(context).primaryColor, size: 20),
              const SizedBox(width: 8),
              const Text('Опрос', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 12),
          ...options.map((option) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.03),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Expanded(child: Text(option, style: const TextStyle(fontSize: 13))),
                      Text('0%', style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.6))),
                    ],
                  ),
                ),
              )),
        ],
      ),
    );
  }
}

class _StickerBubble extends StatelessWidget {
  final String text;
  const _StickerBubble({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.white.withOpacity(0.05),
      ),
      child: Center(
        child: Text(
          text.isNotEmpty ? text : '🎭',
          style: const TextStyle(fontSize: 64),
        ),
      ),
    );
  }
}

class _TypingIndicator extends StatefulWidget {
  @override
  State<_TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<_TypingIndicator> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.04),
          borderRadius: BorderRadius.circular(15),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (index) {
            return AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                final delay = index * 0.2;
                final animationValue = ((_controller.value + delay) % 1.0);
                final opacity = (animationValue < 0.5) ? animationValue * 2 : 2 - (animationValue * 2);
                return Padding(
                  padding: EdgeInsets.only(right: index < 2 ? 4 : 0),
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.3 + opacity * 0.5),
                    ),
                  ),
                );
              },
            );
          }),
        ),
      ),
    );
  }
}