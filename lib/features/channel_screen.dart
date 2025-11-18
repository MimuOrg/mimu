import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:mimu/shared/glass_widgets.dart';
import 'package:mimu/shared/animated_widgets.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:mimu/app/theme.dart';

class ChannelScreen extends StatefulWidget {
  final String channelName;
  final String avatarAsset;

  const ChannelScreen({
    super.key,
    required this.channelName,
    required this.avatarAsset,
  });

  @override
  State<ChannelScreen> createState() => _ChannelScreenState();
}

class _ChannelScreenState extends State<ChannelScreen> {
  bool _isSubscribed = false;
  
  final List<Map<String, dynamic>> _posts = [
    {
      'text': 'Всем здарова',
      'time': '12:12',
      'date': 'Сегодня',
    },
    {
      'text': 'буду постить тут о максе',
      'time': '12:12',
      'date': 'Сегодня',
    },
    {
      'text': 'Новый пост в канале',
      'time': '10:30',
      'date': 'Вчера',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(PhosphorIconsBold.caretLeft),
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
            Text(
              'канал',
              style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.6)),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(PhosphorIconsBold.dotsThreeVertical),
            onPressed: () {},
            color: Colors.white,
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
              Expanded(
                child: ListView.builder(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: _posts.length,
                  itemBuilder: (context, index) {
                    final post = _posts[index];
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
              // Subscribe button
              Padding(
                padding: const EdgeInsets.all(16),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOutCubic,
                  child: GlassButton(
                    onPressed: () {
                      setState(() => _isSubscribed = !_isSubscribed);
                    },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _isSubscribed ? PhosphorIconsBold.checkCircle : PhosphorIconsBold.plus,
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
}

