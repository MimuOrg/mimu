import 'dart:ui';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:mimu/shared/glass_widgets.dart';
import 'package:mimu/shared/animated_widgets.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:flutter_animate/flutter_animate.dart';

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

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
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
                        icon: const Icon(PhosphorIconsBold.caretLeft),
                        onPressed: () => Navigator.of(context).pop(),
                        color: Colors.white,
                      ),
                      GlassIconButton(
                        icon: PhosphorIconsBold.dotsThreeVertical,
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
                const Spacer(),
                // Call controls
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 32),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildControlButton(
                        icon: _isMuted ? PhosphorIconsBold.microphoneSlash : PhosphorIconsBold.microphone,
                        onPressed: () => setState(() => _isMuted = !_isMuted),
                        color: Colors.white.withOpacity(0.2),
                      ),
                      _buildControlButton(
                        icon: _isSpeakerOn ? PhosphorIconsBold.speakerHigh : PhosphorIconsBold.speakerLow,
                        onPressed: () => setState(() => _isSpeakerOn = !_isSpeakerOn),
                        color: Colors.white.withOpacity(0.2),
                      ),
                      if (widget.isVideoCall)
                        _buildControlButton(
                          icon: _isVideoEnabled ? PhosphorIconsBold.videoCamera : PhosphorIconsBold.videoCameraSlash,
                          onPressed: () => setState(() => _isVideoEnabled = !_isVideoEnabled),
                          color: Colors.white.withOpacity(0.2),
                        ),
                      _buildControlButton(
                        icon: PhosphorIconsBold.dotsThree,
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
                            PhosphorIconsBold.phoneX,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                      ).animate().scale(delay: 500.ms, duration: 400.ms, curve: Curves.elasticOut),
                      const SizedBox(width: 32),
                      // Answer/Accept button
                      GestureDetector(
                        onTap: () {
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
                            PhosphorIconsBold.phone,
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

  void _showCallMenu(BuildContext context) {
    showGlassBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: Icon(PhosphorIconsBold.user, color: Theme.of(context).primaryColor),
            title: const Text('Информация о контакте'),
            onTap: () {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Информация о контакте')),
              );
            },
          ),
          const Divider(height: 1),
          ListTile(
            leading: Icon(PhosphorIconsBold.chatCircle, color: Theme.of(context).primaryColor),
            title: const Text('Написать сообщение'),
            onTap: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Открытие чата')),
              );
            },
          ),
          const Divider(height: 1),
          ListTile(
            leading: Icon(PhosphorIconsBold.phone, color: Theme.of(context).primaryColor),
            title: const Text('Повторный звонок'),
            onTap: () {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Повторный звонок')),
              );
            },
          ),
        ],
      ),
    );
  }
}

