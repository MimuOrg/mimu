import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:mimu/shared/glass_widgets.dart';
import 'package:mimu/shared/cupertino_dialogs.dart';
import 'package:mimu/data/browser_service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import 'package:mimu/app/theme.dart';
import 'package:flutter_animate/flutter_animate.dart';

class BrowserView extends StatefulWidget {
  final String initialUrl;
  const BrowserView({super.key, required this.initialUrl});

  @override
  State<BrowserView> createState() => _BrowserViewState();
}

class _BrowserViewState extends State<BrowserView> {
  late final WebViewController _controller;
  bool _isLoading = true;
  String _currentUrl = '';
  bool _canGoBack = false;
  bool _canGoForward = false;

  @override
  void initState() {
    super.initState();
    _currentUrl = widget.initialUrl;
    final isIncognito = BrowserService.getIncognitoMode();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.transparent)
      ..enableZoom(true)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            setState(() {
              _isLoading = true;
              _currentUrl = url;
            });
          },
          onProgress: (int progress) {
            // Обновляем прогресс загрузки
            setState(() {
              _isLoading = progress < 100;
            });
          },
          onPageFinished: (String url) async {
            setState(() {
              _isLoading = false;
              _currentUrl = url;
            });
            _updateNavigationState();
            // Сохраняем в историю если не инкогнито
            if (!BrowserService.getIncognitoMode()) {
              try {
                final title = await _controller.getTitle() ?? _getDomain(url);
                await BrowserService.addToHistory(title, url);
              } catch (_) {
                await BrowserService.addToHistory(_getDomain(url), url);
              }
            }
          },
          onWebResourceError: (WebResourceError error) {
            setState(() => _isLoading = false);
            // Показываем понятное сообщение об ошибке
            if (mounted) {
              String errorMessage = 'Ошибка загрузки страницы';
              if (error.errorCode == -2 || error.description.contains('CACHE_MISS')) {
                // Перезагружаем страницу
                Future.delayed(const Duration(milliseconds: 500), () {
                  if (mounted) {
                    _controller.reload();
                  }
                });
                return;
              } else if (error.errorCode == -6) {
                errorMessage = 'Нет соединения с интернетом';
              } else if (error.errorCode == -8) {
                errorMessage = 'Страница не найдена';
              } else if (error.description.contains('SSL') || error.description.contains('certificate')) {
                errorMessage = 'Ошибка безопасности соединения';
              }
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(errorMessage),
                  backgroundColor: Colors.redAccent,
                ),
              );
            }
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.initialUrl));
  }

  Future<void> _updateNavigationState() async {
    final canGoBack = await _controller.canGoBack();
    final canGoForward = await _controller.canGoForward();
    if (mounted) {
      setState(() {
        _canGoBack = canGoBack;
        _canGoForward = canGoForward;
      });
    }
  }

  void _goBack() {
    _controller.goBack();
    _updateNavigationState();
  }

  void _goForward() {
    _controller.goForward();
    _updateNavigationState();
  }

  void _reload() {
    _controller.reload();
  }

  void _goHome() {
    _controller.loadRequest(Uri.parse('https://www.google.com'));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: const Color(0xFF1C1C1E).withOpacity(0.95), // Telegram iOS стиль
        elevation: 0,
        leading: IconButton(
          icon: const Icon(CupertinoIcons.back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: _isLoading
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Text(
                _getDomain(_currentUrl),
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
        actions: [
          IconButton(
            icon: Icon(
              CupertinoIcons.chevron_left,
              color: _canGoBack ? Colors.white : Colors.white.withOpacity(0.3),
            ),
            onPressed: _canGoBack ? _goBack : null,
          ),
          IconButton(
            icon: Icon(
              CupertinoIcons.chevron_right,
              color: _canGoForward ? Colors.white : Colors.white.withOpacity(0.3),
            ),
            onPressed: _canGoForward ? _goForward : null,
          ),
          IconButton(
            icon: const Icon(CupertinoIcons.arrow_clockwise),
            onPressed: _reload,
          ),
          IconButton(
            icon: const Icon(CupertinoIcons.ellipsis),
            onPressed: () => _showBrowserMenu(context),
          ),
        ],
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_isLoading)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: LinearProgressIndicator(
                backgroundColor: Colors.transparent,
                valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).primaryColor),
              ),
            ),
        ],
      ),
    );
  }

  String _getDomain(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.host.isEmpty ? url : uri.host;
    } catch (_) {
      return url;
    }
  }

  void _showFindInPage(BuildContext context) {
    final searchController = TextEditingController();
    showGlassBottomSheet(
      context: context,
      initialChildSize: 0.3,
      minChildSize: 0.25,
      maxChildSize: 0.4,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Icon(CupertinoIcons.search, color: Theme.of(context).primaryColor, size: 24),
                const SizedBox(width: 12),
                const Text('Найти на странице', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const Spacer(),
                IconButton(
                  icon: const Icon(CupertinoIcons.xmark),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: GlassContainer(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: TextField(
                controller: searchController,
                autofocus: true,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Введите текст для поиска...',
                  hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                  prefixIcon: Icon(CupertinoIcons.search, color: Colors.white.withOpacity(0.7)),
                  border: InputBorder.none,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: GlassButton(
              onPressed: () {
                if (searchController.text.isNotEmpty) {
                  _controller.runJavaScript('''
                    window.find('${searchController.text.replaceAll("'", "\\'")}');
                  ''');
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Поиск: ${searchController.text}')),
                  );
                }
              },
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                child: Text('Найти', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  void _showBrowserMenu(BuildContext context) {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => buildCupertinoActionSheet(
        context: context,
        actions: [
          CupertinoActionSheetAction(
            onPressed: () async {
              Navigator.pop(context);
              try {
                final title = await _controller.getTitle() ?? _getDomain(_currentUrl);
                await BrowserService.addBookmark(title, _currentUrl);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Добавлено в закладки')),
                  );
                }
              } catch (_) {
                await BrowserService.addBookmark(_getDomain(_currentUrl), _currentUrl);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Добавлено в закладки')),
                  );
                }
              }
            },
            child: const Text('Добавить в закладки'),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              _goHome();
            },
            child: const Text('Домой'),
          ),
          CupertinoActionSheetAction(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await Share.share(_currentUrl, subject: 'Поделиться ссылкой');
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Не удалось поделиться')),
                  );
                }
              }
            },
            child: const Text('Поделиться'),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              _showFindInPage(context);
            },
            child: const Text('Найти на странице'),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          isDestructiveAction: false,
          onPressed: () => Navigator.pop(context),
          child: const Text('Отмена'),
        ),
      ),
    );
  }
}
