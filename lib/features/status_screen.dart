import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:mimu/shared/glass_widgets.dart';
import 'package:mimu/shared/animated_widgets.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:mimu/data/user_service.dart';
import 'package:mimu/data/status_service.dart';
import 'package:mimu/data/settings_service.dart';
import 'package:mimu/app/theme.dart';
import 'package:mimu/shared/cupertino_dialogs.dart';
import 'package:path_provider/path_provider.dart';
import 'package:mimu/shared/app_styles.dart';

class StatusScreen extends StatefulWidget {
  const StatusScreen({super.key});

  @override
  State<StatusScreen> createState() => _StatusScreenState();
}

class _StatusScreenState extends State<StatusScreen> {
  final ImagePicker _picker = ImagePicker();
  List<Map<String, dynamic>> _statuses = [];
  String _privacy = 'Все';

  @override
  void initState() {
    super.initState();
    _loadStatuses();
  }

  Future<void> _loadStatuses() async {
    await StatusService.init();
    final statuses = await StatusService.getStatuses();
    final privacy = await StatusService.getStatusPrivacy();
    setState(() {
      _statuses = statuses;
      _privacy = privacy;
    });
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
          icon: const Icon(CupertinoIcons.chevron_left),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Статусы',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontFamily: AppStyles.fontFamily,
            letterSpacing: AppStyles.letterSpacingSignature,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(CupertinoIcons.camera_fill),
            onPressed: _addStatus,
          ),
          IconButton(
            icon: const Icon(CupertinoIcons.ellipsis_vertical),
            onPressed: _showStatusMenu,
          ),
        ],
      ),
      body: Container(
        color: AppStyles.backgroundOled,
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
                          FutureBuilder<Map<String, dynamic>?>(
                            future: StatusService.getMyStatus(),
                            builder: (context, snapshot) {
                              final myStatus = snapshot.data;
                              ImageProvider? imageProvider;
                              if (myStatus != null && myStatus['imagePath'] != null) {
                                final file = File(myStatus['imagePath'] as String);
                                imageProvider = file.existsSync() 
                                    ? FileImage(file) as ImageProvider
                                    : const AssetImage('assets/images/avatar_placeholder.png');
                              } else if (myStatus != null && myStatus['avatar'] != null) {
                                final avatar = myStatus['avatar'].toString();
                                imageProvider = avatar.startsWith('assets/')
                                    ? AssetImage(avatar)
                                    : (File(avatar).existsSync() 
                                        ? FileImage(File(avatar)) as ImageProvider
                                        : const AssetImage('assets/images/avatar_placeholder.png'));
                              } else {
                                imageProvider = const AssetImage('assets/images/avatar_placeholder.png');
                              }
                              return CircleAvatar(
                                radius: 30,
                                backgroundImage: imageProvider,
                              );
                            },
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
                              child: const Icon(CupertinoIcons.add, size: 16, color: Colors.white),
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
                            FutureBuilder<Map<String, dynamic>?>(
                              future: StatusService.getMyStatus(),
                              builder: (context, snapshot) {
                                final myStatus = snapshot.data;
                                return Text(
                                  myStatus != null ? 'Нажмите, чтобы обновить' : 'Нажмите, чтобы добавить статус',
                                  style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.6)),
                                );
                              },
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
              ..._statuses.where((s) => s['isMe'] != true).map((status) {
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
                                _viewStatus(status);
                              },
                              child: ListTile(
                                contentPadding: EdgeInsets.zero,
                                leading: Stack(
                                  children: [
                                    CircleAvatar(
                                      radius: 24,
                                      backgroundImage: () {
                                        if (status['imagePath'] != null) {
                                          final file = File(status['imagePath'] as String);
                                          return file.existsSync() 
                                              ? FileImage(file) as ImageProvider
                                              : const AssetImage('assets/images/avatar_placeholder.png');
                                        }
                                        if (status['avatar'] != null) {
                                          final avatar = status['avatar'].toString();
                                          return avatar.startsWith('assets/')
                                              ? AssetImage(avatar)
                                              : (File(avatar).existsSync() 
                                                  ? FileImage(File(avatar)) as ImageProvider
                                                  : const AssetImage('assets/images/avatar_placeholder.png'));
                                        }
                                        return const AssetImage('assets/images/avatar_placeholder.png');
                                      }(),
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
                                trailing: Icon(CupertinoIcons.chevron_right, color: Colors.white.withOpacity(0.5)),
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

  Future<void> _addStatus() async {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => buildCupertinoActionSheet(
        context: context,
        actions: [
          CupertinoActionSheetAction(
            onPressed: () async {
              Navigator.of(context).pop();
              final file = await _picker.pickImage(source: ImageSource.camera);
              if (file != null) {
                await _saveStatus(file.path);
              }
            },
            child: const Text('Фото'),
          ),
          CupertinoActionSheetAction(
            onPressed: () async {
              Navigator.of(context).pop();
              final file = await _picker.pickImage(source: ImageSource.gallery);
              if (file != null) {
                await _saveStatus(file.path);
              }
            },
            child: const Text('Из галереи'),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          isDestructiveAction: false,
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Отмена'),
        ),
      ),
    );
  }

  Future<void> _saveStatus(String imagePath) async {
    if (!mounted) return;
    
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
                  'Сохранение статуса...',
                  style: TextStyle(color: Colors.white.withOpacity(0.9)),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      // Копируем файл в постоянное хранилище
      final appDir = await getApplicationDocumentsDirectory();
      final statusDir = Directory('${appDir.path}/statuses');
      if (!await statusDir.exists()) {
        await statusDir.create(recursive: true);
      }
      final fileName = 'status_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final savedFile = File('${statusDir.path}/$fileName');
      await File(imagePath).copy(savedFile.path);
      
      await StatusService.addStatus(savedFile.path, isMe: true);
      await _loadStatuses();
      if (mounted) {
        Navigator.of(context).pop(); // Закрываем индикатор прогресса
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Статус добавлен')),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop(); // Закрываем индикатор прогресса
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка: $e')),
        );
      }
    }
  }

  void _showStatusMenu() {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => buildCupertinoActionSheet(
        context: context,
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.of(context).pop();
              _showPrivacySettings();
            },
            child: const Text('Конфиденциальность'),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          isDestructiveAction: false,
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Отмена'),
        ),
      ),
    );
  }

  void _showPrivacySettings() {
    final options = ['Все', 'Только контакты', 'Никто'];
    showCupertinoModalPopup(
      context: context,
      builder: (context) => buildCupertinoActionSheet(
        context: context,
        title: 'Кто может видеть мои статусы',
        actions: options.map((option) {
          return CupertinoActionSheetAction(
            onPressed: () async {
              await StatusService.setStatusPrivacy(option);
              setState(() => _privacy = option);
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Приватность: $option')),
              );
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(option),
                if (_privacy == option)
                  Icon(CupertinoIcons.check_mark, color: Theme.of(context).primaryColor),
              ],
            ),
          );
        }).toList(),
        cancelButton: CupertinoActionSheetAction(
          isDestructiveAction: false,
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Отмена'),
        ),
      ),
    );
  }

  void _viewStatus(Map<String, dynamic> status) {
    if (status['imagePath'] == null) return;
    showCupertinoDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => Scaffold(
        backgroundColor: AppStyles.backgroundOled,
        body: SafeArea(
          child: Stack(
            children: [
              Center(
                child: Image.file(
                  File(status['imagePath'] as String),
                  fit: BoxFit.contain,
                ),
              ),
              Positioned(
                top: 16,
                left: 16,
                child: IconButton(
                  icon: const Icon(CupertinoIcons.xmark, color: Colors.white),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
              if (status['isMe'] == true)
                Positioned(
                  bottom: 16,
                  right: 16,
                  child: IconButton(
                    icon: const Icon(CupertinoIcons.delete, color: Colors.red),
                    onPressed: () async {
                      await StatusService.deleteStatus(status['id'] as String);
                      Navigator.of(context).pop();
                      await _loadStatuses();
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

