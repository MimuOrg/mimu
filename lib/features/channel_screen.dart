import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:mimu/shared/glass_widgets.dart';
import 'package:mimu/shared/animated_widgets.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:mimu/app/theme.dart';
import 'package:mimu/data/channel_service.dart';
import 'package:mimu/data/settings_service.dart';
import 'package:mimu/data/user_api.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/services.dart';

class ChannelScreen extends StatefulWidget {
  final String channelName;
  final String avatarAsset;
  final bool isOwner;

  const ChannelScreen({
    super.key,
    required this.channelName,
    required this.avatarAsset,
    this.isOwner = false,
  });

  @override
  State<ChannelScreen> createState() => _ChannelScreenState();
}

class _ChannelScreenState extends State<ChannelScreen> {
  bool _isSubscribed = false;
  bool _notificationsEnabled = true;
  bool _isSearchActive = false;
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _posts = [];
  List<Map<String, dynamic>> _filteredPosts = [];
  
  @override
  void initState() {
    super.initState();
    _loadChannelData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadChannelData() async {
    await ChannelService.init();
    final isSubscribed = await ChannelService.isSubscribed(widget.channelName);
    final notifications = await ChannelService.getChannelNotifications(widget.channelName);
    final posts = await ChannelService.getChannelPosts(widget.channelName);
    
    // Если постов нет, добавляем демо-посты
    if (posts.isEmpty) {
      final demoPosts = [
        {
          'id': '1',
          'text': 'Всем здарова',
          'time': '12:12',
          'date': 'Сегодня',
          'timestamp': DateTime.now().toIso8601String(),
        },
        {
          'id': '2',
          'text': 'буду постить тут о максе',
          'time': '12:12',
          'date': 'Сегодня',
          'timestamp': DateTime.now().toIso8601String(),
        },
        {
          'id': '3',
          'text': 'Новый пост в канале',
          'time': '10:30',
          'date': 'Вчера',
          'timestamp': DateTime.now().subtract(const Duration(days: 1)).toIso8601String(),
        },
      ];
      for (final post in demoPosts) {
        await ChannelService.addPost(widget.channelName, post['text'] as String);
      }
      final reloaded = await ChannelService.getChannelPosts(widget.channelName);
      setState(() {
        _posts = reloaded;
        _filteredPosts = reloaded;
        _isSubscribed = isSubscribed;
        _notificationsEnabled = notifications;
      });
    } else {
      setState(() {
        _posts = posts;
        _filteredPosts = posts;
        _isSubscribed = isSubscribed;
        _notificationsEnabled = notifications;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(CupertinoIcons.chevron_left),
          onPressed: () => Navigator.of(context).pop(),
          color: Colors.white,
        ),
        centerTitle: true,
        title: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 20,
              backgroundImage: AssetImage(widget.avatarAsset),
            ),
            const SizedBox(height: 6),
            Text(
              widget.channelName,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            FutureBuilder<int>(
              future: ChannelService.getSubscribedChannels().then((list) => list.length),
              builder: (context, snapshot) {
                final count = snapshot.data ?? 0;
                return Text(
                  '$count подписчик${count % 10 == 1 && count % 100 != 11 ? '' : count % 10 >= 2 && count % 10 <= 4 && (count % 100 < 10 || count % 100 >= 20) ? 'а' : 'ов'}',
                  style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.6)),
                );
              },
            ),
          ],
        ),
        actions: [
          GlassIconButton(
            icon: CupertinoIcons.ellipsis_vertical,
            onPressed: () {
              _showChannelMenu(context);
            },
          ),
        ],
        flexibleSpace: ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: Container(color: Colors.transparent),
          ),
        ),
      ),
      body: Stack(
        children: [
          // Background
          Consumer<ThemeProvider>(
            builder: (context, themeProvider, child) {
              return Container(
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage(themeProvider.backgroundImage ?? "assets/images/background_pattern.png"),
                    fit: BoxFit.cover,
                  ),
                ),
              );
            },
          ),
          Column(
            children: [
              const SizedBox(height: 80),
              if (_isSearchActive)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: GlassContainer(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: TextField(
                      controller: _searchController,
                      autofocus: true,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Поиск в канале...',
                        hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                        prefixIcon: Icon(CupertinoIcons.search, color: Colors.white.withOpacity(0.7)),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(CupertinoIcons.xmark, size: 18),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() {
                                    _filteredPosts = _posts;
                                    _isSearchActive = false;
                                  });
                                },
                              )
                            : null,
                        border: InputBorder.none,
                      ),
                      onChanged: (query) {
                        if (query.isEmpty) {
                          setState(() => _filteredPosts = _posts);
                        } else {
                          ChannelService.searchInChannel(widget.channelName, query).then((results) {
                            if (mounted) {
                              setState(() => _filteredPosts = results);
                            }
                          });
                        }
                      },
                    ),
                  ),
                ),
              Expanded(
                child: _filteredPosts.isEmpty && _isSearchActive
                    ? Center(
                        child: Text(
                          'Ничего не найдено',
                          style: TextStyle(color: Colors.white.withOpacity(0.6)),
                        ),
                      )
                    : ListView.builder(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        itemCount: _filteredPosts.length,
                        itemBuilder: (context, index) {
                          final post = _filteredPosts[index];
                    return AnimateOnDisplay(
                      delayMs: 50 * index,
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: GlassContainer(
                          padding: const EdgeInsets.all(16),
                          decoration: Theme.of(context).extension<GlassTheme>()!.baseGlass.copyWith(
                            color: Theme.of(context).primaryColor.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                post['text'] as String,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  height: 1.4,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    post['date'] as String,
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.5),
                                      fontSize: 11,
                                    ),
                                  ),
                                  Text(
                                    post['time']!,
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.65),
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                      .animate()
                      .fadeIn(
                        duration: const Duration(milliseconds: 280),
                        delay: Duration(milliseconds: 50 * index),
                        curve: Curves.easeOutCubic,
                      )
                      .slideY(
                        begin: 0.1,
                        end: 0,
                        duration: const Duration(milliseconds: 320),
                        delay: Duration(milliseconds: 50 * index),
                        curve: Curves.easeOutCubic,
                      );
                  },
                ),
              ),
              // Media section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Медиа', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 100,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: 5,
                        itemBuilder: (context, index) {
                          return Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.asset('assets/images/avatar_placeholder.png', width: 100, height: 100, fit: BoxFit.cover),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              // Subscribe button
              Padding(
                padding: const EdgeInsets.all(16),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOutCubic,
                  child: GlassButton(
                    onPressed: () async {
                      if (_isSubscribed) {
                        await ChannelService.unsubscribe(widget.channelName);
                      } else {
                        await ChannelService.subscribe(widget.channelName);
                      }
                      setState(() => _isSubscribed = !_isSubscribed);
                      HapticFeedback.mediumImpact();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(_isSubscribed ? 'Вы отписались от канала' : 'Вы подписались на канал'),
                        ),
                      );
                    },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _isSubscribed ? CupertinoIcons.check_mark_circled_solid : CupertinoIcons.add_circled_solid,
                          color: Theme.of(context).primaryColor,
                          size: 20,
                        )
                          .animate(target: _isSubscribed ? 1 : 0)
                          .scale(begin: const Offset(1.0, 1.0), end: const Offset(1.2, 1.2), duration: const Duration(milliseconds: 300))
                          .then()
                          .scale(begin: const Offset(1.2, 1.2), end: const Offset(1.0, 1.0), duration: const Duration(milliseconds: 300)),
                        const SizedBox(width: 8),
                        Text(
                          _isSubscribed ? 'Подписан' : 'Подписаться',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                )
                  .animate()
                  .fadeIn(duration: const Duration(milliseconds: 400), delay: const Duration(milliseconds: 200))
                  .slideY(begin: 0.2, end: 0, duration: const Duration(milliseconds: 400), delay: const Duration(milliseconds: 200), curve: Curves.easeOutCubic),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showChannelMenu(BuildContext context) {
    showGlassBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: Icon(CupertinoIcons.bell_fill, color: Theme.of(context).primaryColor),
            title: const Text('Уведомления'),
            trailing: Switch(
              value: _notificationsEnabled,
              onChanged: (value) async {
                await ChannelService.setChannelNotifications(widget.channelName, value);
                setState(() => _notificationsEnabled = value);
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(value ? 'Уведомления включены' : 'Уведомления выключены')),
                );
              },
            ),
          ),
          const Divider(height: 1),
          ListTile(
            leading: Icon(CupertinoIcons.search, color: Theme.of(context).primaryColor),
            title: const Text('Поиск в канале'),
            onTap: () {
              Navigator.of(context).pop();
              setState(() => _isSearchActive = true);
            },
          ),
          const Divider(height: 1),
          ListTile(
            leading: Icon(CupertinoIcons.share, color: Theme.of(context).primaryColor),
            title: const Text('Поделиться каналом'),
            onTap: () async {
              Navigator.of(context).pop();
              try {
                await Share.share('Канал: ${widget.channelName}\nhttps://mimu.app/channel/${widget.channelName.toLowerCase().replaceAll(' ', '_')}');
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Не удалось поделиться')),
                  );
                }
              }
            },
          ),
          const Divider(height: 1),
          ListTile(
            leading: Icon(CupertinoIcons.link, color: Theme.of(context).primaryColor),
            title: const Text('Скопировать ссылку'),
            onTap: () {
              Navigator.of(context).pop();
              final link = 'https://mimu.app/channel/${widget.channelName.toLowerCase().replaceAll(' ', '_')}';
              Clipboard.setData(ClipboardData(text: link));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Ссылка скопирована')),
              );
            },
          ),
          const Divider(height: 1),
          if (widget.isOwner)
            ListTile(
              leading: Icon(CupertinoIcons.add_circled_solid, color: Theme.of(context).primaryColor),
              title: const Text('Добавить пост'),
              onTap: () {
                Navigator.of(context).pop();
                _showAddPostDialog();
              },
            ),
          if (widget.isOwner)
            const Divider(height: 1),
          ListTile(
            leading: Icon(CupertinoIcons.flag_fill, color: Theme.of(context).primaryColor),
            title: const Text('Пожаловаться'),
            onTap: () {
              Navigator.of(context).pop();
              _showReportDialog();
            },
          ),
        ],
      ),
    );
  }

  void _showAddPostDialog() {
    final controller = TextEditingController();
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Новый пост'),
        content: Padding(
          padding: const EdgeInsets.only(top: 16),
          child: CupertinoTextField(
            controller: controller,
            placeholder: 'Текст поста',
            maxLines: 5,
            autofocus: true,
          ),
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Отмена'),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () async {
              if (controller.text.trim().isNotEmpty) {
                await ChannelService.addPost(widget.channelName, controller.text.trim());
                Navigator.of(context).pop();
                await _loadChannelData();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Пост добавлен')),
                );
              }
            },
            child: const Text('Опубликовать'),
          ),
        ],
      ),
    );
  }

  void _showReportDialog() {
    final reasonController = TextEditingController();
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Пожаловаться на канал'),
        content: Padding(
          padding: const EdgeInsets.only(top: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Укажите причину жалобы:'),
              const SizedBox(height: 12),
              CupertinoTextField(
                controller: reasonController,
                placeholder: 'Причина (необязательно)',
                maxLines: 3,
                autofocus: true,
              ),
            ],
          ),
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Отмена'),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () async {
              final reason = reasonController.text.trim();
              try {
                // Для канала используем название канала как decryptedContent
                // chatId можно получить из ChatStore, если канал связан с чатом
                await UserApi().report(
                  chatId: null, // TODO: получить chatId канала, если доступен
                  decryptedContent: 'Канал: ${widget.channelName}',
                  reason: reason.isNotEmpty ? reason : null,
                );
                if (!mounted) return;
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Жалоба отправлена')),
                );
              } catch (e) {
                if (!mounted) return;
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Ошибка: ${e.toString()}')),
                );
              }
            },
            child: const Text('Отправить'),
          ),
        ],
      ),
    );
  }
}

