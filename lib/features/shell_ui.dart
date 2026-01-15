import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:mimu/data/chat_store.dart';
import 'package:mimu/data/models/chat_models.dart';
import 'package:mimu/features/settings_hub.dart';
import 'package:mimu/shared/animated_widgets.dart';
import 'package:mimu/shared/glass_widgets.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../app/routes.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:mimu/app/theme.dart';
import 'package:mimu/features/chat_screen.dart';
import 'package:mimu/features/call_screen.dart';
import 'package:mimu/data/settings_service.dart';
import 'package:mimu/data/browser_service.dart';
import 'package:mimu/data/user_service.dart';
import 'package:mimu/features/browser_view.dart';
import 'package:mimu/features/status_screen.dart';
import 'package:mimu/features/premium_screen.dart';
import 'package:mimu/app/navigation_service.dart';
import 'package:mimu/features/create_entities.dart';
import 'package:provider/provider.dart';
import 'dart:async';

class BannerManager {
  static final BannerManager _instance = BannerManager._internal();
  factory BannerManager() => _instance;
  OverlayEntry? _activeEntry;
  Timer? _hideTimer;

  BannerManager._internal();

  void show({
    required BuildContext context,
    required String title,
    required String message,
    IconData icon = Icons.notifications,
    Duration duration = const Duration(seconds: 3),
  }) {
    _hide();
    final overlay = Overlay.of(context);
    if (overlay == null) return;
    _activeEntry = OverlayEntry(
      builder: (ctx) => Positioned(
        top: 44,
        left: 18,
        right: 18,
        child: GlassContainer(
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.75),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.06), width: 0.5),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.35),
                  blurRadius: 24,
                  offset: const Offset(0, 4)),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
          child: Row(
            children: [
              Icon(icon, color: Theme.of(ctx).primaryColor, size: 26),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(title,
                        style: const TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 15)),
                    const SizedBox(height: 2),
                    Text(message,
                        style: const TextStyle(
                            fontWeight: FontWeight.w400, fontSize: 13)),
                  ],
                ),
              )
            ],
          ),
        )
            .animate()
            .slideY(
                begin: -0.7,
                end: 0,
                duration: const Duration(milliseconds: 360),
                curve: Curves.easeOutBack)
            .fadeIn(),
      ),
    );
    overlay.insert(_activeEntry!);
    _hideTimer = Timer(duration, _hide);
  }

  void _hide() {
    _hideTimer?.cancel();
    _activeEntry?.remove();
    _activeEntry = null;
  }
}

void showSystemBanner(BuildContext context,
    {required String title,
    required String message,
    IconData? icon,
    Duration? duration}) {
  BannerManager().show(
    context: context,
    title: title,
    message: message,
    icon: icon ?? Icons.notifications,
    duration: duration ?? const Duration(seconds: 3),
  );
}

class ShellUI extends StatefulWidget {
  const ShellUI({super.key});

  @override
  State<ShellUI> createState() => _ShellUIState();
}

