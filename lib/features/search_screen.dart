import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:mimu/data/chat_store.dart';
import 'package:mimu/data/user_api.dart';
import 'package:mimu/data/models/chat_models.dart';
import 'package:mimu/shared/app_styles.dart';
import 'package:mimu/shared/glass_widgets.dart';
import 'package:mimu/app/routes.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  Timer? _debounce;
  
  // Local results
  List<ChatContact> _contactResults = [];
  List<ChatThread> _chatResults = [];
  List<ChatMessage> _messageResults = []; // Requires complex search in all chats
  
  // Global results
  List<Map<String, dynamic>> _globalResults = [];
  bool _isSearchingGlobal = false;
  
  late TabController _tabController;
  final List<String> _tabs = ['Контакты', 'Чаты', 'Глобальный'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _searchController.addListener(_onSearchChanged);
    
    // Auto-focus search
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _searchFocusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    _debounce?.cancel();
    _tabController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _performSearch(_searchController.text);
    });
  }

  Future<void> _performSearch(String query) async {
    if (query.isEmpty) {
      setState(() {
        _contactResults = [];
        _chatResults = [];
        _globalResults = [];
      });
      return;
    }

    final chatStore = context.read<ChatStore>();
    final queryLower = query.toLowerCase();

    // 1. Search Contacts
    final contacts = chatStore.contacts.where((c) {
      return c.name.toLowerCase().contains(queryLower) || 
             c.id.toLowerCase().contains(queryLower);
    }).toList();

    // 2. Search Chats (Titles)
    final chats = chatStore.threads.where((t) {
      return t.title.toLowerCase().contains(queryLower);
    }).toList();

    setState(() {
      _contactResults = contacts;
      _chatResults = chats;
      _isSearchingGlobal = true;
    });

    // 3. Search Global Users
    try {
      final global = await UserApi().searchUsers(query);
      if (mounted) {
        setState(() {
          _globalResults = global;
        });
      }
    } catch (e) {
      debugPrint('Global search error: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isSearchingGlobal = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
        title: Container(
          decoration: AppStyles.surfaceDecoration(borderRadius: 18),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
          child: CupertinoSearchTextField(
            controller: _searchController,
            focusNode: _searchFocusNode,
            placeholder: 'Поиск...',
            style: const TextStyle(color: Colors.white, fontFamily: AppStyles.fontFamily),
            placeholderStyle: TextStyle(color: Colors.white.withOpacity(0.5), fontFamily: AppStyles.fontFamily),
            backgroundColor: Colors.transparent,
            prefixIcon: Icon(CupertinoIcons.search, color: Colors.white.withOpacity(0.5)),
            suffixIcon: const Icon(CupertinoIcons.xmark_circle_fill, color: Colors.white),
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            decoration: BoxDecoration(
              color: AppStyles.backgroundOled,
              border: Border(
                bottom: BorderSide(color: AppStyles.borderColor, width: AppStyles.borderWidth),
              ),
            ),
            child: TabBar(
              controller: _tabController,
              indicatorColor: Theme.of(context).primaryColor,
              indicatorWeight: 3,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white60,
              tabs: _tabs.map((t) => Tab(text: t)).toList(),
            ),
          ),
        ),
      ),
      body: Container(
        color: AppStyles.backgroundOled,
        child: SafeArea(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildContactsList(),
              _buildChatsList(),
              _buildGlobalList(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContactsList() {
    if (_contactResults.isEmpty && _searchController.text.isNotEmpty) {
      return _buildEmptyState('Контакты не найдены');
    }
    return ListView.builder(
      itemCount: _contactResults.length,
      itemBuilder: (context, index) {
        final contact = _contactResults[index];
        return GlassContainer(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          padding: EdgeInsets.zero,
          child: ListTile(
            leading: CircleAvatar(
              backgroundImage: AssetImage(contact.avatarAsset),
            ),
            title: Text(contact.name, style: const TextStyle(color: Colors.white)),
            subtitle: Text(contact.id, style: TextStyle(color: Colors.white.withOpacity(0.6))),
            onTap: () {
              // Open chat with this contact
              _openChatWithContact(contact);
            },
          ),
        );
      },
    );
  }

  Widget _buildChatsList() {
    if (_chatResults.isEmpty && _searchController.text.isNotEmpty) {
      return _buildEmptyState('Чаты не найдены');
    }
    return ListView.builder(
      itemCount: _chatResults.length,
      itemBuilder: (context, index) {
        final chat = _chatResults[index];
        return GlassContainer(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          padding: EdgeInsets.zero,
          child: ListTile(
            leading: CircleAvatar(
              backgroundImage: AssetImage(chat.avatarAsset),
            ),
            title: Text(chat.title, style: const TextStyle(color: Colors.white)),
            subtitle: Text(
              chat.isGroup ? 'Группа' : 'Чат',
              style: TextStyle(color: Colors.white.withOpacity(0.6)),
            ),
            onTap: () {
              Navigator.pushNamed(context, AppRoutes.chat, arguments: {'chatId': chat.id});
            },
          ),
        );
      },
    );
  }

  Widget _buildGlobalList() {
    if (_isSearchingGlobal) {
      return const Center(child: CupertinoActivityIndicator(color: Colors.white));
    }
    if (_globalResults.isEmpty && _searchController.text.isNotEmpty) {
      return _buildEmptyState('Пользователи не найдены');
    }
    return ListView.builder(
      itemCount: _globalResults.length,
      itemBuilder: (context, index) {
        final user = _globalResults[index];
        final publicId = user['public_id'] ?? 'unknown';
        final displayName = user['display_name'] ?? publicId;
        final avatarUrl = user['avatar_url']; // TODO: Handle network image

        return GlassContainer(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          padding: EdgeInsets.zero,
          child: ListTile(
            leading: CircleAvatar(
              backgroundImage: const AssetImage('assets/images/avatar_placeholder.png'),
              // TODO: NetworkImage(avatarUrl) if exists
            ),
            title: Text(displayName, style: const TextStyle(color: Colors.white)),
            subtitle: Text('@$publicId', style: TextStyle(color: Colors.white.withOpacity(0.6))),
            trailing: GlassButton(
              onPressed: () => _startChatWithUser(publicId, displayName),
              child: const Icon(CupertinoIcons.chat_bubble_text, color: Colors.white, size: 20),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(CupertinoIcons.search, size: 64, color: Colors.white.withOpacity(0.2)),
          const SizedBox(height: 16),
          Text(message, style: TextStyle(color: Colors.white.withOpacity(0.5))),
        ],
      ),
    );
  }

  void _openChatWithContact(ChatContact contact) async {
    final chatStore = context.read<ChatStore>();
    // Check if chat exists
    final existingChat = chatStore.threads.firstWhere(
      (t) => !t.isGroup && t.participantIds.contains(contact.id),
      orElse: () => ChatThread.empty(),
    );

    if (existingChat.id.isNotEmpty) {
      Navigator.pushNamed(context, AppRoutes.chat, arguments: {'chatId': existingChat.id});
    } else {
      // Create new chat
      final chatId = await chatStore.createChat(
        title: contact.name,
        participantIds: [contact.id],
        avatarAsset: contact.avatarAsset,
      );
      if (mounted) {
        Navigator.pushNamed(context, AppRoutes.chat, arguments: {'chatId': chatId});
      }
    }
  }

  void _startChatWithUser(String publicId, String displayName) async {
    final chatStore = context.read<ChatStore>();
    
    // Check local contacts first to avoid duplicates
    final existingContact = chatStore.contactById(publicId);
    if (existingContact != null) {
      _openChatWithContact(existingContact);
      return;
    }

    // Add to contacts temporarily or permanently?
    // Usually we just start a chat.
    final contact = ChatContact(
      id: publicId,
      name: displayName,
      avatarAsset: 'assets/images/avatar_placeholder.png',
    );
    await chatStore.addContact(contact);
    _openChatWithContact(contact);
  }
}
