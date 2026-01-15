import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:mimu/shared/glass_widgets.dart';
import 'package:mimu/shared/animated_widgets.dart';
import 'package:provider/provider.dart';
import 'package:mimu/data/chat_store.dart';
import 'package:mimu/data/models/chat_models.dart';
import 'package:mimu/data/settings_service.dart';
import 'package:mimu/data/user_service.dart';
import 'package:mimu/app/theme.dart';
import 'package:mimu/shared/cupertino_dialogs.dart';
import 'package:flutter_animate/flutter_animate.dart';

class GroupSettingsScreen extends StatefulWidget {
  final String chatId;
  const GroupSettingsScreen({super.key, required this.chatId});

  @override
  State<GroupSettingsScreen> createState() => _GroupSettingsScreenState();
}

class _GroupSettingsScreenState extends State<GroupSettingsScreen> {
  bool _notificationsEnabled = true;
  bool _isPinned = false;
  bool _isMuted = false;
  bool _onlyAdminsCanPost = false;
  bool _onlyAdminsCanAddMembers = false;
  String _groupDescription = '';

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    await SettingsService.init();
    setState(() {
      _isMuted = SettingsService.isChatMuted(widget.chatId);
      _isPinned = SettingsService.isChatPinned(widget.chatId);
      _notificationsEnabled = !_isMuted;
      _onlyAdminsCanPost = SettingsService.getGroupOnlyAdminsPost(widget.chatId);
      _onlyAdminsCanAddMembers = SettingsService.getGroupOnlyAdminsAdd(widget.chatId);
    });
  }

  void _showPermissionSnack(BuildContext context, String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ChatStore>(
      builder: (context, chatStore, _) {
        final chat = chatStore.threadById(widget.chatId);
        if (chat == null) {
          return Scaffold(
            appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
            body: const Center(child: Text('Группа не найдена')),
          );
        }

        return Scaffold(
          extendBodyBehindAppBar: true,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: GlassIconButton(
              icon: CupertinoIcons.chevron_left,
              onPressed: () => Navigator.of(context).pop(),
            ),
            title: Text('Настройки группы'),
            centerTitle: true,
            flexibleSpace: ClipRRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                child: Container(color: Colors.transparent),
              ),
            ),
          ),
          body: Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage("assets/images/background_pattern.png"),
                fit: BoxFit.cover,
              ),
            ),
            child: SafeArea(
              child: ListView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.all(16),
                children: [
                  AnimateOnDisplay(
                    child: Center(
                      child: Column(
                        children: [
                          CircleAvatar(
                            radius: 50,
                            backgroundImage: chat.avatarAsset.startsWith('assets/')
                                ? AssetImage(chat.avatarAsset)
                                : const AssetImage('assets/images/avatar_placeholder.png'),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            chat.title,
                            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            '${chat.participantIds.length} участников',
                            style: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.6)),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  AnimateOnDisplay(
                    delayMs: 100,
                    child: Text('Уведомления', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(height: 12),
                  AnimateOnDisplay(
                    delayMs: 150,
                    child: GlassContainer(
                      padding: EdgeInsets.zero,
                      child: Column(
                        children: [
                          ListTile(
                            leading: Icon(CupertinoIcons.bell_fill, color: Theme.of(context).primaryColor),
                            title: const Text('Уведомления'),
                            subtitle: Text(_notificationsEnabled ? 'Включены' : 'Отключены', 
                                style: TextStyle(color: Colors.white.withOpacity(0.6))),
                            trailing: Switch(
                              value: _notificationsEnabled,
                              onChanged: (value) async {
                                setState(() => _notificationsEnabled = value);
                                await SettingsService.setChatMuted(widget.chatId, !value);
                              },
                            ),
                          ),
                          Divider(height: 1, color: Colors.white.withOpacity(0.1)),
                          ListTile(
                            leading: Icon(CupertinoIcons.bell_slash_fill, color: Theme.of(context).primaryColor),
                            title: const Text('Отключить звук'),
                            subtitle: Text(_isMuted ? 'Включено' : 'Выключено', 
                                style: TextStyle(color: Colors.white.withOpacity(0.6))),
                            trailing: Switch(
                              value: _isMuted,
                              onChanged: (value) async {
                                setState(() => _isMuted = value);
                                await SettingsService.setChatMuted(widget.chatId, value);
                              },
                            ),
                          ),
                          Divider(height: 1, color: Colors.white.withOpacity(0.1)),
                          ListTile(
                            leading: Icon(CupertinoIcons.pin_fill, color: Theme.of(context).primaryColor),
                            title: const Text('Закрепить чат'),
                            subtitle: Text(_isPinned ? 'Закреплен' : 'Не закреплен', 
                                style: TextStyle(color: Colors.white.withOpacity(0.6))),
                            trailing: Switch(
                              value: _isPinned,
                              onChanged: (value) async {
                                setState(() => _isPinned = value);
                                await SettingsService.setChatPinned(widget.chatId, value);
                                chatStore.notifyListeners();
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  AnimateOnDisplay(
                    delayMs: 200,
                    child: Text('Права администратора', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(height: 12),
                  AnimateOnDisplay(
                    delayMs: 250,
                    child: GlassContainer(
                      padding: EdgeInsets.zero,
                      child: Column(
                        children: [
                          ListTile(
                            leading: Icon(CupertinoIcons.person_circle_fill, color: Theme.of(context).primaryColor),
                            title: const Text('Только администраторы могут публиковать'),
                            subtitle: Text(_onlyAdminsCanPost ? 'Включено' : 'Выключено', 
                                style: TextStyle(color: Colors.white.withOpacity(0.6))),
                            trailing: Switch(
                              value: _onlyAdminsCanPost,
                              onChanged: (value) async {
                                setState(() => _onlyAdminsCanPost = value);
                                await SettingsService.setGroupOnlyAdminsPost(widget.chatId, value);
                                _showPermissionSnack(context, value
                                    ? 'Теперь публиковать могут только администраторы'
                                    : 'Любой участник может публиковать сообщения');
                              },
                            ),
                          ),
                          Divider(height: 1, color: Colors.white.withOpacity(0.1)),
                          ListTile(
                            leading: Icon(CupertinoIcons.person_add_solid, color: Theme.of(context).primaryColor),
                            title: const Text('Только администраторы могут добавлять участников'),
                            subtitle: Text(_onlyAdminsCanAddMembers ? 'Включено' : 'Выключено', 
                                style: TextStyle(color: Colors.white.withOpacity(0.6))),
                            trailing: Switch(
                              value: _onlyAdminsCanAddMembers,
                              onChanged: (value) async {
                                setState(() => _onlyAdminsCanAddMembers = value);
                                await SettingsService.setGroupOnlyAdminsAdd(widget.chatId, value);
                                _showPermissionSnack(context, value
                                    ? 'Добавлять участников могут только администраторы'
                                    : 'Любой участник может приглашать друзей');
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  AnimateOnDisplay(
                    delayMs: 300,
                    child: Text('Участники', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(height: 12),
                  AnimateOnDisplay(
                    delayMs: 350,
                    child: GlassContainer(
                      padding: EdgeInsets.zero,
                      child: Column(
                        children: [
                          ListTile(
                            leading: Icon(CupertinoIcons.person_3_fill, color: Theme.of(context).primaryColor),
                            title: const Text('Участники'),
                            subtitle: Text('${chat.participantIds.length} человек', 
                                style: TextStyle(color: Colors.white.withOpacity(0.6))),
                            trailing: Icon(CupertinoIcons.chevron_right, color: Colors.white.withOpacity(0.5)),
                            onTap: () => _showParticipants(context, chatStore, chat),
                          ),
                          Divider(height: 1, color: Colors.white.withOpacity(0.1)),
                          ListTile(
                            leading: Icon(CupertinoIcons.person_add_solid, color: Theme.of(context).primaryColor),
                            title: const Text('Добавить участника'),
                            trailing: Icon(CupertinoIcons.chevron_right, color: Colors.white.withOpacity(0.5)),
                            onTap: () => _showAddParticipant(context, chatStore, chat),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  AnimateOnDisplay(
                    delayMs: 400,
                    child: Text('О группе', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(height: 12),
                  AnimateOnDisplay(
                    delayMs: 450,
                    child: GlassContainer(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _groupDescription.isEmpty ? 'Нет описания' : _groupDescription,
                            style: TextStyle(
                              color: _groupDescription.isEmpty 
                                  ? Colors.white.withOpacity(0.5) 
                                  : Colors.white,
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextButton.icon(
                            onPressed: () {
                              final controller = TextEditingController(text: _groupDescription);
                              showCupertinoDialog(
                                context: context,
                                builder: (context) => buildCupertinoDialog(
                                  context: context,
                                  title: 'Описание группы',
                                  content: CupertinoTextField(
                                    controller: controller,
                                    style: const TextStyle(color: Colors.white),
                                    maxLines: 3,
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.08),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: Colors.white.withOpacity(0.1)),
                                    ),
                                  ),
                                  actions: [
                                    CupertinoDialogAction(
                                      onPressed: () => Navigator.of(context).pop(),
                                      child: const Text('Отмена'),
                                    ),
                                    CupertinoDialogAction(
                                      isDefaultAction: true,
                                      onPressed: () {
                                        setState(() => _groupDescription = controller.text.trim());
                                        Navigator.of(context).pop();
                                      },
                                      child: const Text('Сохранить'),
                                    ),
                                  ],
                                ),
                              );
                            },
                            icon: Icon(CupertinoIcons.pencil, size: 18, color: Theme.of(context).primaryColor),
                            label: Text(_groupDescription.isEmpty ? 'Добавить описание' : 'Изменить описание'),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const SizedBox(height: 24),
                  AnimateOnDisplay(
                    delayMs: 500,
                    child: Text('Медиа', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(height: 12),
                  AnimateOnDisplay(
                    delayMs: 550,
                    child: SizedBox(
                      height: 100,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: 5,
                        itemBuilder: (context, index) {
                          return Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.asset('assets/images/avatar_placeholder.png', width: 100, height: 100, fit: BoxFit.cover),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  AnimateOnDisplay(
                    delayMs: 600,
                    child: GlassButton(
                      onPressed: () {
                        showCupertinoDialog(
                          context: context,
                          builder: (context) => buildCupertinoDialog(
                            context: context,
                            title: 'Покинуть группу',
                            content: const Text('Вы уверены, что хотите покинуть эту группу?'),
                            actions: [
                              CupertinoDialogAction(
                                onPressed: () => Navigator.of(context).pop(),
                                child: const Text('Отмена'),
                              ),
                              CupertinoDialogAction(
                                isDestructiveAction: true,
                                onPressed: () async {
                                  // Удаляем текущего пользователя из участников
                                  await UserService.init();
                                  final currentUsername = UserService.getUsername();
                                  final updatedParticipants = List<String>.from(chat.participantIds);
                                  // Ищем контакт по username или используем первый доступный
                                  final currentContact = chatStore.contacts.firstWhere(
                                    (c) => c.id == currentUsername || c.name == UserService.getDisplayName(),
                                    orElse: () => chatStore.contacts.isNotEmpty ? chatStore.contacts.first : ChatContact(
                                      id: currentUsername,
                                      name: UserService.getDisplayName(),
                                      avatarAsset: 'assets/images/avatar_placeholder.png',
                                    ),
                                  );
                                  updatedParticipants.removeWhere((id) => id == currentContact.id);
                                  
                                  if (updatedParticipants.isEmpty) {
                                    // Если группа пустая, удаляем её
                                    await chatStore.deleteChat(chat.id);
                                  } else {
                                    final updatedChat = chat.copyWith(participantIds: updatedParticipants);
                                    final index = chatStore.threads.indexWhere((t) => t.id == chat.id);
                                    if (index != -1) {
                                      chatStore.threads[index] = updatedChat;
                                      await chatStore.persistThreads();
                                      chatStore.notifyListeners();
                                    }
                                  }
                                  
                                  Navigator.of(context).pop();
                                  Navigator.of(context).pop();
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Вы покинули группу')),
                                    );
                                  }
                                },
                                child: const Text('Покинуть'),
                              ),
                            ],
                          ),
                        );
                      },
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(CupertinoIcons.arrow_right_square, color: Colors.redAccent, size: 20),
                          SizedBox(width: 8),
                          Text('Покинуть группу', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showParticipants(BuildContext context, ChatStore chatStore, ChatThread chat) {
    showGlassBottomSheet(
      context: context,
      initialChildSize: 0.6,
      minChildSize: 0.3,
      maxChildSize: 0.9,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                const Text('Участники', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text('${chat.participantIds.length}', 
                      style: TextStyle(color: Theme.of(context).primaryColor, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 8),
                GlassIconButton(
                  icon: CupertinoIcons.xmark,
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView.builder(
              itemCount: chat.participantIds.length,
              itemBuilder: (context, index) {
                final participantId = chat.participantIds[index];
                final contact = chatStore.contacts.firstWhere(
                  (c) => c.id == participantId,
                  orElse: () => ChatContact(
                    id: participantId,
                    name: participantId,
                    avatarAsset: 'assets/images/avatar_placeholder.png',
                  ),
                );
                return AnimateOnDisplay(
                  delayMs: 50 * index,
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundImage: AssetImage(contact.avatarAsset),
                    ),
                    title: Text(contact.name),
                    subtitle: index == 0 
                        ? Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(CupertinoIcons.star_fill, size: 14, color: Theme.of(context).primaryColor),
                              const SizedBox(width: 4),
                              const Text('Администратор'),
                            ],
                          )
                        : null,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showAddParticipant(BuildContext context, ChatStore chatStore, ChatThread chat) {
    final availableContacts = chatStore.contacts.where(
      (c) => !chat.participantIds.contains(c.id),
    ).toList();
    
    showGlassBottomSheet(
      context: context,
      initialChildSize: 0.6,
      minChildSize: 0.3,
      maxChildSize: 0.9,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                const Text('Добавить участника', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const Spacer(),
                GlassIconButton(
                  icon: CupertinoIcons.xmark,
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: availableContacts.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(CupertinoIcons.person_add_solid, size: 64, color: Colors.white.withOpacity(0.3)),
                        const SizedBox(height: 16),
                        Text('Нет доступных контактов', 
                            style: TextStyle(color: Colors.white.withOpacity(0.6))),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: availableContacts.length,
                    itemBuilder: (context, index) {
                      final contact = availableContacts[index];
                      return AnimateOnDisplay(
                        delayMs: 50 * index,
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundImage: AssetImage(contact.avatarAsset),
                          ),
                          title: Text(contact.name),
                          trailing: GlassButton(
                            onPressed: () async {
                              final updatedParticipants = List<String>.from(chat.participantIds)..add(contact.id);
                              final updatedChat = chat.copyWith(participantIds: updatedParticipants);
                              final threadIndex = chatStore.threads.indexWhere((t) => t.id == chat.id);
                              if (threadIndex != -1) {
                                chatStore.threads[threadIndex] = updatedChat;
                                await chatStore.persistThreads();
                                chatStore.notifyListeners();
                              }
                              Navigator.of(context).pop();
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('${contact.name} добавлен в группу')),
                                );
                              }
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(8),
                              child: Icon(CupertinoIcons.add, 
                                  color: Theme.of(context).primaryColor, size: 18),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