class _ShellUIState extends State<ShellUI> with SingleTickerProviderStateMixin {
  int _currentIndex = 0;
  int? _openedChat; // index of chat in liquid swipe
  bool _isSearchActive = false;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  late PageController _pageController;
  bool _isBottomNavBarVisible = true;
  final List<_NavDestination> _navDestinations = const [
    _NavDestination(icon: CupertinoIcons.chat_bubble_2_fill, label: "Чаты"),
    _NavDestination(icon: CupertinoIcons.globe, label: "Браузер"),
    _NavDestination(icon: CupertinoIcons.settings_solid, label: "Настройки"),
  ];
  bool _isNavDragActive = false;
  int? _navDragTarget;
  final GlobalKey _navBarKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    // Убрано приветственное сообщение
  }

  @override
  void dispose() {
    _pageController.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void showCustomGlassBottomSheet(
      {required BuildContext context, required Widget child}) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      barrierColor: Colors.black.withOpacity(0.4),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => AnimatedPadding(
        duration: const Duration(milliseconds: 340),
        curve: Curves.easeOutQuart,
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: GlassContainer(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.75),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            border: Border(
              top: BorderSide(color: Colors.white.withOpacity(0.06), width: 0.5),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.35),
                blurRadius: 32,
                offset: const Offset(0, -8),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: Container(
        constraints: BoxConstraints.expand(),
        child: Stack(
          children: [
          // Background
          Consumer<ThemeProvider>(
            builder: (context, themeProvider, child) {
              return Container(
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage("assets/images/secondb.png"),
                    fit: BoxFit.cover,
                  ),
                ),
              );
            },
          ),
          // Overlay для поиска - без блюра, просто затемнение
          if (_isSearchActive)
            Positioned.fill(
              child: IgnorePointer(
                ignoring: !_isSearchActive,
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 200),
                  opacity: _isSearchActive ? 1 : 0,
                  curve: Curves.easeOutCubic,
                  child: Container(color: Colors.black.withOpacity(0.5)),
                ),
              ),
            ),
          // Content with proper positioning
          SafeArea(
            child: Column(
              children: [
                // Top bar (only on Chats)
                if (_currentIndex == 0)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white.withOpacity(0.04), width: 0.5),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 320),
                              layoutBuilder: (currentChild, previousChildren) {
                                return Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    ...previousChildren,
                                    if (currentChild != null) currentChild,
                                  ],
                                );
                              },
                              transitionBuilder: (child, animation) {
                                final curved = CurvedAnimation(
                                  parent: animation,
                                  curve: Curves.easeInOutCubic);
                                return FadeTransition(
                                  opacity: curved,
                                  child: child,
                                );
                              },
                              child: _isSearchActive
                                ? SizedBox(
                                    key: const ValueKey('search'),
                                    height: 44,
                                    child: TextField(
                                      controller: _searchController,
                                      focusNode: _searchFocusNode,
                                      autofocus: true,
                                      style: const TextStyle(color: Colors.white),
                                      decoration: InputDecoration(
                                        hintText: "Поиск...",
                                        filled: true,
                                        fillColor: Colors.white.withOpacity(0.08),
                                        isDense: true,
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                        border: OutlineInputBorder(
                                          borderSide: BorderSide(color: Colors.white.withOpacity(0.06), width: 0.5),
                                          borderRadius: BorderRadius.circular(16),
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderSide: BorderSide(color: Colors.white.withOpacity(0.06), width: 0.5),
                                          borderRadius: BorderRadius.circular(16),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderSide: BorderSide(color: Theme.of(context).primaryColor.withOpacity(0.4), width: 1),
                                          borderRadius: BorderRadius.circular(16),
                                        ),
                                        prefixIcon: const Icon(CupertinoIcons.search, size: 18),
                                        suffixIcon: (_searchController.text.isNotEmpty)
                                            ? IconButton(
                                                icon: const Icon(Icons.clear, size: 18),
                                                onPressed: () {
                                                  _searchController.clear();
                                                  setState(() {});
                                                },
                                              )
                                            : null,
                                      ),
                                      onChanged: (_) => setState(() {}),
                                    ),
                                  )
                                : Align(
                                    key: const ValueKey('title'),
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      "Mimu",
                                      style: Theme.of(context)
                                          .textTheme
                                          .headlineMedium
                                          ?.copyWith(
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white),
                                    ),
                                  ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 280),
                            transitionBuilder: (child, animation) =>
                                FadeTransition(opacity: animation, child: child),
                            child: _buildSearchButton(),
                          ),
                        ],
                      ),
                    ),
                  ),
                // Search chips (only when search is active)
                if (_currentIndex == 0 && _isSearchActive)
                  Container(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      child: Row(
                        children: [
                          _buildChip('Все'),
                          _buildChip('Люди'),
                          _buildChip('Группы'),
                          _buildChip('Каналы'),
                          _buildChip('Медиа'),
                        ],
                      ),
                    ),
                  ),
                // Content with swipe navigation
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    physics: SettingsService.getSwipeNavigation()
                        ? const BouncingScrollPhysics()
                        : const NeverScrollableScrollPhysics(),
                    onPageChanged: (index) {
                      setState(() => _currentIndex = index);
                    },
                    children: [
                      _ChatListPage(
                        query: _searchController.text,
                        onChatTap: (index) {
                          setState(() {
                            _openedChat = index;
                            _isBottomNavBarVisible =
                                false; // Скрываем панель при открытии чата
                          });
                        },
                      ),
                      _BrowserPageStateful(), // Используем Stateful версию
                      const SettingsHub(),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (_currentIndex == 0 && _openedChat != null)
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: Duration(milliseconds: SettingsService.getOptimizeMimu() ? 250 : 300),
              curve: Curves.easeInOutCubic,
              builder: (context, value, child) {
                return Transform.scale(
                  scale: 0.88 + (value * 0.12),
                  child: Opacity(
                    opacity: value,
                    child: Consumer<ChatStore>(
                      builder: (context, chatStore, child) {
                        final threads = chatStore.threads;
                        if (threads.isEmpty) {
                          return const SizedBox.shrink();
                        }
                        return LiquidChatPageView(
                          threads: threads,
                          initialPage: _openedChat ?? 0,
                          onClose: () => setState(() {
                            _openedChat = null;
                            _isBottomNavBarVisible =
                                true; // Показываем панель при закрытии чата
                          }),
                        );
                      },
                    ),
                  ),
                );
              },
            ),
          // Новая плавающая панель навигации
          _buildFloatingNavBar(),
        ],
        ),
      ),
      // bottomNavigationBar: _buildBottomNavBar(), // Заменено на плавающую панель в Stack
    );
  }

  void _onNavTap(int index) {
    if (_currentIndex == index) return;
    if (SettingsService.getVibrationEnabled()) {
      HapticFeedback.lightImpact();
    }
    setState(() {
      _currentIndex = index;
    });
    final isOptimized = SettingsService.getOptimizeMimu();
    _pageController.animateToPage(
      index,
      duration: Duration(milliseconds: isOptimized ? 250 : 300),
      curve: Curves.easeInOutCubic,
    );
  }

  void _startNavDrag(Offset globalPosition) {
    final index = _indexFromGlobal(globalPosition);
    if (index == null) return;
    setState(() {
      _isNavDragActive = true;
      _navDragTarget = index;
    });
  }

  void _updateNavDrag(Offset globalPosition) {
    if (!_isNavDragActive) return;
    final index = _indexFromGlobal(globalPosition);
    if (index == null || index == _navDragTarget) return;
    setState(() {
      _navDragTarget = index;
    });
  }

  void _endNavDrag() {
    if (_isNavDragActive && _navDragTarget != null) {
      _onNavTap(_navDragTarget!);
    }
    setState(() {
      _isNavDragActive = false;
      _navDragTarget = null;
    });
  }

  void _cancelNavDrag() {
    if (!_isNavDragActive) return;
    setState(() {
      _isNavDragActive = false;
      _navDragTarget = null;
    });
  }

  int? _indexFromGlobal(Offset globalPosition) {
    final box = _navBarKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return null;
    final local = box.globalToLocal(globalPosition);
    if (local.dx < 0 ||
        local.dx > box.size.width ||
        local.dy < 0 ||
        local.dy > box.size.height) {
      return null;
    }
    final segmentWidth = box.size.width / _navDestinations.length;
    final index =
        (local.dx / segmentWidth).floor().clamp(0, _navDestinations.length - 1);
    return index;
  }

  double _alignmentForIndex(int index) {
    if (_navDestinations.length == 1) return 0;
    final step = 2 / (_navDestinations.length - 1);
    return -1 + (index * step);
  }

  Widget _buildFloatingNavBar() {
    final isOptimized = SettingsService.getOptimizeMimu();
    return AnimatedPositioned(
      duration: Duration(milliseconds: isOptimized ? 200 : 280),
      curve: Curves.easeInOutCubic,
      bottom: _isBottomNavBarVisible ? 16 : -100,
      left: 0,
      right: 0,
      child: AnimatedOpacity(
        duration: Duration(milliseconds: isOptimized ? 150 : 250),
        curve: Curves.easeInOutCubic,
        opacity: _isBottomNavBarVisible ? 1.0 : 0.0,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _buildCreateButton(),
              const SizedBox(width: 12),
              _buildNavBarBody(),
              const SizedBox(width: 12),
              _buildPremiumButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchButton() {
    final isOptimized = SettingsService.getOptimizeMimu();
    final icon = Icon(
      _isSearchActive ? Icons.close : CupertinoIcons.search,
      color: Colors.white,
      size: 20,
    );

    final base = InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () {
        setState(() {
          _isSearchActive = !_isSearchActive;
          _isBottomNavBarVisible = !_isSearchActive;
          if (_isSearchActive) {
            _searchFocusNode.requestFocus();
          } else {
            _searchController.clear();
            _searchFocusNode.unfocus();
          }
        });
      },
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.18)),
          color: Colors.black.withOpacity(0.55),
        ),
        child: Center(child: icon),
      ),
    );

    // Telegram iOS стиль - чистая кнопка без лишних эффектов
    return base;
  }

  Widget _buildCreateButton() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: () {
          if (SettingsService.getVibrationEnabled()) {
            HapticFeedback.lightImpact();
          }
          _showCreateMenu(context);
        },
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withOpacity(0.1),
          ),
          child: const Icon(CupertinoIcons.add, color: Colors.white, size: 24),
        ),
      ),
    );
  }

  Widget _buildPremiumButton() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: () {
          if (SettingsService.getVibrationEnabled()) {
            HapticFeedback.lightImpact();
          }
          Navigator.pushNamed(context, AppRoutes.premium);
        },
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Theme.of(context).primaryColor.withOpacity(0.2),
          ),
          child: Icon(
            CupertinoIcons.checkmark_seal_fill,
            color: Theme.of(context).primaryColor,
            size: 22,
          ),
        ),
      ),
    );
  }


  void _showCreateMenu(BuildContext context) {
    showCupertinoModalPopup(
      context: context,
      filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
      builder: (context) => CupertinoActionSheet(
        title: const Text('Создать'),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              Navigator.of(context).push(NavigationService.createSlideTransitionRoute(CreateEntitiesScreen(entityType: EntityType.channel)));
            },
            child: const Text('Канал'),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              Navigator.of(context).push(NavigationService.createSlideTransitionRoute(CreateEntitiesScreen(entityType: EntityType.group)));
            },
            child: const Text('Группу'),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              _createSecretChat(context);
            },
            child: const Text('Секретный чат'),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              _createCloudChat(context);
            },
            child: const Text('Облачный чат'),
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

  void _createSecretChat(BuildContext context) {
    final chatStore = Provider.of<ChatStore>(context, listen: false);
    final contacts = chatStore.contacts;

    if (contacts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Нет контактов для создания секретного чата')),
      );
      return;
    }

    showCupertinoModalPopup(
      context: context,
      filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
      builder: (ctx) => CupertinoActionSheet(
        title: const Text('Выберите контакт'),
        message: const Text('Секретные чаты используют сквозное шифрование'),
        actions: contacts.map((contact) => CupertinoActionSheetAction(
          onPressed: () async {
            Navigator.pop(ctx);
            final chatId = await chatStore.createChat(
              title: contact.name,
              isGroup: false,
              chatType: ChatType.secret,
              participantIds: [contact.id],
            );
            if (context.mounted) {
              Navigator.pushNamed(context, AppRoutes.chat, arguments: {'chatId': chatId});
            }
          },
          child: Text(contact.name),
        )).toList(),
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Отмена'),
        ),
      ),
    );
  }

  void _createCloudChat(BuildContext context) {
    final chatStore = Provider.of<ChatStore>(context, listen: false);

    showCupertinoDialog(
      context: context,
      builder: (ctx) {
        final controller = TextEditingController();
        return CupertinoAlertDialog(
          title: const Text('Облачный чат'),
          content: Column(
            children: [
              const SizedBox(height: 8),
              const Text('Сохраняйте заметки, файлы и сообщения в облаке'),
              const SizedBox(height: 16),
              CupertinoTextField(
                controller: controller,
                placeholder: 'Название чата',
                style: const TextStyle(color: CupertinoColors.white),
              ),
            ],
          ),
          actions: [
            CupertinoDialogAction(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Отмена'),
            ),
            CupertinoDialogAction(
              isDefaultAction: true,
              onPressed: () async {
                Navigator.pop(ctx);
                final name = controller.text.trim().isEmpty ? 'Избранное' : controller.text.trim();
                final chatId = await chatStore.createChat(
                  title: name,
                  isGroup: false,
                  chatType: ChatType.cloud,
                  participantIds: [],
                );
                if (context.mounted) {
                  Navigator.pushNamed(context, AppRoutes.chat, arguments: {'chatId': chatId});
                }
              },
              child: const Text('Создать'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildNavBarBody() {
    return GestureDetector(
      key: _navBarKey,
      onLongPressStart: (details) => _startNavDrag(details.globalPosition),
      onLongPressMoveUpdate: (details) =>
          _updateNavDrag(details.globalPosition),
      onLongPressEnd: (_) => _endNavDrag(),
      onLongPressCancel: _cancelNavDrag,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          color: Colors.white.withOpacity(0.1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(_navDestinations.length, (index) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: _buildNavItem(_navDestinations[index], index),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildNavDragOverlay() {
    final targetIndex = _navDragTarget ?? _currentIndex;
    final isOptimized = SettingsService.getOptimizeMimu();
    return IgnorePointer(
      child: AnimatedOpacity(
        duration: Duration(milliseconds: isOptimized ? 150 : 200),
        curve: Curves.easeInOutCubic,
        opacity: _isNavDragActive ? 1 : 0,
        child: Align(
          alignment: Alignment(_alignmentForIndex(targetIndex), -1.2),
          child: Container(
            width: 132,
            height: 44,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(26),
              color: Colors.black.withOpacity(0.7),
              border: Border.all(color: Colors.white.withOpacity(0.25)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.18),
                  blurRadius: 24,
                  offset: const Offset(0, 18),
                ),
              ],
            ),
            child: Center(
              child: Text(
                'Удерживай и тяни',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.white.withOpacity(0.9),
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _selectedCategory = 'Все';
  Widget _buildChip(String label) {
    final selected = _selectedCategory == label;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeInOutCubic,
      margin: EdgeInsets.only(left: label == 'Все' ? 0 : 10),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => setState(() => _selectedCategory = label),
          child: GlassContainer(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration:
                Theme.of(context).extension<GlassTheme>()!.baseGlass.copyWith(
                      color: selected
                          ? Theme.of(context).primaryColor.withOpacity(0.12)
                          : Colors.white.withOpacity(0.04),
                      border: Border.all(
                        color: selected
                            ? Theme.of(context).primaryColor.withOpacity(0.35)
                            : Colors.white.withOpacity(0.06),
                        width: selected ? 1.2 : 0.5,
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
            child: Text(
              label,
              style: TextStyle(
                fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                color: selected ? Colors.white : Colors.white.withOpacity(0.8),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildChatsFab(BuildContext context) {
    final theme = Theme.of(context);

    final fab = FloatingActionButton(
      onPressed: () {
        showGlassBottomSheet(
          context: context,
          builder: (context) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(CupertinoIcons.person_2, color: Colors.white),
                title: const Text(
                  'Новая группа',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                onTap: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).push(
                    NavigationService.createSlideTransitionRoute(
                      CreateEntitiesScreen(entityType: EntityType.group),
                    ),
                  );
                },
              ),
              const Divider(height: 1),
              ListTile(
                leading: Icon(
                  CupertinoIcons.antenna_radiowaves_left_right,
                  color: theme.primaryColor,
                ),
                title: const Text(
                  'Новый канал',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                onTap: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).push(
                    NavigationService.createSlideTransitionRoute(
                      CreateEntitiesScreen(entityType: EntityType.channel),
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
      backgroundColor: theme.primaryColor,
      elevation: 8,
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: theme.primaryColor.withOpacity(0.4),
              blurRadius: 12,
              spreadRadius: 2,
            ),
          ],
        ),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );

    return fab
        .animate()
        .scale(
            delay: const Duration(milliseconds: 200),
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeOutCubic)
        .fadeIn(duration: const Duration(milliseconds: 300));
  }

  Widget _buildNavItem(_NavDestination destination, int index) {
    final bool isSelected = _currentIndex == index;
    final color = isSelected ? Colors.white : Colors.white.withOpacity(0.5);

    return GestureDetector(
      onTap: () => _onNavTap(index),
      behavior: HitTestBehavior.translucent,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 160),
        opacity: _isNavDragActive && _navDragTarget == index ? 0.75 : 1,
        child: Icon(destination.icon, color: color, size: 26),
      ),
    );
  }
}

// --- Chat List Page ---
class _ChatListPage extends StatelessWidget {
  final String query;
  final void Function(int)? onChatTap;
  const _ChatListPage({this.query = '', this.onChatTap});

  @override
  Widget build(BuildContext context) {
    final shellState = context.findAncestorStateOfType<_ShellUIState>();
    final category = shellState?._selectedCategory ?? 'Все';
    final chatStore = context.watch<ChatStore>();
    var threads = chatStore.threads;

    // Фильтрация по категории ПЕРЕД поиском (исправлен баг)
    if (category != 'Все') {
      // Фильтруем по категории (пока только "Люди" поддерживается, остальные пустые)
      if (category != 'Люди') {
        threads = [];
      }
    }

    if (query.isNotEmpty) {
      // Инициализируем сервисы если нужно
      SettingsService.init();
      UserService.init();

      final searchByUsername = SettingsService.getSearchByUsername();
      threads = threads.where((thread) {
        final titleMatch =
            thread.title.toLowerCase().contains(query.toLowerCase());
        // Если поиск по юзернейму включен, также ищем по username контактов
        if (searchByUsername && query.startsWith('@')) {
          final usernameQuery = query.substring(1).toLowerCase();
          // Проверяем username из UserService для текущего пользователя
          final currentUsername = UserService.getUsername().toLowerCase();
          if (currentUsername.contains(usernameQuery)) {
            return true;
          }
        }
        return titleMatch;
      }).toList();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (category != 'Люди' && category != 'Все')
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Text('Нет результатов в категории "$category"',
                style: TextStyle(color: Colors.white.withOpacity(0.7))),
          ),
        Expanded(
          child: ListView.builder(
            padding: EdgeInsets.zero, // Telegram iOS - без отступов
            itemCount: threads.length,
            itemBuilder: (context, index) {
              final thread = threads[index];
              return _buildChatListItem(context, thread);
            },
            ),
          ),
        ],
      );
  }

  Widget _buildChatListItem(BuildContext context, ChatThread thread) {
    // Telegram iOS стиль - чистый список с микро-анимациями
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          if (SettingsService.getVibrationEnabled()) {
            HapticFeedback.lightImpact();
          }
          Navigator.pushNamed(
            context,
            AppRoutes.chat,
            arguments: {'chatId': thread.id},
          );
        },
        borderRadius: BorderRadius.zero, // Без закруглений для полного списка
        splashColor: Theme.of(context).primaryColor.withOpacity(0.1),
        highlightColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          color: Colors.transparent, // Для правильной работы InkWell
          child: Row(
            children: [
              // Аватар в стиле Telegram iOS
              GestureDetector(
                onTap: () => Navigator.pushNamed(
                  context,
                  AppRoutes.profile,
                  arguments: {
                    'userName': thread.title,
                    'avatarAsset': thread.avatarAsset
                  },
                ),
                child: Hero(
                  tag: 'avatar-${thread.id}',
                  child: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.grey.withOpacity(0.3),
                    ),
                    child: ClipOval(
                      child: Image(
                        image: _avatarProvider(thread.avatarAsset),
                        fit: BoxFit.cover,
                        width: 50,
                        height: 50,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        if (thread.chatType == ChatType.secret)
                          Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: Icon(
                              CupertinoIcons.lock_fill,
                              size: 13,
                              color: Colors.white.withOpacity(0.6),
                            ),
                          ),
                        if (thread.chatType == ChatType.cloud)
                          Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: Icon(
                              CupertinoIcons.cloud_fill,
                              size: 13,
                              color: Colors.white.withOpacity(0.6),
                            ),
                          ),
                        Expanded(
                          child: Text(
                            thread.title,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                              color: Colors.white,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                      const SizedBox(height: 2),
                      Text(
                        _buildPreview(thread),
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.6),
                          fontSize: 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _formatTime(thread.updatedAt),
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.6),
                      fontSize: 14,
                    ),
                  ),
                  if (thread.messages.isNotEmpty && !thread.messages.last.isRead)
                    const SizedBox(height: 6),
                  if (thread.messages.isNotEmpty && !thread.messages.last.isRead)
                    Container(
                      width: 18,
                      height: 18,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Theme.of(context).primaryColor,
                      ),
                      child: const Center(
                        child: Text(
                          '1',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
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

  String _buildPreview(ChatThread thread) {
    if (thread.messages.isEmpty) return 'Нажмите, чтобы начать чат';
    final last = thread.messages.last;
    switch (last.type) {
      case ChatMessageType.text:
        return last.text ?? '';
      case ChatMessageType.image:
        return '📷 Фото';
      case ChatMessageType.voice:
        return '🎙 Голосовое';
      case ChatMessageType.file:
        return last.text ?? '📎 Файл';
      case ChatMessageType.call:
        return last.text ?? '📞 Звонок';
      case ChatMessageType.location:
        return '📍 Местоположение';
      case ChatMessageType.poll:
        return '📊 Опрос';
      case ChatMessageType.sticker:
        return '🎭 Стикер';
    }
  }

  String _formatTime(DateTime time) {
    final hours = time.hour.toString().padLeft(2, '0');
    final minutes = time.minute.toString().padLeft(2, '0');
    return '$hours:$minutes';
  }

  ImageProvider _avatarProvider(String path) {
    if (path.startsWith('assets/')) {
      return AssetImage(path);
    }
    final file = File(path);
    if (file.existsSync()) {
      return FileImage(file);
    }
    return const AssetImage('assets/images/avatar_placeholder.png');
  }
}

class _NavDestination {
  final IconData icon;
  final String label;
  const _NavDestination({required this.icon, required this.label});
}

// Liquid swipe PageView с чатами
/// Упрощенная версия просмотра чатов без liquid glass
class LiquidChatPageView extends StatefulWidget {
  final List<ChatThread> threads;
  final int initialPage;
  final VoidCallback onClose;
  const LiquidChatPageView(
      {required this.threads,
      required this.initialPage,
      required this.onClose});
  @override
  State<LiquidChatPageView> createState() => _LiquidChatPageViewState();
}

class _LiquidChatPageViewState extends State<LiquidChatPageView> {
  late PageController _pageController;
  late int _pageIndex;

  @override
  void initState() {
    super.initState();
    _pageIndex = widget.initialPage;
    _pageController = PageController(initialPage: widget.initialPage);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Telegram iOS стиль - плавная анимация появления
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          transitionBuilder: (child, animation) {
            return FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0.1, 0),
                  end: Offset.zero,
                ).animate(CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeOutCubic,
                )),
                child: child,
              ),
            );
          },
          child: Container(
            key: ValueKey(widget.threads[_pageIndex].id),
            child: ChatScreen(
              chatId: widget.threads[_pageIndex].id,
            ),
          ),
        ),
        // Кнопка назад в стиле Telegram iOS
        Positioned(
          top: 44,
          left: 16,
          child: GlassIconButton(
            icon: CupertinoIcons.back,
            iconColor: Colors.white,
            iconSize: 22,
            onPressed: widget.onClose,
            borderRadius: 20,
          ),
        ),
      ],
    );
  }
}

// --- Browser Page ---
class _BrowserPageStateful extends StatefulWidget {
  const _BrowserPageStateful();

  @override
  State<_BrowserPageStateful> createState() => _BrowserPageStatefulState();
}

class _BrowserPageStatefulState extends State<_BrowserPageStateful> {
  final TextEditingController _searchController = TextEditingController();
  bool vsEnabled = true;
  String _selectedSearchEngine = 'Google';
  int _selectedTab = 0; // 0: поиск, 1: история, 2: закладки, 3: загрузки
  List<Map<String, dynamic>> _history = [];
  List<Map<String, dynamic>> _bookmarks = [];
  List<Map<String, dynamic>> _downloads = [];
  bool _incognitoMode = false;

  @override
  void initState() {
    super.initState();
    _loadData();
    _searchController.addListener(() {
      setState(() {}); // Обновляем UI при изменении текста поиска
    });
  }

  Future<void> _loadData() async {
    await BrowserService.init();
    await SettingsService.init();
    setState(() {
      _selectedSearchEngine = SettingsService.getSearchEngine();
      vsEnabled = SettingsService.getVSLEnabled();
      _incognitoMode = BrowserService.getIncognitoMode();
    });
    _refreshHistory();
    _refreshBookmarks();
    _refreshDownloads();
  }

  Future<void> _refreshDownloads() async {
    final downloads = await BrowserService.getDownloads();
    setState(() {
      _downloads = downloads;
    });
  }

  Future<void> _refreshHistory() async {
    final history = await BrowserService.getHistory();
    setState(() {
      _history = history;
    });
  }

  Future<void> _refreshBookmarks() async {
    final bookmarks = await BrowserService.getBookmarks();
    setState(() {
      _bookmarks = bookmarks;
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _performSearch(String query) async {
    String searchUrl;
    switch (_selectedSearchEngine) {
      case 'Google':
        searchUrl =
            'https://www.google.com/search?q=${Uri.encodeComponent(query)}';
        break;
      case 'DuckDuckGo':
        searchUrl = 'https://duckduckgo.com/?q=${Uri.encodeComponent(query)}';
        break;
      case 'Bing':
        searchUrl =
            'https://www.bing.com/search?q=${Uri.encodeComponent(query)}';
        break;
      default:
        searchUrl =
            'https://www.google.com/search?q=${Uri.encodeComponent(query)}';
    }

    if (!_incognitoMode) {
      await BrowserService.addToHistory(query, searchUrl);
      await _refreshHistory();
    }

    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => BrowserView(initialUrl: searchUrl),
        ),
      );
    }
  }

  void _showSearchEngineDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.black87,
        title: const Text('Поисковая система'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: ['Google', 'DuckDuckGo', 'Bing'].map((engine) {
            final isSelected = _selectedSearchEngine == engine;
            return ListTile(
              title: Text(engine),
              trailing: isSelected
                  ? Icon(CupertinoIcons.check_mark,
                      color: Theme.of(context).primaryColor)
                  : null,
              onTap: () async {
                await SettingsService.setSearchEngine(engine);
                setState(() => _selectedSearchEngine = engine);
                Navigator.of(context).pop();
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  void _showBrowserSettings() {
    showGlassBottomSheet(
      context: context,
      initialChildSize: 0.5,
      minChildSize: 0.3,
      maxChildSize: 0.8,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Icon(CupertinoIcons.settings,
                    color: Theme.of(context).primaryColor, size: 24),
                const SizedBox(width: 12),
                const Text('Настройки браузера',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const Spacer(),
                IconButton(
                  icon: const Icon(CupertinoIcons.xmark),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          ListTile(
            leading: Icon(CupertinoIcons.search,
                color: Theme.of(context).primaryColor),
            title: const Text('Поисковая система'),
            subtitle: Text(_selectedSearchEngine),
            trailing: Icon(CupertinoIcons.chevron_right,
                color: Colors.white.withOpacity(0.5)),
            onTap: () {
              Navigator.of(context).pop();
              _showSearchEngineDialog();
            },
          ),
          const Divider(height: 1),
          ListTile(
            leading: Icon(CupertinoIcons.power,
                color: Theme.of(context).primaryColor),
            title: const Text('Отключить ВСЛ'),
            subtitle: const Text('(не рекомендуется)'),
            trailing: Switch(
              value: vsEnabled,
              onChanged: (val) async {
                await SettingsService.setVSLEnabled(val);
                setState(() => vsEnabled = val);
              },
            ),
          ),
          const Divider(height: 1),
          ListTile(
            leading: Icon(CupertinoIcons.eye_slash,
                color: Theme.of(context).primaryColor),
            title: const Text('Режим инкогнито'),
            subtitle: const Text('Не сохраняет историю и cookies'),
            trailing: Switch(
              value: _incognitoMode,
              onChanged: (val) async {
                await BrowserService.setIncognitoMode(val);
                setState(() => _incognitoMode = val);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content: Text(val
                          ? 'Режим инкогнито включен'
                          : 'Режим инкогнито выключен')),
                );
              },
            ),
          ),
          const Divider(height: 1),
          ListTile(
            leading: Icon(CupertinoIcons.trash,
                color: Theme.of(context).primaryColor),
            title: const Text('Очистить историю'),
            onTap: () async {
              await BrowserService.clearHistory();
              await _refreshHistory();
              if (mounted) {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('История очищена')),
                );
              }
            },
          ),
          const Divider(height: 1),
          ListTile(
            leading: Icon(CupertinoIcons.bookmark,
                color: Theme.of(context).primaryColor),
            title: const Text('Управление закладками'),
            trailing: Icon(CupertinoIcons.chevron_right,
                color: Colors.white.withOpacity(0.5)),
            onTap: () {
              setState(() => _selectedTab = 2);
              Navigator.of(context).pop();
            },
          ),
          const Divider(height: 1),
          ListTile(
            leading: Icon(CupertinoIcons.arrow_down_circle,
                color: Theme.of(context).primaryColor),
            title: const Text('Управление загрузками'),
            trailing: Icon(CupertinoIcons.chevron_right,
                color: Colors.white.withOpacity(0.5)),
            onTap: () {
              setState(() => _selectedTab = 3);
              Navigator.of(context).pop();
            },
          ),
          const Divider(height: 1),
          ListTile(
            leading: Icon(CupertinoIcons.shield,
                color: Theme.of(context).primaryColor),
            title: const Text('Безопасность'),
            subtitle: const Text('Настройки безопасности и приватности'),
            trailing: Icon(CupertinoIcons.chevron_right,
                color: Colors.white.withOpacity(0.5)),
            onTap: () {
              Navigator.of(context).pop();
              _showSecuritySettings();
            },
          ),
          const Divider(height: 1),
          ListTile(
            leading: Icon(CupertinoIcons.doc_text,
                color: Theme.of(context).primaryColor),
            title: const Text('Cookies и данные'),
            subtitle: const Text('Управление cookies и кэшем'),
            trailing: Icon(CupertinoIcons.chevron_right,
                color: Colors.white.withOpacity(0.5)),
            onTap: () {
              Navigator.of(context).pop();
              _showCookiesSettings();
            },
          ),
          const Divider(height: 1),
          ListTile(
            leading: Icon(CupertinoIcons.device_desktop,
                color: Theme.of(context).primaryColor),
            title: const Text('Режим чтения'),
            subtitle: const Text('Упрощенный вид страниц'),
            trailing: Switch(
              value: SettingsService.getReadingMode(),
              onChanged: (val) async {
                await SettingsService.setReadingMode(val);
                setState(() {});
              },
            ),
          ),
          const Divider(height: 1),
          ListTile(
            leading: Icon(CupertinoIcons.textformat,
                color: Theme.of(context).primaryColor),
            title: const Text('Перевод страниц'),
            subtitle: const Text('Автоматический перевод'),
            trailing: Switch(
              value: SettingsService.getAutoTranslate(),
              onChanged: (val) async {
                await SettingsService.setAutoTranslate(val);
                setState(() {});
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showSecuritySettings() {
    showGlassBottomSheet(
      context: context,
      initialChildSize: 0.5,
      minChildSize: 0.3,
      maxChildSize: 0.8,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Icon(CupertinoIcons.shield,
                    color: Theme.of(context).primaryColor, size: 24),
                const SizedBox(width: 12),
                const Text('Безопасность',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const Spacer(),
                IconButton(
                  icon: const Icon(CupertinoIcons.xmark),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          ListTile(
            leading: Icon(CupertinoIcons.checkmark_shield,
                color: Theme.of(context).primaryColor),
            title: const Text('Защита от фишинга'),
            subtitle: const Text('Предупреждать о подозрительных сайтах'),
            trailing: Switch(
              value: SettingsService.getPhishingProtection(),
              onChanged: (val) async {
                await SettingsService.setPhishingProtection(val);
                setState(() {});
              },
            ),
          ),
          const Divider(height: 1),
          ListTile(
            leading: Icon(CupertinoIcons.lock,
                color: Theme.of(context).primaryColor),
            title: const Text('HTTPS только'),
            subtitle: const Text('Использовать только безопасные соединения'),
            trailing: Switch(
              value: SettingsService.getHttpsOnly(),
              onChanged: (val) async {
                await SettingsService.setHttpsOnly(val);
                setState(() {});
              },
            ),
          ),
          const Divider(height: 1),
          ListTile(
            leading: Icon(CupertinoIcons.lock_fill,
                color: Theme.of(context).primaryColor),
            title: const Text('Биометрическая защита'),
            subtitle: const Text('Требовать отпечаток для доступа'),
            trailing: Switch(
              value: SettingsService.getBiometricProtection(),
              onChanged: (val) async {
                await SettingsService.setBiometricProtection(val);
                setState(() {});
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showCookiesSettings() {
    showGlassBottomSheet(
      context: context,
      initialChildSize: 0.5,
      minChildSize: 0.3,
      maxChildSize: 0.8,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Icon(CupertinoIcons.info_circle_fill,
                    color: Theme.of(context).primaryColor, size: 24),
                const SizedBox(width: 12),
                const Text('Cookies и данные',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const Spacer(),
                IconButton(
                  icon: const Icon(CupertinoIcons.xmark),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          ListTile(
            leading: Icon(CupertinoIcons.doc_text,
                color: Theme.of(context).primaryColor),
            title: const Text('Принимать cookies'),
            subtitle: const Text('Разрешить сайтам сохранять cookies'),
            trailing: Switch(
              value: SettingsService.getAcceptCookies(),
              onChanged: (val) async {
                await SettingsService.setAcceptCookies(val);
                setState(() {});
              },
            ),
          ),
          const Divider(height: 1),
          ListTile(
            leading: Icon(CupertinoIcons.trash,
                color: Theme.of(context).primaryColor),
            title: const Text('Очистить cookies'),
            subtitle: const Text('Удалить все сохраненные cookies'),
            onTap: () {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Cookies очищены')),
              );
            },
          ),
          const Divider(height: 1),
          ListTile(
            leading: Icon(CupertinoIcons.square_stack_3d_up_fill,
                color: Theme.of(context).primaryColor),
            title: const Text('Очистить кэш'),
            subtitle: const Text('Удалить кэшированные данные'),
            onTap: () {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Кэш очищен')),
              );
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage("assets/images/secondb.png"),
          fit: BoxFit.cover,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          const SizedBox(height: 24),
          AnimateOnDisplay(
            delayMs: 0,
            rippleFade: true,
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        height: 98,
                        width: 98,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.06),
                        ),
                      ),
                      Image.asset(
                        'assets/icons/browser_logo.png',
                        width: 48,
                        height: 48,
                        fit: BoxFit.contain,
                      )
                    ],
                  ),
                ),
                Text(
                  'Bloball.',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 34,
                    color: Colors.white,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Изучай интернет без помех.',
                  style: TextStyle(
                      fontSize: 16,
                      color: Colors.white.withOpacity(0.75),
                      fontWeight: FontWeight.w400),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: AnimateOnDisplay(
              delayMs: 100,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF2C2C2E).withOpacity(0.8),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.1),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(CupertinoIcons.search,
                        size: 18, color: Colors.white.withOpacity(0.55)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          hintText: "Поиск в Интернете",
                          hintStyle: TextStyle(
                              color: Colors.white.withOpacity(0.55)),
                        ),
                        onSubmitted: (query) {
                          if (query.isNotEmpty) {
                            _performSearch(query);
                          }
                        },
                      ),
                    ),
                    if (_searchController.text.isNotEmpty)
                      IconButton(
                        splashRadius: 18,
                        icon: const Icon(Icons.close,
                            size: 18, color: Colors.white70),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {});
                        },
                      ),
                    IconButton(
                      splashRadius: 22,
                      icon: const Icon(CupertinoIcons.arrow_up_right_square_fill,
                          size: 20, color: Colors.white70),
                      onPressed: () {
                        if (_searchController.text.isNotEmpty) {
                          _performSearch(_searchController.text);
                        }
                      },
                    ),
                    IconButton(
                      splashRadius: 22,
                      icon: const Icon(CupertinoIcons.ellipsis_vertical,
                          size: 20, color: Colors.white70),
                      onPressed: _showBrowserSettings,
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Панелька с табами ниже поиска
          AnimateOnDisplay(
            delayMs: 150,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Row(
                  children: [
                    _buildBrowserTab('Поиск', 0),
                    const SizedBox(width: 8),
                    _buildBrowserTab('История', 1),
                    const SizedBox(width: 8),
                    _buildBrowserTab('Закладки', 2),
                    const SizedBox(width: 8),
                    _buildBrowserTab('Загрузки', 3),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Скроллируемый контент
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                children: [
                  AnimateOnDisplay(
                    delayMs: 200,
                    child: _buildBrowserContent(),
                  ),
                  if (_selectedTab == 0) ...[
                    const SizedBox(height: 24),
                    AnimateOnDisplay(
                      delayMs: 300,
                      child: Column(
                        children: [
                          Text('Настройки',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 20,
                                  color: Colors.white)),
                          const SizedBox(height: 18),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 100), // Отступ для скролла
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBrowserTab(String label, int index) {
    final isSelected = _selectedTab == index;
    return GestureDetector(
      onTap: () {
        if (SettingsService.getVibrationEnabled()) {
          HapticFeedback.lightImpact();
        }
        setState(() => _selectedTab = index);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).primaryColor.withOpacity(0.2)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.white.withOpacity(0.6),
            fontSize: 15,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    );
  }

  Widget _buildBrowserContent() {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      transitionBuilder: (Widget child, Animation<double> animation) {
        return FadeTransition(
          opacity: CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
          ),
          child: child,
        );
      },
      child: _buildTabContent(),
    );
  }

  Widget _buildTabContent() {
    switch (_selectedTab) {
      case 1:
        return _buildHistoryTab(key: const ValueKey('history'));
      case 2:
        return _buildBookmarksTab(key: const ValueKey('bookmarks'));
      case 3:
        return _buildDownloadsTab(key: const ValueKey('downloads'));
      default:
        return _buildSearchTab(key: const ValueKey('search'));
    }
  }

  Widget _buildSearchTab({Key? key}) {
    return Container(
      key: key,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 40),
          Icon(CupertinoIcons.search,
              size: 64, color: Colors.white.withOpacity(0.3)),
          const SizedBox(height: 16),
          Text('Начните поиск',
              style: TextStyle(color: Colors.white.withOpacity(0.5))),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildHistoryTab({Key? key}) {
    if (_history.isEmpty) {
      return Container(
        key: key,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(CupertinoIcons.clock_fill,
                  size: 64, color: Colors.white.withOpacity(0.3)),
              const SizedBox(height: 16),
              Text('История пуста',
                  style: TextStyle(color: Colors.white.withOpacity(0.5))),
            ],
          ),
        ),
      );
    }
    return Container(
      key: key,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: _history.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          return AnimateOnDisplay(
            delayMs: 50 * index,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            BrowserView(initialUrl: item['url'] as String),
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      children: [
                        Icon(
                          CupertinoIcons.globe,
                          color: Colors.white.withOpacity(0.6),
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item['title'] as String,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w500,
                                  fontSize: 16,
                                  color: Colors.white,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                item['url'] as String,
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.6),
                                  fontSize: 14,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                BrowserService.formatTime(item['time'] as String),
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.4),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: Icon(
                            CupertinoIcons.xmark,
                            size: 18,
                            color: Colors.white.withOpacity(0.4),
                          ),
                          onPressed: () async {
                            await BrowserService.removeFromHistory(index);
                            await _refreshHistory();
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          )
              .animate()
              .fadeIn(
                  duration: const Duration(milliseconds: 280),
                  delay: Duration(milliseconds: 50 * index),
                  curve: Curves.easeOutCubic)
              .slideX(
                  begin: -0.1,
                  end: 0,
                  duration: const Duration(milliseconds: 320),
                  delay: Duration(milliseconds: 50 * index),
                  curve: Curves.easeOutCubic);
        }).toList(),
      ),
    );
  }

  Widget _buildDownloadsTab({Key? key}) {
    if (_downloads.isEmpty) {
      return Container(
        key: key,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(CupertinoIcons.arrow_down_circle_fill,
                  size: 64, color: Colors.white.withOpacity(0.3)),
              const SizedBox(height: 16),
              Text('Загрузки отсутствуют',
                  style: TextStyle(color: Colors.white.withOpacity(0.5))),
            ],
          ),
        ),
      );
    }
    return ListView.builder(
      key: key,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _downloads.length,
      itemBuilder: (context, index) {
        final download = _downloads[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () async {
                final filePath = download['filePath'] as String?;
                if (filePath != null) {
                  final file = File(filePath);
                  if (await file.exists()) {
                    try {
                      final uri = Uri.file(filePath);
                      if (await canLaunchUrl(uri)) {
                        await launchUrl(uri);
                      } else {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Не удалось открыть файл: ${download['fileName']}'),
                            ),
                          );
                        }
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Ошибка открытия файла: $e')),
                        );
                      }
                    }
                  } else {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Файл не найден')),
                      );
                    }
                  }
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    Icon(
                      CupertinoIcons.doc_fill,
                      color: Colors.white.withOpacity(0.6),
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            download['fileName'] as String,
                            style: const TextStyle(
                              fontWeight: FontWeight.w500,
                              fontSize: 16,
                              color: Colors.white,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            download['url'] as String,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.6),
                              fontSize: 14,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            BrowserService.formatTime(download['time'] as String),
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.4),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        CupertinoIcons.folder_fill,
                        size: 18,
                        color: Colors.white.withOpacity(0.4),
                      ),
                      onPressed: () async {
                        final filePath = download['filePath'] as String?;
                        if (filePath != null) {
                          final file = File(filePath);
                          if (await file.exists()) {
                            try {
                              final parentDir = file.parent.path;
                              final uri = Uri.file(parentDir);
                              if (await canLaunchUrl(uri)) {
                                await launchUrl(uri);
                              }
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Ошибка: $e')),
                                );
                              }
                            }
                          }
                        }
                      },
                    ),
                    IconButton(
                      icon: Icon(
                        CupertinoIcons.xmark,
                        size: 18,
                        color: Colors.white.withOpacity(0.4),
                      ),
                      onPressed: () async {
                        await BrowserService.removeDownload(index);
                        await _refreshDownloads();
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBookmarksTab({Key? key}) {
    return ListView(
      key: key,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      children: [
        if (_bookmarks.isNotEmpty) ...[
          ..._bookmarks.asMap().entries.map((entry) {
            final index = entry.key;
            final bookmark = entry.value;
            return Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  Navigator.of(context).push(
                    NavigationService.createSlideTransitionRoute(
                      BrowserView(initialUrl: bookmark['url'] as String),
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      Icon(
                        CupertinoIcons.bookmark_fill,
                        color: Colors.white.withOpacity(0.6),
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              bookmark['title'] as String,
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                                fontSize: 16,
                                color: Colors.white,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              bookmark['url'] as String,
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.6),
                                fontSize: 14,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          CupertinoIcons.xmark,
                          size: 18,
                          color: Colors.white.withOpacity(0.4),
                        ),
                        onPressed: () async {
                          await BrowserService.removeBookmark(bookmark['url'] as String);
                          await _refreshBookmarks();
                        },
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ] else ...[
          // Пустое состояние
          const SizedBox(height: 100),
          Center(
            child: Column(
              children: [
                Icon(
                  CupertinoIcons.bookmark,
                  size: 64,
                  color: Colors.white.withOpacity(0.3),
                ),
                const SizedBox(height: 16),
                Text(
                  'Нет закладок',
                  style: TextStyle(color: Colors.white.withOpacity(0.5)),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 12),
        GlassButton(
          onPressed: () {
            final controller = TextEditingController();
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                backgroundColor: Colors.black87,
                title: const Text('Добавить закладку'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: controller,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        hintText: 'URL (например: https://example.com)',
                        hintStyle: TextStyle(color: Colors.white54),
                      ),
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Отмена'),
                  ),
                  TextButton(
                    onPressed: () async {
                      final url = controller.text.trim();
                      if (url.isNotEmpty) {
                        final uri =
                            url.startsWith('http') ? url : 'https://$url';
                        await BrowserService.addBookmark(uri, uri);
                        await _refreshBookmarks();
                        if (mounted) {
                          Navigator.of(context).pop();
                          setState(() => _selectedTab = 2);
                        }
                      }
                    },
                    child: const Text('Добавить'),
                  ),
                ],
              ),
            );
          },
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(CupertinoIcons.plus,
                  color: Theme.of(context).primaryColor, size: 20),
              const SizedBox(width: 8),
              const Text('Добавить закладку', style: TextStyle(fontSize: 16)),
            ],
          ),
        ),
      ],
    );
  }
}

class _CallsPage extends StatelessWidget {
  _CallsPage();

  final List<_CallEntry> _calls = const [
    _CallEntry(
        name: 'Друг пятки',
        subtitle: 'Голосовой звонок',
        time: 'Сегодня, 10:12',
        isMissed: false),
    _CallEntry(
        name: 'Команда Mimu',
        subtitle: 'Видео-звонок',
        time: 'Вчера, 19:45',
        isMissed: false),
    _CallEntry(
        name: 'Саппорт',
        subtitle: 'Пропущенный звонок',
        time: 'Вчера, 08:31',
        isMissed: true),
  ];

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView.builder(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
        itemCount: _calls.length,
        itemBuilder: (context, index) {
          final entry = _calls[index];
          return AnimateOnDisplay(
            delayMs: 60 * index,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: GlassContainer(
                child: ListTile(
                  leading: CircleAvatar(
                    radius: 24,
                    backgroundColor:
                        Theme.of(context).primaryColor.withOpacity(0.2),
                    child: Icon(
                      entry.isMissed
                          ? CupertinoIcons.phone_down_fill
                          : CupertinoIcons.phone_fill,
                      color: entry.isMissed
                          ? Colors.redAccent
                          : Theme.of(context).primaryColor,
                    ),
                  ),
                  title: Text(entry.name,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w600)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        entry.subtitle,
                        style: TextStyle(
                            color: Colors.white.withOpacity(0.65),
                            fontSize: 12),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        entry.time,
                        style: TextStyle(
                            color: Colors.white.withOpacity(0.5), fontSize: 11),
                      ),
                    ],
                  ),
                  trailing: IconButton(
                    icon: const Icon(CupertinoIcons.phone_fill),
                    color: Theme.of(context).primaryColor,
                    onPressed: () {
                      Navigator.of(context).push(
                        PageRouteBuilder(
                          pageBuilder: (context, animation, secondaryAnimation) =>
                              CallScreen(
                                userName: entry.name,
                                avatarAsset: 'assets/images/avatar_placeholder.png',
                                isIncoming: false,
                                isVideoCall: false,
                              ),
                          transitionsBuilder:
                              (context, animation, secondaryAnimation, child) {
                            final tween = Tween(
                                    begin: const Offset(1.0, 0.0), end: Offset.zero)
                                .chain(CurveTween(curve: Curves.easeOutQuart));

                            return SlideTransition(
                              position: animation.drive(tween),
                              child: child,
                            );
                          },
                          transitionDuration: const Duration(milliseconds: 350),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _CallEntry {
  final String name;
  final String subtitle;
  final String time;
  final bool isMissed;
  const _CallEntry({
    required this.name,
    required this.subtitle,
    required this.time,
    required this.isMissed,
  });
}

// --- Premium Page ---
class _PremiumPage extends StatelessWidget {
  const _PremiumPage();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Fox illustration
            AnimateOnDisplay(
              child: Image.asset(
                'assets/images/fox_premium.png',
                height: 200,
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(height: 24),
            // Title with checkmark
            AnimateOnDisplay(
              delayMs: 100,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Купите Mimu Premium',
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      CupertinoIcons.check_mark,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            // Three text blocks
            AnimateOnDisplay(
              delayMs: 200,
              child: GlassContainer(
                padding: const EdgeInsets.all(20),
                child: Text(
                  'Мы знаем, что приватность - это неприкасаемое право каждого человека на земле, и всеми силами пытаемся бороться с активным ущемлением этого права',
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      height: 1.5,
                      fontSize: 15),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            const SizedBox(height: 16),
            AnimateOnDisplay(
              delayMs: 300,
              child: GlassContainer(
                padding: const EdgeInsets.all(20),
                child: Text(
                  'Видя активную борьбу с приватностью и свободой, мы создали Mimu - безопасный и защищенный мессенджер, а позже и экосистема с браузером Bloball.',
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      height: 1.5,
                      fontSize: 15),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            const SizedBox(height: 16),
            AnimateOnDisplay(
              delayMs: 400,
              child: GlassContainer(
                padding: const EdgeInsets.all(20),
                child: Text(
                  'Проект стал бесплатным. Без рекламы мы будем работать в убыток. Поддержите нас. Купите Mimu Premium',
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      height: 1.5,
                      fontSize: 15),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            const SizedBox(height: 32),
            // Subscription plans
            AnimateOnDisplay(
              delayMs: 500,
              child: Row(
                children: [
                  Expanded(
                    child: GlassContainer(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Mimu Premium',
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 8),
                          GlassButton(
                            onPressed: () => _showComingSoon(context),
                            child: const Padding(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                              child: Text('Функции',
                                  style: TextStyle(fontSize: 12)),
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text('499 рублей/мес',
                              style: TextStyle(
                                  fontSize: 14, fontWeight: FontWeight.w500)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GlassContainer(
                      padding: const EdgeInsets.all(16),
                      decoration: Theme.of(context)
                          .extension<GlassTheme>()!
                          .baseGlass
                          .copyWith(
                            border: Border.all(
                              color: Theme.of(context)
                                  .primaryColor
                                  .withOpacity(0.5),
                              width: 2,
                            ),
                          ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Mimu Ultra',
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 4),
                          Text(
                            'Популярен!',
                            style: TextStyle(
                              fontSize: 11,
                              color: Theme.of(context).primaryColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          GlassButton(
                            onPressed: () => _showComingSoon(context),
                            child: const Padding(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                              child: Text('Функции',
                                  style: TextStyle(fontSize: 12)),
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text('899 рублей/мес',
                              style: TextStyle(
                                  fontSize: 14, fontWeight: FontWeight.w500)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
            // Bottom message
            AnimateOnDisplay(
              delayMs: 600,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Мы будем очень благодарны',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.favorite, color: Colors.pink, size: 20),
                  const SizedBox(width: 4),
                  Transform.translate(
                    offset: const Offset(-8, 0),
                    child: const Icon(Icons.favorite,
                        color: Colors.pink, size: 20),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PremiumPlanCard extends StatelessWidget {
  final String title;
  final String price;
  final String subtitle;
  final bool isPopular;

  const _PremiumPlanCard({
    required this.title,
    required this.price,
    required this.subtitle,
    required this.isPopular,
  });

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).primaryColor;
    return GlassContainer(
      padding: const EdgeInsets.all(18),
      decoration: Theme.of(context).extension<GlassTheme>()!.baseGlass.copyWith(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
                color: isPopular
                    ? primary.withOpacity(0.4)
                    : Colors.white.withOpacity(0.08),
                width: 1.6),
          ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isPopular)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: primary.withOpacity(0.25),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text('Популярно',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
            ),
          if (isPopular) const SizedBox(height: 10),
          Text(title,
              style:
                  const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Text(price,
              style:
                  const TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Text(subtitle,
              style:
                  TextStyle(color: Colors.white.withOpacity(0.7), height: 1.4)),
          const SizedBox(height: 16),
          GlassButton(
            onPressed: () => _showComingSoon(context),
            child: const Padding(
              padding: EdgeInsets.symmetric(vertical: 10),
              child: Center(child: Text('Выбрать')),
            ),
          ),
        ],
      ),
    );
  }
}

class _PremiumTag extends StatelessWidget {
  final String label;
  const _PremiumTag({required this.label});

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: Theme.of(context).extension<GlassTheme>()!.baseGlass.copyWith(
            borderRadius: BorderRadius.circular(14),
            color: Colors.white.withOpacity(0.08),
          ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(CupertinoIcons.sparkles,
              size: 16, color: Theme.of(context).primaryColor),
          const SizedBox(width: 6),
          Text(label,
              style:
                  const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

void _showComingSoon(BuildContext context) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (_) => GlassContainer(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Скоро будет доступно',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 10),
            Text(
              'Команда уже собирает билды с подпиской. Получите ранний доступ, подписавшись на Mimu Premium внутри ближайших обновлений.',
              style:
                  TextStyle(color: Colors.white.withOpacity(0.75), height: 1.4),
            ),
            const SizedBox(height: 18),
            GlassButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 10),
                child: Center(child: Text('Жду')),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
