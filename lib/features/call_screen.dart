import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:mimu/shared/app_styles.dart';
import 'package:mimu/shared/glass_widgets.dart';
import 'package:mimu/shared/animated_widgets.dart';
import 'package:mimu/shared/cupertino_dialogs.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:mimu/features/calls/call_controller.dart';

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
  
  final _callController = CallController();

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
    _precheckPermissions();
    _isVideoEnabled = widget.isVideoCall;
    
    // Listen for remote stream updates to refresh UI
    _callController.webrtc.onRemoteStream = (stream) {
      if (mounted) setState(() {});
    };
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _precheckPermissions() async {
    _microphoneGranted = await _ensurePermission(Permission.microphone, silent: true);
    if (widget.isVideoCall) {
      _cameraGranted = await _ensurePermission(Permission.camera, silent: true);
    }
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppStyles.backgroundOled,
      body: Stack(
        children: [
          // Background / Remote Video
          if (widget.isVideoCall && _callController.webrtc.remoteRenderer.srcObject != null)
            Positioned.fill(
              child: RTCVideoView(
                _callController.webrtc.remoteRenderer,
                objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
              ),
            )
          else
            Positioned.fill(
              child: Container(
                color: AppStyles.backgroundOled,
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
                      GlassIconButton(
                        icon: CupertinoIcons.chevron_down,
                        onPressed: () {
                          // Minimize call (just pop, call continues)
                          Navigator.of(context).pop(); 
                        },
                      ),
                      if (widget.isVideoCall)
                         GlassIconButton(
                           icon: CupertinoIcons.camera_rotate,
                           onPressed: _switchCamera,
                         ),
                    ],
                  ),
                ),
                
                // Content (Avatar or Spacer)
                if (!widget.isVideoCall || _callController.webrtc.remoteRenderer.srcObject == null) ...[
                  const Spacer(),
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
                  ),
                  const SizedBox(height: 24),
                  Text(
                    widget.userName,
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      fontFamily: AppStyles.fontFamily,
                      letterSpacing: AppStyles.letterSpacingSignature,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Mimu Audio Call',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white.withOpacity(0.8),
                      fontFamily: AppStyles.fontFamily,
                    ),
                  ),
                  const Spacer(),
                ] else 
                  const Spacer(),

                // Local Video (PIP)
                if (widget.isVideoCall && _isVideoEnabled && _callController.webrtc.localRenderer.srcObject != null)
                  Align(
                    alignment: Alignment.centerRight,
                    child: Padding(
                      padding: const EdgeInsets.only(right: 16, bottom: 16),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(18),
                        child: SizedBox(
                          width: 120,
                          height: 160,
                          child: RTCVideoView(
                            _callController.webrtc.localRenderer,
                            mirror: true,
                            objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                          ),
                        ),
                      ),
                    ),
                  ),

                // Controls
                GlassContainer(
                  margin: const EdgeInsets.all(24),
                  padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildControlButton(
                            icon: _isMuted ? CupertinoIcons.mic_slash_fill : CupertinoIcons.mic_fill,
                            onPressed: _toggleMic,
                            color: _isMuted ? Colors.white : AppStyles.surfaceDeep,
                            iconColor: _isMuted ? Colors.black : Colors.white,
                          ),
                          _buildControlButton(
                            icon: _isSpeakerOn ? CupertinoIcons.speaker_2_fill : CupertinoIcons.speaker_1_fill,
                            onPressed: _toggleSpeaker,
                            color: _isSpeakerOn ? Colors.white : AppStyles.surfaceDeep,
                            iconColor: _isSpeakerOn ? Colors.black : Colors.white,
                          ),
                          if (widget.isVideoCall)
                            _buildControlButton(
                              icon: _isVideoEnabled ? CupertinoIcons.videocam_fill : CupertinoIcons.video_camera_solid,
                              onPressed: _toggleVideo,
                              color: _isVideoEnabled ? AppStyles.surfaceDeep : Colors.white,
                              iconColor: _isVideoEnabled ? Colors.white : Colors.black,
                            ),
                          _buildControlButton(
                            icon: CupertinoIcons.phone_down_fill,
                            onPressed: _endCall,
                            color: Colors.redAccent,
                            iconColor: Colors.white,
                            size: 64,
                          ),
                        ],
                      ),
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
    required Color iconColor,
    double size = 48,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color,
        ),
        child: Icon(icon, color: iconColor, size: size * 0.5),
      ),
    );
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
    return status == PermissionStatus.granted || status == PermissionStatus.limited;
  }

  Future<void> _toggleMic() async {
    if (!_microphoneGranted) {
      _microphoneGranted = await _ensurePermission(Permission.microphone);
      if (!_microphoneGranted) return;
    }
    setState(() => _isMuted = !_isMuted);
    await _callController.webrtc.setMicrophoneMute(_isMuted);
  }

  Future<void> _toggleSpeaker() async {
    setState(() => _isSpeakerOn = !_isSpeakerOn);
    await _callController.webrtc.setSpeakerphoneOn(_isSpeakerOn);
  }

  Future<void> _toggleVideo() async {
    if (!_cameraGranted) {
      _cameraGranted = await _ensurePermission(Permission.camera);
      if (!_cameraGranted) return;
    }
    setState(() => _isVideoEnabled = !_isVideoEnabled);
    await _callController.webrtc.setVideoEnabled(_isVideoEnabled);
  }
  
  Future<void> _switchCamera() async {
     await _callController.webrtc.switchCamera();
  }
  
  Future<void> _endCall() async {
    // Hangup current call
    // We assume currentCallId is stored in WebRTCService, but hangup needs args.
    // CallController tracks peers.
    // For simplicity, we can use CallKit's endAll or webrtc.dispose.
    // Better to use CallKitService onEnd logic which triggers hangup.
    await _callController.callKit.endAll(); 
    if (mounted) Navigator.of(context).pop();
  }
}
