import 'dart:ui';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:mimu/shared/glass_widgets.dart';
import 'package:mimu/shared/animated_widgets.dart';
import 'package:mimu/shared/cupertino_dialogs.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:permission_handler/permission_handler.dart';

class CallScreen extends StatefulWidget {
  final String userName;
  final String avatarAsset;
  final bool isIncoming;
  final bool isVideoCall;

  const CallScreen({
    super.key,
    required this.userName,
    required this.avatarAsset,
    this.isIncoming = false,
    this.isVideoCall = false,
  });

  @override
  State<CallScreen> createState() => _CallScreenState();
}

class _CallScreenState extends State<CallScreen> with SingleTickerProviderStateMixin {
  bool _isMuted = false;
  bool _isSpeakerOn = false;
  bool _isVideoEnabled = true;
  late AnimationController _pulseController;
  bool _microphoneGranted = false;
  bool _cameraGranted = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
    _precheckPermissions();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _precheckPermissions() async {
    // Запрос заранее, чтобы кнопки не казались сломанными
    _microphoneGranted = await _ensurePermission(Permission.microphone, silent: true);
    if (widget.isVideoCall) {
      _cameraGranted = await _ensurePermission(Permission.camera, silent: true);
    }
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // Background
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage("assets/images/background_pattern.png"),
                fit: BoxFit.cover,
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                // Top bar
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(CupertinoIcons.chevron_left),
                        onPressed: () => Navigator.of(context).pop(),
                        color: Colors.white,
                      ),
                      GlassIconButton(
                        icon: CupertinoIcons.ellipsis_vertical,
                        onPressed: () {
                          _showCallMenu(context);
                        },
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                // Avatar
                AnimatedBuilder(
                  animation: _pulseController,
                  builder: (context, child) {
                    return Container(
                      width: 180,
                      height: 180,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Theme.of(context).primaryColor.withOpacity(
                            0.3 + (_pulseController.value * 0.3),
                          ),
                          width: 3,
                        ),
                      ),
                      child: CircleAvatar(
                        radius: 87,
                        backgroundImage: _avatarProvider(),
                      ),
                    );
                  },
                ).animate().scale(delay: 200.ms, duration: 600.ms, curve: Curves.elasticOut),
                const SizedBox(height: 24),
                // Name
                Text(
                  widget.userName,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ).animate().fadeIn(delay: 300.ms),
                const SizedBox(height: 8),
                Text(
                  widget.isVideoCall ? 'Видеозвонок через Mimu' : 'Звонок через Mimu',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.7),
                  ),
                ).animate().fadeIn(delay: 400.ms),
                if (widget.isVideoCall)
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: GlassContainer(
                      padding: const EdgeInsets.all(12),
                      child: SizedBox(
                        height: 160,
                        child: Center(
                          child: _isVideoEnabled && _cameraGranted
                              ? Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: const [
                                    Icon(CupertinoIcons.videocam_circle_fill, size: 42, color: Colors.white70),
                                    SizedBox(height: 8),
                                    Text('Превью камеры активно', style: TextStyle(color: Colors.white70)),
                                  ],
                                )
                              : Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(CupertinoIcons.videocam_fill, size: 38, color: Colors.white54),
                                    const SizedBox(height: 8),
                                    Text(
                                      _cameraGranted ? 'Видео выключено' : 'Нет доступа к камере',
                                      style: const TextStyle(color: Colors.white60),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                    ),
                  ),
                const Spacer(),
                // Call controls
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 32),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildControlButton(
                        icon: _isMuted ? CupertinoIcons.mic_slash_fill : CupertinoIcons.mic_fill,
                        onPressed: _toggleMic,
                        color: Colors.white.withOpacity(0.2),
                      ),
                      _buildControlButton(
                        icon: _isSpeakerOn ? CupertinoIcons.speaker_2_fill : CupertinoIcons.speaker_1_fill,
                        onPressed: _toggleSpeaker,
                        color: Colors.white.withOpacity(0.2),
                      ),
                      if (widget.isVideoCall)
                        _buildControlButton(
                          icon: _isVideoEnabled ? CupertinoIcons.videocam_fill : CupertinoIcons.videocam,
                          onPressed: _toggleVideo,
                          color: Colors.white.withOpacity(0.2),
                        ),
                      _buildControlButton(
                        icon: CupertinoIcons.ellipsis,
                        onPressed: () {
                          _showCallMenu(context);
                        },
                        color: Colors.white.withOpacity(0.2),
                      ),
                    ],
                  ),
                ),
                // Main call buttons
                Padding(
                  padding: const EdgeInsets.only(bottom: 32),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Decline/End button
                      GestureDetector(
                        onTap: () => Navigator.of(context).pop(),
                        child: Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.redAccent,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.redAccent.withOpacity(0.4),
                                blurRadius: 20,
                                spreadRadius: 4,
                              ),
                            ],
                          ),
                          child: const Icon(
                            CupertinoIcons.phone_down_fill,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                      ).animate().scale(delay: 500.ms, duration: 400.ms, curve: Curves.elasticOut),
                      const SizedBox(width: 32),
                      // Answer/Accept button
                      GestureDetector(
                        onTap: () async {
                          if (!_microphoneGranted) {
                            _microphoneGranted = await _ensurePermission(Permission.microphone);
                          }
                          if (widget.isVideoCall && !_cameraGranted) {
                            _cameraGranted = await _ensurePermission(Permission.camera);
                          }
                          if (!mounted) return;
                          Navigator.of(context).pop(true);
                        },
                        child: Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Theme.of(context).primaryColor,
                            boxShadow: [
                              BoxShadow(
                                color: Theme.of(context).primaryColor.withOpacity(0.4),
                                blurRadius: 20,
                                spreadRadius: 4,
                              ),
                            ],
                          ),
                          child: const Icon(
                            CupertinoIcons.phone_fill,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                      ).animate().scale(delay: 600.ms, duration: 400.ms, curve: Curves.elasticOut),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required VoidCallback onPressed,
    required Color color,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onPressed,
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Icon(icon, color: Colors.white, size: 22),
        ),
      ),
    ).animate()
      .scale(delay: 100.ms, duration: 200.ms, curve: Curves.elasticOut);
  }

  ImageProvider _avatarProvider() {
    if (widget.avatarAsset.startsWith('assets/')) {
      return AssetImage(widget.avatarAsset);
    }
    final file = File(widget.avatarAsset);
    if (file.existsSync()) {
      return FileImage(file);
    }
    return const AssetImage('assets/images/avatar_placeholder.png');
  }

  Future<bool> _ensurePermission(Permission permission, {bool silent = false}) async {
    final status = await permission.request();
    final granted = status == PermissionStatus.granted || status == PermissionStatus.limited;
    if (!granted && !silent && mounted) {
      String permissionName = 'разрешение';
      if (permission == Permission.microphone) {
        permissionName = 'доступ к микрофону';
      } else if (permission == Permission.camera) {
        permissionName = 'доступ к камере';
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Нужен $permissionName для работы функции. Откройте настройки, чтобы предоставить доступ.'),
          duration: const Duration(seconds: 4),
          backgroundColor: Colors.orangeAccent,
          action: SnackBarAction(
            label: 'Настройки',
            textColor: Colors.white,
            onPressed: () async {
              await openAppSettings();
            },
          ),
        ),
      );
    }
    return granted;
  }

  Future<void> _toggleMic() async {
    if (!_microphoneGranted) {
      _microphoneGranted = await _ensurePermission(Permission.microphone);
      if (!_microphoneGranted) return;
    }
    setState(() => _isMuted = !_isMuted);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(_isMuted ? 'Микрофон выключен' : 'Микрофон включен')),
    );
  }

  Future<void> _toggleSpeaker() async {
    setState(() => _isSpeakerOn = !_isSpeakerOn);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(_isSpeakerOn ? 'Громкая связь включена' : 'Громкая связь выключена')),
    );
  }

  Future<void> _toggleVideo() async {
    if (!_cameraGranted) {
      _cameraGranted = await _ensurePermission(Permission.camera);
      if (!_cameraGranted) {
        setState(() => _isVideoEnabled = false);
        return;
      }
    }
    setState(() => _isVideoEnabled = !_isVideoEnabled);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isVideoEnabled ? 'Видео включено' : 'Видео выключено'),
          duration: const Duration(seconds: 1),
        ),
      );
    }
  }

  void _showCallMenu(BuildContext context) {
    showCupertinoModalPopup(
      context: context,
      filter: ImageFilter.blur(sigmaX: 0.5, sigmaY: 0.5),
      builder: (context) => buildCupertinoActionSheet(
        context: context,
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Информация о контакте')),
              );
            },
            child: const Text('Информация о контакте'),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Открытие чата')),
              );
            },
            child: const Text('Написать сообщение'),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Повторный звонок')),
              );
            },
            child: const Text('Повторный звонок'),
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
}

