import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:mimu/app/routes.dart';
import 'package:mimu/data/server_config.dart';
import 'package:mimu/data/user_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

/// Режим разработчика - скрытое меню
class DevModeScreen extends StatefulWidget {
  const DevModeScreen({super.key});

  @override
  State<DevModeScreen> createState() => _DevModeScreenState();
}

class _DevModeScreenState extends State<DevModeScreen> {
  String _logs = '';
  String? _fingerprint;
  String? _deviceId;
  String? _currentServer;
  PackageInfo? _packageInfo;

  @override
  void initState() {
    super.initState();
    _loadInfo();
  }

  Future<void> _loadInfo() async {
    _packageInfo = await PackageInfo.fromPlatform();
    _fingerprint = UserService.getFingerprint();
    _deviceId = UserService.getDeviceId();
    _currentServer = ServerConfig.getApiBaseUrl();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: const Text('Режим разработчика'),
        leading: CupertinoNavigationBarBackButton(
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildSection('Информация о приложении', [
              _buildInfoRow('Версия', _packageInfo?.version ?? 'N/A'),
              _buildInfoRow('Build', _packageInfo?.buildNumber ?? 'N/A'),
              _buildInfoRow('Package', _packageInfo?.packageName ?? 'N/A'),
            ]),
            _buildSection('Безопасность', [
              _buildInfoRow('Fingerprint', _fingerprint ?? 'N/A'),
              _buildInfoRow('Device ID', _deviceId ?? 'N/A'),
              _buildButton('Показать ключи', _showKeys),
            ]),
            _buildSection('Сеть', [
              _buildInfoRow('Сервер', _currentServer ?? 'N/A'),
              _buildButton('Переключить сервер', _switchServer),
              _buildButton('Показать статистику', () { _showNetworkStats(); }),
            ]),
            _buildSection('Отладка', [
              _buildButton('Показать логи', _showLogs),
              _buildButton('Копировать логи', _copyLogs),
              _buildButton('Очистить логи', _clearLogs),
            ]),
            _buildSection('Опасные действия', [
              _buildButton('Сбросить сессию', () { _resetSession(); }, isDestructive: true),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 24, bottom: 12),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
        ...children,
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: SelectableText(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildButton(String label, VoidCallback onPressed, {bool isDestructive = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: CupertinoButton(
        padding: EdgeInsets.zero,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isDestructive
                ? Colors.red.withOpacity(0.2)
                : Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: isDestructive ? Colors.red : Colors.white,
              fontSize: 14,
            ),
          ),
        ),
        onPressed: onPressed,
      ),
    );
  }

  void _showKeys() {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Ключи шифрования'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Fingerprint: ${_fingerprint ?? "N/A"}'),
              const SizedBox(height: 8),
              Text('Device ID: ${_deviceId ?? "N/A"}'),
            ],
          ),
        ),
        actions: [
          CupertinoDialogAction(
            child: const Text('OK'),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  void _switchServer() {
    showCupertinoDialog(
      context: context,
      builder: (context) {
        final servers = [
          'https://api.mimu.app',
          'https://dev-api.mimu.app',
          'http://localhost:3000',
        ];
        return CupertinoAlertDialog(
          title: const Text('Выберите сервер'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: servers.map((server) {
              return CupertinoButton(
                child: Text(server),
                onPressed: () async {
                  await ServerConfig.setApiBaseUrl(server);
                  setState(() {
                    _currentServer = server;
                  });
                  Navigator.of(context).pop();
                },
              );
            }).toList(),
          ),
          actions: [
            CupertinoDialogAction(
              child: const Text('Отмена'),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showNetworkStats() async {
    final server = ServerConfig.getApiBaseUrl();
    final result = await Connectivity().checkConnectivity();
    final connectStr = result is List
        ? (result as List).map((e) => e.toString().split('.').last).join(', ')
        : result.toString();
    if (!mounted) return;
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Сеть'),
        content: Padding(
          padding: const EdgeInsets.only(top: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Сервер: $server', style: const TextStyle(fontSize: 14)),
              const SizedBox(height: 8),
              Text('Подключение: $connectStr', style: const TextStyle(fontSize: 14)),
            ],
          ),
        ),
        actions: [
          CupertinoDialogAction(
            child: const Text('OK'),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  void _showLogs() {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Логи приложения'),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: SingleChildScrollView(
            child: SelectableText(
              _logs.isEmpty ? 'Логи пусты' : _logs,
              style: const TextStyle(fontSize: 12, color: Colors.white),
            ),
          ),
        ),
        actions: [
          CupertinoDialogAction(
            child: const Text('OK'),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  void _copyLogs() {
    Clipboard.setData(ClipboardData(text: _logs));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Логи скопированы в буфер обмена')),
    );
  }

  void _clearLogs() {
    setState(() {
      _logs = '';
    });
  }

  Future<void> _resetSession() async {
    final confirmed = await showCupertinoDialog<bool>(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Сбросить сессию?'),
        content: const Text(
          'Будут очищены токены и данные входа. Вы перейдёте на экран авторизации.',
        ),
        actions: [
          CupertinoDialogAction(
            child: const Text('Отмена'),
            onPressed: () => Navigator.of(context).pop(false),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            child: const Text('Сбросить'),
            onPressed: () => Navigator.of(context).pop(true),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await UserService.logout();
      if (!mounted) return;
      Navigator.of(context).pushNamedAndRemoveUntil(AppRoutes.auth, (route) => false);
    }
  }
}

