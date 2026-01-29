import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:mimu/data/user_api.dart';
import 'package:mimu/shared/glass_widgets.dart';

/// Экран "Устройства" — активные сессии, возможность завершить (кик)
class DevicesScreen extends StatefulWidget {
  const DevicesScreen({super.key});

  @override
  State<DevicesScreen> createState() => _DevicesScreenState();
}

class _DevicesScreenState extends State<DevicesScreen> {
  List<Map<String, dynamic>> _sessions = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final list = await UserApi().listSessions();
      if (mounted) {
        setState(() {
          _sessions = list;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  Future<void> _kick(String sessionId) async {
    try {
      await UserApi().kickSession(sessionId);
      if (mounted) {
        await _load();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Сессия завершена')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('Устройства'),
      ),
      child: SafeArea(
        child: _loading
            ? const Center(child: CupertinoActivityIndicator(radius: 14))
            : _error != null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _error!,
                            style: TextStyle(color: CupertinoColors.systemRed),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          CupertinoButton.filled(
                            onPressed: _load,
                            child: const Text('Повторить'),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: _sessions.length,
                    itemBuilder: (context, index) {
                      final s = _sessions[index];
                      final id = s['id']?.toString() ?? '';
                      final userAgent = s['user_agent'] as String? ?? 'Неизвестное устройство';
                      final ip = s['ip'] as String?;
                      final createdAt = s['created_at'] as String?;
                      final lastUsed = s['last_used_at'] as String?;
                      
                      // Определяем текущее устройство по user_agent (упрощенная версия)
                      final currentUserAgent = Platform.isAndroid 
                          ? 'Android' 
                          : Platform.isIOS 
                              ? 'iOS' 
                              : 'Unknown';
                      final isCurrentDevice = userAgent.contains(currentUserAgent) || 
                          (Platform.isAndroid && userAgent.toLowerCase().contains('android')) ||
                          (Platform.isIOS && (userAgent.toLowerCase().contains('iphone') || userAgent.toLowerCase().contains('ipad')));
                      
                      return GlassContainer(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        padding: const EdgeInsets.all(16),
                        decoration: isCurrentDevice 
                            ? BoxDecoration(
                                border: Border.all(
                                  color: CupertinoColors.activeGreen.withOpacity(0.5),
                                  width: 2,
                                ),
                                borderRadius: BorderRadius.circular(12),
                              )
                            : null,
                        child: Row(
                          children: [
                            Icon(
                              CupertinoIcons.device_phone_portrait,
                              size: 32,
                              color: isCurrentDevice 
                                  ? CupertinoColors.activeGreen 
                                  : CupertinoColors.systemGrey,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        userAgent.length > 50 ? '${userAgent.substring(0, 50)}...' : userAgent,
                                        style: const TextStyle(
                                          color: CupertinoColors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      if (isCurrentDevice) ...[
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: CupertinoColors.activeGreen,
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: const Text(
                                            'Это устройство',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                  if (ip != null && ip.isNotEmpty)
                                    Text(
                                      'IP: $ip',
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.6),
                                        fontSize: 13,
                                      ),
                                    ),
                                  if (lastUsed != null)
                                    Text(
                                      'Был: $lastUsed',
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.5),
                                        fontSize: 12,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            CupertinoButton(
                              padding: EdgeInsets.zero,
                              onPressed: () async {
                                final confirm = await showCupertinoDialog<bool>(
                                  context: context,
                                  builder: (ctx) => CupertinoAlertDialog(
                                    title: const Text('Завершить сессию?'),
                                    content: const Text(
                                      'Устройство будет отключено. Потребуется повторный вход.',
                                    ),
                                    actions: [
                                      CupertinoDialogAction(
                                        onPressed: () => Navigator.of(ctx).pop(false),
                                        child: const Text('Отмена'),
                                      ),
                                      CupertinoDialogAction(
                                        isDestructiveAction: true,
                                        onPressed: () => Navigator.of(ctx).pop(true),
                                        child: const Text('Завершить'),
                                      ),
                                    ],
                                  ),
                                );
                                if (confirm == true) await _kick(id);
                              },
                              child: Text(
                                'Завершить',
                                style: TextStyle(
                                  color: CupertinoColors.systemRed,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}
