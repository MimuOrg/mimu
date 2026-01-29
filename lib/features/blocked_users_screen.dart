import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:mimu/data/user_api.dart';
import 'package:mimu/shared/glass_widgets.dart';

/// Экран "Заблокированные" — список заблокированных пользователей
class BlockedUsersScreen extends StatefulWidget {
  const BlockedUsersScreen({super.key});

  @override
  State<BlockedUsersScreen> createState() => _BlockedUsersScreenState();
}

class _BlockedUsersScreenState extends State<BlockedUsersScreen> {
  List<Map<String, dynamic>> _blocked = [];
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
      final list = await UserApi().listBlocked();
      if (mounted) {
        setState(() {
          _blocked = list;
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

  Future<void> _unblock(String identifier) async {
    try {
      await UserApi().unblockUser(identifier);
      if (mounted) {
        await _load();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Пользователь разблокирован')),
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
        middle: Text('Заблокированные'),
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
                : _blocked.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              CupertinoIcons.person_crop_circle_badge_xmark,
                              size: 64,
                              color: Colors.white.withOpacity(0.3),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Нет заблокированных',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.6),
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemCount: _blocked.length,
                        itemBuilder: (context, index) {
                          final user = _blocked[index];
                          final publicId = user['public_id']?.toString() ?? '';
                          final displayName = user['display_name'] as String?;
                          final avatarUrl = user['avatar_url'] as String?;
                          final blockedAt = user['blocked_at'] as String?;
                          return GlassContainer(
                            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 24,
                                  backgroundImage: avatarUrl != null && avatarUrl.isNotEmpty
                                      ? NetworkImage(avatarUrl)
                                      : null,
                                  child: avatarUrl == null || avatarUrl.isEmpty
                                      ? Text(
                                          (displayName?.isNotEmpty == true
                                                  ? displayName![0]
                                                  : publicId.isNotEmpty
                                                      ? publicId[0]
                                                      : '?')
                                              .toUpperCase(),
                                          style: const TextStyle(color: Colors.white),
                                        )
                                      : null,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        displayName ?? publicId,
                                        style: const TextStyle(
                                          color: CupertinoColors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      if (publicId.isNotEmpty && displayName != null)
                                        Text(
                                          publicId,
                                          style: TextStyle(
                                            color: Colors.white.withOpacity(0.6),
                                            fontSize: 13,
                                          ),
                                        ),
                                      if (blockedAt != null)
                                        Text(
                                          'Заблокирован: $blockedAt',
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
                                        title: const Text('Разблокировать?'),
                                        content: Text(
                                          'Пользователь ${displayName ?? publicId} будет разблокирован.',
                                        ),
                                        actions: [
                                          CupertinoDialogAction(
                                            onPressed: () => Navigator.of(ctx).pop(false),
                                            child: const Text('Отмена'),
                                          ),
                                          CupertinoDialogAction(
                                            isDefaultAction: true,
                                            onPressed: () => Navigator.of(ctx).pop(true),
                                            child: const Text('Разблокировать'),
                                          ),
                                        ],
                                      ),
                                    );
                                    if (confirm == true) await _unblock(publicId);
                                  },
                                  child: Text(
                                    'Разблокировать',
                                    style: TextStyle(
                                      color: CupertinoColors.activeGreen,
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
