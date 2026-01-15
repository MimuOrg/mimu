import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';

import 'package:mimu/app/routes.dart';
import 'package:mimu/data/chat_store.dart';
import 'package:mimu/data/settings_service.dart';
import 'package:mimu/shared/animated_widgets.dart';
import 'package:mimu/shared/glass_widgets.dart';
import 'package:mimu/shared/cupertino_dialogs.dart';

enum EntityType {
  group,
  channel,
}

class CreateEntitiesScreen extends StatelessWidget {
  final EntityType entityType;

  const CreateEntitiesScreen({super.key, required this.entityType});

  @override
  Widget build(BuildContext context) {
    if (entityType == EntityType.group) {
      return const CreateGroupScreen();
    } else {
      return const CreateChannelScreen();
    }
  }
}

class CreateGroupScreen extends StatefulWidget {
  const CreateGroupScreen({super.key});

  @override
  State<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends State<CreateGroupScreen> {
  final nameController = TextEditingController();
  final descriptionController = TextEditingController();
  final Set<String> _selectedUsers = {};
  bool _isPublic = true;
  final ImagePicker _picker = ImagePicker();
  File? _groupPhoto;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: GlassIconButton(
          icon: CupertinoIcons.chevron_left,
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Новая группа'),
        actions: [
          TextButton(
            onPressed: _selectedUsers.isEmpty || nameController.text.isEmpty
                ? null
                : () async {
                    final chatStore = context.read<ChatStore>();
                    final chatId = await chatStore.createChat(
                      title: nameController.text.trim(),
                      isGroup: true,
                      participantIds: _selectedUsers.toList(),
                      avatarAsset: _groupPhoto?.path ?? 'assets/images/avatar_placeholder.png',
                    );
                    await SettingsService.setGroupVisibility(chatId, _isPublic);
                    await SettingsService.setGroupOnlyAdminsPost(chatId, false);
                    await SettingsService.setGroupOnlyAdminsAdd(chatId, false);
                    if (!mounted) return;
                    Navigator.of(context).pop();
                    Navigator.pushNamed(context, AppRoutes.chat, arguments: {'chatId': chatId});
                  },
            child: Text('Создать', style: TextStyle(color: _selectedUsers.isEmpty || nameController.text.isEmpty
                ? Colors.white.withOpacity(0.3)
                : Theme.of(context).primaryColor)),
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
                  GestureDetector(
                    onTap: () async {
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
                                  final XFile? file = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
                                  if (file != null && mounted) {
                                    setState(() => _groupPhoto = File(file.path));
                                  }
                                } catch (e) {
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Ошибка выбора изображения: ${e.toString()}'),
                                        backgroundColor: Colors.redAccent,
                                      ),
                                    );
                                  }
                                }
                              },
                              child: const Text('Галерея'),
                            ),
                            CupertinoActionSheetAction(
                              onPressed: () async {
                                Navigator.of(context).pop();
                                try {
                                  final XFile? file = await _picker.pickImage(source: ImageSource.camera, imageQuality: 85);
                                  if (file != null && mounted) {
                                    setState(() => _groupPhoto = File(file.path));
                                  }
                                } catch (e) {
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Ошибка выбора изображения: ${e.toString()}'),
                                        backgroundColor: Colors.redAccent,
                                      ),
                                    );
                                  }
                                }
                              },
                              child: const Text('Камера'),
                            ),
                          ],
                          cancelButton: CupertinoActionSheetAction(
                            onPressed: () => Navigator.of(context).pop(),
                            child: const Text('Отмена'),
                          ),
                        ),
                      );
                    },
                    child: Stack(
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                          child: CircleAvatar(
                            radius: 50,
                            backgroundColor: Colors.white.withOpacity(0.1),
                            backgroundImage: _groupPhoto != null ? FileImage(_groupPhoto!) : null,
                            child: _groupPhoto == null
                                ? Icon(CupertinoIcons.camera_fill, size: 32, color: Colors.white.withOpacity(0.7))
                                : null,
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: const Color(0xFF0A0A0A), // Богатый черный вместо фиолетового
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.6),
                                  blurRadius: 12,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: CircleAvatar(
                              radius: 16,
                              backgroundColor: Colors.transparent,
                              child: const Icon(Icons.add, color: Colors.white, size: 20),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
            AnimateOnDisplay(
              delayMs: 100,
              child: GlassContainer(
                child: Column(
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        hintText: 'Название группы',
                        hintStyle: TextStyle(color: Colors.white54),
                      ),
                      style: const TextStyle(color: Colors.white),
                      onChanged: (_) => setState(() {}),
                    ),
                    const Divider(height: 1),
                    TextField(
                      controller: descriptionController,
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        hintText: 'Описание (необязательно)',
                        hintStyle: TextStyle(color: Colors.white54),
                      ),
                      style: const TextStyle(color: Colors.white),
                      maxLines: 3,
                    ),
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
                    ListTile(
                      title: const Text('Публичная группа'),
                      subtitle: Text(_isPublic ? 'Любой может присоединиться' : 'Только по приглашению',
                          style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 12)),
                      trailing: Switch(
                        value: _isPublic,
                        onChanged: (value) => setState(() => _isPublic = value),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            AnimateOnDisplay(
              delayMs: 300,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Участники (${_selectedUsers.length})',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  TextButton.icon(
                    onPressed: () {
                      final contacts = context.read<ChatStore>().contacts;
                      showCupertinoModalPopup(
                        context: context,
                        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                        builder: (context) => CupertinoActionSheet(
                          actions: [
                            CupertinoActionSheetAction(
                              onPressed: () {
                                Navigator.of(context).pop();
                                setState(() {
                                  _selectedUsers
                                    ..clear()
                                    ..addAll(contacts.map((c) => c.id));
                                });
                              },
                              child: const Text('Выбрать всех'),
                            ),
                            CupertinoActionSheetAction(
                              onPressed: () {
                                Navigator.of(context).pop();
                                setState(() => _selectedUsers.clear());
                              },
                              child: const Text('Очистить выбор'),
                            ),
                          ],
                          cancelButton: CupertinoActionSheetAction(
                            isDestructiveAction: false,
                            onPressed: () => Navigator.of(context).pop(),
                            child: const Text('Отмена'),
                          ),
                        ),
                      );
                    },
                    icon: const Icon(CupertinoIcons.list_bullet),
                    label: const Text('Действия'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            if (_selectedUsers.isEmpty)
              AnimateOnDisplay(
                delayMs: 350,
                child: Column(
                  children: [
                    Center(
                      child: Column(
                        children: [
                          Icon(CupertinoIcons.person_3_fill, size: 64, color: Colors.white.withOpacity(0.3)),
                          const SizedBox(height: 16),
                          Text('Добавьте участников', style: TextStyle(color: Colors.white.withOpacity(0.5))),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    GlassButton(
                      onPressed: () {
                        showCupertinoModalPopup(
                          context: context,
                          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                          builder: (context) => _UserSelectionSheet(
                            selectedUsers: _selectedUsers,
                            onSelectionChanged: (selected) {
                              setState(() {
                                _selectedUsers
                                  ..clear()
                                  ..addAll(selected);
                              });
                            },
                          ),
                        );
                      },
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(CupertinoIcons.person_add_solid, color: Theme.of(context).primaryColor, size: 20),
                          const SizedBox(width: 8),
                          const Text('Выбрать участников', style: TextStyle(fontSize: 16)),
                        ],
                      ),
                    ),
                  ],
                ),
              )
            else
              ..._selectedUsers.map((userId) {
                final user = context.read<ChatStore>().contacts.firstWhere((u) => u.id == userId);
                return AnimateOnDisplay(
                  delayMs: 350,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: GlassContainer(
                      padding: const EdgeInsets.all(12),
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: CircleAvatar(backgroundImage: AssetImage(user.avatarAsset)),
                        title: Text(user.name),
                        trailing: IconButton(
                          icon: Icon(CupertinoIcons.xmark, size: 18, color: Colors.white.withOpacity(0.5)),
                          onPressed: () => setState(() => _selectedUsers.remove(userId)),
                        ),
                      ),
                    ),
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}

class CreateChannelScreen extends StatefulWidget {
  const CreateChannelScreen({super.key});

  @override
  State<CreateChannelScreen> createState() => _CreateChannelScreenState();
}

class _CreateChannelScreenState extends State<CreateChannelScreen> {
  final nameController = TextEditingController();
  final descriptionController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  File? _channelPhoto;

  @override
  void dispose() {
    nameController.dispose();
    descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: GlassIconButton(
          icon: CupertinoIcons.chevron_left,
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Новый канал'),
        actions: [
          TextButton(
            onPressed: nameController.text.isEmpty
                ? null
                : () async {
                    final chatStore = context.read<ChatStore>();
                    final contacts = chatStore.contacts;
                    if (contacts.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Добавьте участников для создания канала')),
                      );
                      return;
                    }
                    final chatId = await chatStore.createChat(
                      title: nameController.text.trim(),
                      isGroup: true, // Channels are treated as groups for now
                      participantIds: contacts.map((c) => c.id).toList(),
                      avatarAsset: _channelPhoto?.path ?? 'assets/images/avatar_placeholder.png',
                    );
                    if (!mounted) return;
                    Navigator.of(context).pop();
                    Navigator.pushNamed(context, AppRoutes.chat, arguments: {'chatId': chatId});
                  },
            child: Text('Создать', style: TextStyle(color: nameController.text.isEmpty
                ? Colors.white.withOpacity(0.3)
                : Theme.of(context).primaryColor)),
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
                  GestureDetector(
                    onTap: () async {
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
                                  final XFile? file = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
                                  if (file != null && mounted) {
                                    setState(() => _channelPhoto = File(file.path));
                                  }
                                } catch (e) {
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Ошибка выбора изображения: ${e.toString()}'),
                                        backgroundColor: Colors.redAccent,
                                      ),
                                    );
                                  }
                                }
                              },
                              child: const Text('Галерея'),
                            ),
                            CupertinoActionSheetAction(
                              onPressed: () async {
                                Navigator.of(context).pop();
                                try {
                                  final XFile? file = await _picker.pickImage(source: ImageSource.camera, imageQuality: 85);
                                  if (file != null && mounted) {
                                    setState(() => _channelPhoto = File(file.path));
                                  }
                                } catch (e) {
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Ошибка выбора изображения: ${e.toString()}'),
                                        backgroundColor: Colors.redAccent,
                                      ),
                                    );
                                  }
                                }
                              },
                              child: const Text('Камера'),
                            ),
                          ],
                          cancelButton: CupertinoActionSheetAction(
                            isDestructiveAction: false,
                            onPressed: () => Navigator.of(context).pop(),
                            child: const Text('Отмена'),
                          ),
                        ),
                      );
                    },
                    child: Stack(
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                          child: CircleAvatar(
                            radius: 50,
                            backgroundColor: Colors.white.withOpacity(0.1),
                            backgroundImage: _channelPhoto != null ? FileImage(_channelPhoto!) : null,
                            child: _channelPhoto == null
                                ? Icon(CupertinoIcons.camera_fill, size: 32, color: Colors.white.withOpacity(0.7))
                                : null,
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: const Color(0xFF0A0A0A), // Богатый черный вместо фиолетового
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.6),
                                  blurRadius: 12,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: CircleAvatar(
                              radius: 16,
                              backgroundColor: Colors.transparent,
                              child: const Icon(Icons.add, color: Colors.white, size: 20),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
            AnimateOnDisplay(
              delayMs: 100,
              child: GlassContainer(
                child: Column(
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        hintText: 'Название канала',
                        hintStyle: TextStyle(color: Colors.white54),
                      ),
                      style: const TextStyle(color: Colors.white),
                      onChanged: (_) => setState(() {}),
                    ),
                    const Divider(height: 1),
                    TextField(
                      controller: descriptionController,
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        hintText: 'Описание (необязательно)',
                        hintStyle: TextStyle(color: Colors.white54),
                      ),
                      style: const TextStyle(color: Colors.white),
                      maxLines: 3,
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
}

class _UserSelectionSheet extends StatefulWidget {
  final Set<String> selectedUsers;
  final Function(Set<String>) onSelectionChanged;
  const _UserSelectionSheet({required this.selectedUsers, required this.onSelectionChanged});

  @override
  State<_UserSelectionSheet> createState() => _UserSelectionSheetState();
}

class _UserSelectionSheetState extends State<_UserSelectionSheet> {
  late Set<String> _tempSelection;

  @override
  void initState() {
    super.initState();
    _tempSelection = Set.from(widget.selectedUsers);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Выберите участников (${_tempSelection.length})',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              TextButton(
                onPressed: () {
                  widget.onSelectionChanged(_tempSelection);
                  Navigator.of(context).pop();
                },
                child: Text('Готово', style: TextStyle(color: Theme.of(context).primaryColor)),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Flexible(
          child: Consumer<ChatStore>(
            builder: (context, chatStore, child) {
              return ListView.builder(
                shrinkWrap: true,
                itemCount: chatStore.contacts.length,
                itemBuilder: (context, index) {
                  final user = chatStore.contacts[index];
                  final isSelected = _tempSelection.contains(user.id);
                  return CheckboxListTile(
                    value: isSelected,
                    onChanged: (value) {
                      setState(() {
                        if (value == true) {
                          _tempSelection.add(user.id);
                        } else {
                          _tempSelection.remove(user.id);
                        }
                      });
                    },
                    title: Text(user.name),
                    secondary: CircleAvatar(backgroundImage: AssetImage(user.avatarAsset)),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
