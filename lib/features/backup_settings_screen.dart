import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:mimu/data/backup_service.dart';
import 'package:mimu/data/services/crypto_auth_service.dart';
import 'package:mimu/shared/app_styles.dart';
import 'package:mimu/shared/glass_widgets.dart';

class BackupSettingsScreen extends StatefulWidget {
  const BackupSettingsScreen({super.key});

  @override
  State<BackupSettingsScreen> createState() => _BackupSettingsScreenState();
}

class _BackupSettingsScreenState extends State<BackupSettingsScreen> {
  bool _isLoading = false;
  String? _lastBackupPath;

  @override
  Widget build(BuildContext context) {
    final mnemonic = CryptoAuthService().currentMnemonic;
    final hasMnemonic = mnemonic != null;

    return Scaffold(
      backgroundColor: AppStyles.backgroundOled,
      appBar: AppBar(
        backgroundColor: AppStyles.backgroundOled,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: GlassIconButton(
          icon: CupertinoIcons.chevron_left,
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Бэкап и Безопасность',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontFamily: AppStyles.fontFamily,
            letterSpacing: AppStyles.letterSpacingSignature,
          ),
        ),
        centerTitle: true,
      ),
      body: Container(
        color: AppStyles.backgroundOled,
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (hasMnemonic) ...[
                const _SectionHeader(title: 'Фраза восстановления'),
                const SizedBox(height: 8),
                GlassContainer(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Ваша фраза восстановления (12 слов) — единственный способ восстановить доступ к аккаунту и сообщениям на новом устройстве.',
                        style: TextStyle(color: Colors.white70),
                      ),
                      const SizedBox(height: 16),
                      GlassButton(
                        onPressed: () => _showMnemonicDialog(context, mnemonic),
                        child: const Center(
                          child: Text('Показать фразу'),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],

              const _SectionHeader(title: 'Резервное копирование чатов'),
              const SizedBox(height: 8),
              GlassContainer(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const Text(
                      'Создайте локальную копию всех ваших чатов и настроек. Вы можете сохранить файл или отправить его себе.',
                      style: TextStyle(color: Colors.white70),
                    ),
                    const SizedBox(height: 16),
                    GlassButton(
                      onPressed: _isLoading ? null : _createBackup,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (_isLoading)
                            const Padding(
                              padding: EdgeInsets.only(right: 8.0),
                              child: CupertinoActivityIndicator(color: Colors.white),
                            )
                          else
                            const Icon(CupertinoIcons.arrow_down_doc, color: Colors.white),
                          const SizedBox(width: 8),
                          const Text('Создать резервную копию'),
                        ],
                      ),
                    ),
                    if (_lastBackupPath != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        'Последний бэкап: ${_lastBackupPath!.split('/').last}',
                        style: const TextStyle(fontSize: 12, color: Colors.greenAccent),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 24),
              const _SectionHeader(title: 'Восстановление'),
              const SizedBox(height: 8),
              GlassContainer(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const Text(
                      'Восстановите чаты из ранее созданного файла резервной копии (.mimu).',
                      style: TextStyle(color: Colors.white70),
                    ),
                    const SizedBox(height: 16),
                    GlassButton(
                      onPressed: _isLoading ? null : _restoreBackup,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(CupertinoIcons.arrow_up_doc, color: Colors.white),
                          SizedBox(width: 8),
                          Text('Восстановить из файла'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showMnemonicDialog(BuildContext context, String mnemonic) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withOpacity(0.7),
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: Container(
          decoration: AppStyles.surfaceDecoration(),
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Фраза восстановления',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  fontFamily: AppStyles.fontFamily,
                  letterSpacing: AppStyles.letterSpacingSignature,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Text(
                'Запишите эти слова в надежном месте. Никогда не передавайте их третьим лицам.',
                style: TextStyle(color: Colors.white.withOpacity(0.75), fontSize: 13),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: AppStyles.surfaceDecoration(borderRadius: 18),
                child: SelectableText(
                  mnemonic,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: GlassButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      child: const Center(child: Text('Закрыть')),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GlassButton(
                      onPressed: () async {
                        await Clipboard.setData(ClipboardData(text: mnemonic));
                        if (context.mounted) {
                          Navigator.of(ctx).pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Фраза скопирована')),
                          );
                        }
                      },
                      child: const Center(child: Text('Копировать')),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _createBackup() async {
    setState(() => _isLoading = true);
    try {
      // Можно запросить пароль для шифрования
      final password = await _askForPassword(context, isEncryption: true);
      if (password == null) {
        setState(() => _isLoading = false);
        return; // Отмена
      }

      final file = await BackupService.createBackup(password: password.isEmpty ? null : password);
      
      setState(() {
        _lastBackupPath = file.path;
      });

      if (mounted) {
        // Предложить поделиться файлом
        await Share.shareXFiles([XFile(file.path)], text: 'Mimu Backup');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка создания бэкапа: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _restoreBackup() async {
    try {
      final result = await FilePicker.platform.pickFiles();
      if (result == null || result.files.isEmpty) return;

      final path = result.files.single.path;
      if (path == null) return;

      setState(() => _isLoading = true);

      // Запрашиваем пароль
      final password = await _askForPassword(context, isEncryption: false);
      // Если пользователь нажал отмена, вернется null. Если пустой ввод - пустая строка.
      // Если файл не зашифрован, пароль не нужен (null или empty).
      // Логика сервиса: password != null -> decrypt.
      // Нам нужно знать, зашифрован ли файл? BackupService.verifyBackup проверяет JSON.
      // Если verify не проходит, возможно он зашифрован.
      
      // Попробуем восстановить
      final success = await BackupService.restoreBackup(
        File(path),
        password: (password != null && password.isNotEmpty) ? password : null,
      );

      if (mounted) {
        if (success) {
          showCupertinoDialog(
            context: context,
            builder: (ctx) => CupertinoAlertDialog(
              title: const Text('Успешно'),
              content: const Text('Данные восстановлены. Приложение будет перезагружено для применения изменений.'),
              actions: [
                CupertinoDialogAction(
                  child: const Text('OK'),
                  onPressed: () {
                    Navigator.pop(ctx);
                    // Тут можно сделать рестарт или навигацию на Home
                    Navigator.of(context).pushNamedAndRemoveUntil('/home', (r) => false);
                  },
                ),
              ],
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Не удалось восстановить бэкап. Проверьте пароль или целостность файла.')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<String?> _askForPassword(BuildContext context, {required bool isEncryption}) async {
    final controller = TextEditingController();
    return showCupertinoDialog<String>(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: Text(isEncryption ? 'Защита бэкапа' : 'Расшифровка бэкапа'),
        content: Column(
          children: [
            Text(isEncryption 
              ? 'Введите пароль для шифрования файла (опционально)' 
              : 'Введите пароль, если файл был зашифрован'),
            const SizedBox(height: 12),
            CupertinoTextField(
              controller: controller,
              placeholder: 'Пароль',
              obscureText: true,
            ),
          ],
        ),
        actions: [
          CupertinoDialogAction(
            child: const Text('Без пароля / Отмена'), // Упрощение для UI
            onPressed: () => Navigator.pop(ctx, ''), 
          ),
          CupertinoDialogAction(
            child: const Text('OK'),
            onPressed: () => Navigator.pop(ctx, controller.text),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 6),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: Color(0xFF888888),
          letterSpacing: 0.8,
          fontFamily: AppStyles.fontFamily,
        ),
      ),
    );
  }
}
