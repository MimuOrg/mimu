import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class ChannelService {
  static const String _keySubscriptions = 'channel_subscriptions';
  static const String _keyChannelPosts = 'channel_posts_';
  static const String _keyChannelNotifications = 'channel_notifications_';
  static const String _keyChannelId = 'channel_id_';

  static SharedPreferences? _prefs;

  static Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  static Future<List<String>> getSubscribedChannels() async {
    await init();
    final data = _prefs?.getStringList(_keySubscriptions) ?? [];
    return data;
  }

  static Future<bool> isSubscribed(String channelName) async {
    await init();
    final subscriptions = await getSubscribedChannels();
    return subscriptions.contains(channelName);
  }

  static Future<void> subscribe(String channelName) async {
    await init();
    final subscriptions = await getSubscribedChannels();
    if (!subscriptions.contains(channelName)) {
      subscriptions.add(channelName);
      await _prefs?.setStringList(_keySubscriptions, subscriptions);
    }
  }

  static Future<void> unsubscribe(String channelName) async {
    await init();
    final subscriptions = await getSubscribedChannels();
    subscriptions.remove(channelName);
    await _prefs?.setStringList(_keySubscriptions, subscriptions);
  }

  static Future<List<Map<String, dynamic>>> getChannelPosts(String channelName) async {
    await init();
    final data = _prefs?.getString(_keyChannelPosts + channelName);
    if (data == null) return [];
    try {
      return List<Map<String, dynamic>>.from(jsonDecode(data));
    } catch (_) {
      return [];
    }
  }

  static Future<void> addPost(String channelName, String text) async {
    await init();
    final posts = await getChannelPosts(channelName);
    final now = DateTime.now();
    posts.insert(0, {
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'text': text,
      'time': '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}',
      'date': _formatDate(now),
      'timestamp': now.toIso8601String(),
    });
    await _prefs?.setString(_keyChannelPosts + channelName, jsonEncode(posts));
  }

  static Future<void> editPost(String channelName, String postId, String newText) async {
    await init();
    final posts = await getChannelPosts(channelName);
    final index = posts.indexWhere((p) => p['id'] == postId);
    if (index != -1) {
      posts[index]['text'] = newText;
      posts[index]['edited'] = true;
      await _prefs?.setString(_keyChannelPosts + channelName, jsonEncode(posts));
    }
  }

  static Future<void> deletePost(String channelName, String postId) async {
    await init();
    final posts = await getChannelPosts(channelName);
    posts.removeWhere((p) => p['id'] == postId);
    await _prefs?.setString(_keyChannelPosts + channelName, jsonEncode(posts));
  }

  static Future<bool> getChannelNotifications(String channelName) async {
    await init();
    return _prefs?.getBool(_keyChannelNotifications + channelName) ?? true;
  }

  static Future<void> setChannelNotifications(String channelName, bool enabled) async {
    await init();
    await _prefs?.setBool(_keyChannelNotifications + channelName, enabled);
  }

  static String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inDays == 0) {
      return 'Сегодня';
    } else if (diff.inDays == 1) {
      return 'Вчера';
    } else if (diff.inDays < 7) {
      return '${diff.inDays} дня назад';
    } else {
      return '${date.day}.${date.month}.${date.year}';
    }
  }

  static Future<List<Map<String, dynamic>>> searchInChannel(String channelName, String query) async {
    final posts = await getChannelPosts(channelName);
    final lowerQuery = query.toLowerCase();
    return posts.where((post) => 
      (post['text'] as String).toLowerCase().contains(lowerQuery)
    ).toList();
  }
}

