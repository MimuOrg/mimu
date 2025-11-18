import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:mimu/shared/glass_widgets.dart';
import 'package:mimu/shared/animated_widgets.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:mimu/data/user_service.dart';
import 'package:mimu/app/theme.dart';

class StatusScreen extends StatefulWidget {
  const StatusScreen({super.key});

  @override
  State<StatusScreen> createState() => _StatusScreenState();
}

class _StatusScreenState extends State<StatusScreen> {
  final ImagePicker _picker = ImagePicker();
  List<Map<String, dynamic>> _statuses = [];

  @override
  void initState() {
    super.initState();
    _loadStatuses();
  }

  void _loadStatuses() {
    setState(() {
      _statuses = [
        {
          'id': '1',
          'name': 'Мой статус',
          'avatar': UserService.getAvatarPath(),
          'time': 'Сейчас',
          'isMe': true,
        },
        {
          'id': '2',
          'name': 'Друг',
          'avatar': 'assets/images/avatar_placeholder.png',
          'time': '5 минут назад',
          'isMe': false,
        },
      ];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(PhosphorIconsBold.caretLeft),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Статусы'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(PhosphorIconsBold.camera),
            onPressed: _addStatus,
          ),
          IconButton(
            icon: const Icon(PhosphorIconsBold.dotsThreeVertical),
            onPressed: _showStatusMenu,
          ),
        ],
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
                child: GlassContainer(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Stack(
                        children: [
                          CircleAvatar(
                            radius: 30,
                            backgroundImage: _statuses.isNotEmpty && _statuses[0]['avatar'] != null
                                ? (_statuses[0]['avatar'].toString().startsWith('assets/')
                                    ? AssetImage(_statuses[0]['avatar'])
                                    : FileImage(_statuses[0]['avatar']) as ImageProvider)
                                : const AssetImage('assets/images/avatar_placeholder.png'),
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Theme.of(context).primaryColor,
                                border: Border.all(color: Colors.black, width: 2),
                              ),
                              child: const Icon(PhosphorIconsBold.plus, size: 16, color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Мой статус', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            Text(
                              'Нажмите, чтобы добавить статус',
                              style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.6)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              AnimateOnDisplay(
                delayMs: 100,
                child: Text(
                  'Недавние обновления',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white.withOpacity(0.7)),
                ),
              ),
              const SizedBox(height: 12),
              ..._statuses.where((s) => !s['isMe']).map((status) {
                    final index = _statuses.indexOf(status);
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: AnimateOnDisplay(
                        delayMs: 150 + (index * 50),
                        child: GlassContainer(
                          padding: const EdgeInsets.all(12),
                          decoration: Theme.of(context).extension<GlassTheme>()!.baseGlass.copyWith(
                            color: Theme.of(context).primaryColor.withOpacity(0.12),
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(15),
                              onTap: () {
                                // Открыть просмотр статуса
                              },
                              child: ListTile(
                                contentPadding: EdgeInsets.zero,
                                leading: Stack(
                                  children: [
                                    CircleAvatar(
                                      radius: 24,
                                      backgroundImage: status['avatar'].toString().startsWith('assets/')
                                          ? AssetImage(status['avatar'])
                                          : const AssetImage('assets/images/avatar_placeholder.png'),
                                    ),
                                    Positioned(
                                      bottom: 0,
                                      right: 0,
                                      child: Container(
                                        width: 16,
                                        height: 16,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: Colors.green,
                                          border: Border.all(color: Colors.black, width: 2),
                                        ),
                                      )
                                        .animate(onPlay: (controller) => controller.repeat())
                                        .scale(begin: const Offset(1.0, 1.0), end: const Offset(1.15, 1.15), duration: const Duration(milliseconds: 1000), curve: Curves.easeInOut)
                                        .then()
                                        .scale(begin: const Offset(1.15, 1.15), end: const Offset(1.0, 1.0), duration: const Duration(milliseconds: 1000), curve: Curves.easeInOut),
                                    ),
                                  ],
                                ),
                                title: Text(
                                  status['name'],
                                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                                ),
                                subtitle: Text(
                                  status['time'],
                                  style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 12),
                                ),
                                trailing: Icon(PhosphorIconsBold.caretRight, color: Colors.white.withOpacity(0.5)),
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
            ],
          ),
        ),
      ),
    );
  }

  void _addStatus() {
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
                leading: const Icon(PhosphorIconsBold.camera),
                title: const Text('Фото'),
                onTap: () async {
                  Navigator.of(context).pop();
                  final file = await _picker.pickImage(source: ImageSource.camera);
                  if (file != null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Статус добавлен')),
                    );
                  }
                },
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(PhosphorIconsBold.images),
                title: const Text('Из галереи'),
                onTap: () async {
                  Navigator.of(context).pop();
                  final file = await _picker.pickImage(source: ImageSource.gallery);
                  if (file != null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Статус добавлен')),
                    );
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showStatusMenu() {
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
                leading: Icon(PhosphorIconsBold.gear, color: Theme.of(context).primaryColor),
                title: const Text('Настройки статусов'),
                onTap: () {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Настройки статусов')),
                  );
                },
              ),
              const Divider(height: 1),
              ListTile(
                leading: Icon(PhosphorIconsBold.lock, color: Theme.of(context).primaryColor),
                title: const Text('Конфиденциальность'),
                onTap: () {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Настройки конфиденциальности')),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

