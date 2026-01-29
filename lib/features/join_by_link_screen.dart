import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:mimu/data/services/dio_api_client.dart';
import 'package:mimu/app/routes.dart';

/// Экран входа по invite-ссылке: t.mimu.app/join/{token}
class JoinByLinkScreen extends StatefulWidget {
  final String inviteToken;

  const JoinByLinkScreen({super.key, required this.inviteToken});

  @override
  State<JoinByLinkScreen> createState() => _JoinByLinkScreenState();
}

class _JoinByLinkScreenState extends State<JoinByLinkScreen> {
  bool _loading = false;
  String? _error;

  Future<void> _join() async {
    final token = widget.inviteToken.trim();
    if (token.isEmpty) {
      setState(() => _error = 'Нет токена приглашения');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final dio = DioApiClient().dio;
      final resp = await dio.post(
        '/api/v1/chats/join',
        data: {'invite_token': token},
      );
      final data = resp.data is Map ? Map<String, dynamic>.from(resp.data as Map) : null;
      final chatId = data?['chat_id']?.toString();
      if (chatId == null || chatId.isEmpty) {
        setState(() => _error = 'Не удалось войти в чат');
        return;
      }
      if (!mounted) return;
      Navigator.of(context).pop();
      Navigator.of(context).pushNamed(AppRoutes.chat, arguments: {'chatId': chatId});
    } catch (e) {
      setState(() {
        _error = e.toString().replaceFirst('DioException: ', '');
        _loading = false;
      });
    }
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: const Text('Присоединиться к чату'),
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          child: const Icon(CupertinoIcons.xmark),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Text(
                    _error!,
                    style: const TextStyle(color: CupertinoColors.systemRed),
                    textAlign: TextAlign.center,
                  ),
                ),
              CupertinoButton.filled(
                onPressed: _loading ? null : _join,
                child: _loading
                    ? const CupertinoActivityIndicator(color: CupertinoColors.white)
                    : const Text('Вступить в чат'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
