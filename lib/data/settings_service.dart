import 'package:shared_preferences/shared_preferences.dart';
import 'package:mimu/data/user_api.dart';

class SettingsService {
  static const String _keyNotifications = 'notifications_enabled';
  static const String _keyAutoDownload = 'auto_download_video';
  static const String _keyTrafficSaving = 'traffic_saving';
  static const String _keyVSLEnabled = 'vsl_enabled';
  static const String _keySearchEngine = 'search_engine';
  static const String _keyConnection = 'connection';
  static const String _keyTheme = 'theme';
  static const String _keyFont = 'font';
  static const String _keyFontSize = 'font_size';
  static const String _keyFontStyle = 'font_style';
  static const String _keySoundProfile = 'sound_profile';
  static const String _keyAudioInput = 'audio_input';
  static const String _keyAudioOutput = 'audio_output';
  static const String _keyVibrationEnabled = 'vibration_enabled';
  static const String _keySearchByUsername = 'search_by_username';
  static const String _keyAutoDeleteMessages = 'auto_delete_messages';
  static const String _keyAutoDeleteTime = 'auto_delete_time';
  static const String _keyNotificationSoundEnabled =
      'notification_sound_enabled';
  static const String _keyNotificationPreview = 'notification_preview_enabled';
  static const String _keyInAppNotifications = 'notification_in_app';
  static const String _keyNotificationSoundName = 'notification_sound_name';
  static const String _keyUseProxy = 'connection_use_proxy';
  static const String _keyAutoConnect = 'connection_auto_connect';
  static const String _keyAppLanguage = 'app_language';
  static const String _keyAutoCleanMedia = 'auto_clean_media';
  static const String _keyAutoCleanCache = 'auto_clean_cache';
  static const String _keyAutoBackupEnabled = 'auto_backup_enabled';
  static const String _keySyncEnabled = 'sync_enabled';

  static SharedPreferences? _prefs;

  static Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  // Notifications
  static bool getNotificationsEnabled() =>
      _prefs?.getBool(_keyNotifications) ?? true;
  static Future<void> setNotificationsEnabled(bool value) async {
    await _prefs?.setBool(_keyNotifications, value);
  }

  static bool getNotificationSoundEnabled() =>
      _prefs?.getBool(_keyNotificationSoundEnabled) ?? true;
  static Future<void> setNotificationSoundEnabled(bool value) async {
    await _prefs?.setBool(_keyNotificationSoundEnabled, value);
  }

  static bool getNotificationPreviewEnabled() =>
      _prefs?.getBool(_keyNotificationPreview) ?? true;
  static Future<void> setNotificationPreviewEnabled(bool value) async {
    await _prefs?.setBool(_keyNotificationPreview, value);
  }

  static bool getInAppNotificationsEnabled() =>
      _prefs?.getBool(_keyInAppNotifications) ?? true;
  static Future<void> setInAppNotificationsEnabled(bool value) async {
    await _prefs?.setBool(_keyInAppNotifications, value);
  }

  static String getNotificationSoundName() =>
      _prefs?.getString(_keyNotificationSoundName) ?? 'Mimu';
  static Future<void> setNotificationSoundName(String value) async {
    await _prefs?.setString(_keyNotificationSoundName, value);
  }

  // Video
  static bool getAutoDownloadVideo() =>
      _prefs?.getBool(_keyAutoDownload) ?? false;
  static Future<void> setAutoDownloadVideo(bool value) async {
    await _prefs?.setBool(_keyAutoDownload, value);
  }

  static bool getTrafficSaving() => _prefs?.getBool(_keyTrafficSaving) ?? false;
  static Future<void> setTrafficSaving(bool value) async {
    await _prefs?.setBool(_keyTrafficSaving, value);
  }

  static bool getSyncEnabled() => _prefs?.getBool(_keySyncEnabled) ?? true;
  static Future<void> setSyncEnabled(bool value) async {
    await _prefs?.setBool(_keySyncEnabled, value);
  }

  // Browser
  static bool getVSLEnabled() => _prefs?.getBool(_keyVSLEnabled) ?? true;
  static Future<void> setVSLEnabled(bool value) async {
    await _prefs?.setBool(_keyVSLEnabled, value);
  }

  static String getSearchEngine() =>
      _prefs?.getString(_keySearchEngine) ?? 'Google';
  static Future<void> setSearchEngine(String value) async {
    await _prefs?.setString(_keySearchEngine, value);
  }

  static String getConnection() =>
      _prefs?.getString(_keyConnection) ?? 'Default';
  static Future<void> setConnection(String value) async {
    await _prefs?.setString(_keyConnection, value);
  }

  static bool getUseProxy() => _prefs?.getBool(_keyUseProxy) ?? false;
  static Future<void> setUseProxy(bool value) async {
    await _prefs?.setBool(_keyUseProxy, value);
  }

  static bool getAutoConnect() => _prefs?.getBool(_keyAutoConnect) ?? true;
  static Future<void> setAutoConnect(bool value) async {
    await _prefs?.setBool(_keyAutoConnect, value);
  }

  // Appearance
  static String getTheme() => _prefs?.getString(_keyTheme) ?? 'Mimu Classical';
  static Future<void> setTheme(String value) async {
    await _prefs?.setString(_keyTheme, value);
  }

  static String getLanguage() =>
      _prefs?.getString(_keyAppLanguage) ?? 'Русский';
  static Future<void> setLanguage(String value) async {
    await _prefs?.setString(_keyAppLanguage, value);
  }

  static String getFont() => _prefs?.getString(_keyFont) ?? 'Inter';
  static Future<void> setFont(String value) async {
    await _prefs?.setString(_keyFont, value);
  }

  static int getFontSize() => _prefs?.getInt(_keyFontSize) ?? 16;
  static Future<void> setFontSize(int value) async {
    await _prefs?.setInt(_keyFontSize, value);
  }

  static String getFontStyle() => _prefs?.getString(_keyFontStyle) ?? 'Regular';
  static Future<void> setFontStyle(String value) async {
    await _prefs?.setString(_keyFontStyle, value);
  }

  // Sound
  static String getSoundProfile() =>
      _prefs?.getString(_keySoundProfile) ?? 'Mimu';
  static Future<void> setSoundProfile(String value) async {
    await _prefs?.setString(_keySoundProfile, value);
  }

  static String getAudioInput() =>
      _prefs?.getString(_keyAudioInput) ?? 'Default';
  static Future<void> setAudioInput(String value) async {
    await _prefs?.setString(_keyAudioInput, value);
  }

  static String getAudioOutput() =>
      _prefs?.getString(_keyAudioOutput) ?? 'Default';
  static Future<void> setAudioOutput(String value) async {
    await _prefs?.setString(_keyAudioOutput, value);
  }

  // Optimization
  static const String _keyPowerSaving = 'power_saving';
  static const String _keyAnimationsEnabled = 'animations_enabled';
  static const String _keyOptimizeMimu = 'optimize_mimu';

  static bool getPowerSaving() => _prefs?.getBool(_keyPowerSaving) ?? false;
  static Future<void> setPowerSaving(bool value) async {
    await _prefs?.setBool(_keyPowerSaving, value);
  }

  static bool getAnimationsEnabled() =>
      _prefs?.getBool(_keyAnimationsEnabled) ?? true;
  static Future<void> setAnimationsEnabled(bool value) async {
    await _prefs?.setBool(_keyAnimationsEnabled, value);
  }

  static bool getOptimizeMimu() => _prefs?.getBool(_keyOptimizeMimu) ?? false;
  static Future<void> setOptimizeMimu(bool value) async {
    await _prefs?.setBool(_keyOptimizeMimu, value);
  }

  // Chat state persistence
  static const String _keyChatMessages = 'chat_messages_';
  static const String _keyLastOpenedChat = 'last_opened_chat';
  static const String _keyChatScrollPosition = 'chat_scroll_';

  static Future<void> saveChatMessages(
      String chatId, List<Map<String, dynamic>> messages) async {
    await _prefs?.setString(
        _keyChatMessages + chatId,
        messages
            .map((m) =>
                '${m['id']}|${m['type']}|${m['text'] ?? ''}|${m['isMe']}|${m['time']}')
            .join(';'));
  }

  static List<Map<String, dynamic>>? getChatMessages(String chatId) {
    final data = _prefs?.getString(_keyChatMessages + chatId);
    if (data == null) return null;
    return data.split(';').map((s) {
      final parts = s.split('|');
      return {
        'id': parts[0],
        'type': parts[1],
        'text': parts[2],
        'isMe': parts[3] == 'true',
        'time': parts[4],
      };
    }).toList();
  }

  static Future<void> saveLastOpenedChat(String chatId) async {
    await _prefs?.setString(_keyLastOpenedChat, chatId);
  }

  static String? getLastOpenedChat() => _prefs?.getString(_keyLastOpenedChat);

  static Future<void> saveChatScrollPosition(
      String chatId, double position) async {
    await _prefs?.setDouble(_keyChatScrollPosition + chatId, position);
  }

  static double? getChatScrollPosition(String chatId) =>
      _prefs?.getDouble(_keyChatScrollPosition + chatId);

  // Vibration
  static bool getVibrationEnabled() =>
      _prefs?.getBool(_keyVibrationEnabled) ?? true;
  static Future<void> setVibrationEnabled(bool value) async {
    await _prefs?.setBool(_keyVibrationEnabled, value);
  }

  // Privacy
  static const String _keyLastSeenEnabled = 'last_seen_enabled';
  static const String _keyReadReceiptsEnabled = 'read_receipts_enabled';
  static const String _keyProfilePhotoVisible = 'profile_photo_visible';
  static const String _keyStatusVisible = 'status_visible';
  static const String _keyWhoCanAddMe = 'who_can_add_me';
  static const String _keyTwoFactorEnabled = 'two_factor_enabled';
  static const String _keyScreenLockEnabled = 'screen_lock_enabled';
  static const String _keySelfDestructMessages = 'self_destruct_messages';
  static const String _keyEncryptionEnabled = 'encryption_enabled';

  static bool getSearchByUsername() =>
      _prefs?.getBool(_keySearchByUsername) ?? true;
  static Future<void> setSearchByUsername(bool value) async {
    await _prefs?.setBool(_keySearchByUsername, value);
  }

  static bool getAutoDeleteMessages() =>
      _prefs?.getBool(_keyAutoDeleteMessages) ?? false;
  static Future<void> setAutoDeleteMessages(bool value) async {
    await _prefs?.setBool(_keyAutoDeleteMessages, value);
  }

  static int getAutoDeleteTime() =>
      _prefs?.getInt(_keyAutoDeleteTime) ?? 24; // hours, default 24
  static Future<void> setAutoDeleteTime(int hours) async {
    await _prefs?.setInt(_keyAutoDeleteTime, hours);
  }

  static bool getLastSeenEnabled() =>
      _prefs?.getBool(_keyLastSeenEnabled) ?? true;
  static Future<void> setLastSeenEnabled(bool value) async {
    await _prefs?.setBool(_keyLastSeenEnabled, value);
  }

  static bool getReadReceiptsEnabled() =>
      _prefs?.getBool(_keyReadReceiptsEnabled) ?? true;
  static Future<void> setReadReceiptsEnabled(bool value) async {
    await _prefs?.setBool(_keyReadReceiptsEnabled, value);
  }

  static bool getProfilePhotoVisible() =>
      _prefs?.getBool(_keyProfilePhotoVisible) ?? true;
  static Future<void> setProfilePhotoVisible(bool value) async {
    await _prefs?.setBool(_keyProfilePhotoVisible, value);
  }

  static bool getStatusVisible() => _prefs?.getBool(_keyStatusVisible) ?? true;
  static Future<void> setStatusVisible(bool value) async {
    await _prefs?.setBool(_keyStatusVisible, value);
  }

  static String getWhoCanAddMe() => _prefs?.getString(_keyWhoCanAddMe) ?? 'Все';
  static Future<void> setWhoCanAddMe(String value) async {
    await _prefs?.setString(_keyWhoCanAddMe, value);
  }

  static bool getTwoFactorEnabled() =>
      _prefs?.getBool(_keyTwoFactorEnabled) ?? false;
  static Future<void> setTwoFactorEnabled(bool value) async {
    await _prefs?.setBool(_keyTwoFactorEnabled, value);
  }

  static bool getScreenLockEnabled() =>
      _prefs?.getBool(_keyScreenLockEnabled) ?? false;
  static Future<void> setScreenLockEnabled(bool value) async {
    await _prefs?.setBool(_keyScreenLockEnabled, value);
  }

  static bool getSelfDestructMessages() =>
      _prefs?.getBool(_keySelfDestructMessages) ?? false;
  static Future<void> setSelfDestructMessages(bool value) async {
    await _prefs?.setBool(_keySelfDestructMessages, value);
  }

  static bool getEncryptionEnabled() =>
      _prefs?.getBool(_keyEncryptionEnabled) ?? true;
  static Future<void> setEncryptionEnabled(bool value) async {
    await _prefs?.setBool(_keyEncryptionEnabled, value);
  }

  // Chat settings
  static const String _keyChatMuted = 'chat_muted_';
  static const String _keyChatPinned = 'chat_pinned_';

  static bool isChatMuted(String chatId) =>
      _prefs?.getBool(_keyChatMuted + chatId) ?? false;
  static Future<void> setChatMuted(String chatId, bool muted) async {
    await _prefs?.setBool(_keyChatMuted + chatId, muted);
  }

  static bool isChatPinned(String chatId) =>
      _prefs?.getBool(_keyChatPinned + chatId) ?? false;
  static Future<void> setChatPinned(String chatId, bool pinned) async {
    await _prefs?.setBool(_keyChatPinned + chatId, pinned);
  }

  // New chat display settings
  static const String _keyCompactMode = 'compact_mode';
  static const String _keyShowTimestamps = 'show_timestamps';
  static const String _keyShowReadReceipts = 'show_read_receipts';
  static const String _keyShowOnlineStatus = 'show_online_status';
  static const String _keyShowOnline = 'show_online'; // Server-side setting
  
  static bool getShowOnline() => _prefs?.getBool(_keyShowOnline) ?? true;
  static Future<void> setShowOnline(bool value) async {
    await _prefs?.setBool(_keyShowOnline, value);
    try {
      await UserApi().updateMe(settings: _serverSettingsMap());
    } catch (_) {}
  }
  static const String _keySwipeToReply = 'swipe_to_reply';
  static const String _keyDoubleTapToLike = 'double_tap_to_like';
  static const String _keySwipeNavigation = 'swipe_navigation';
  static const String _keyMessageAnimations = 'message_animations';
  static const String _keyHapticFeedback = 'haptic_feedback';
  static const String _keySoundEffects = 'sound_effects';
  static const String _keyShowTypingIndicator = 'show_typing_indicator';
  static const String _keyAutoPlayMedia = 'auto_play_media';
  static const String _keySaveMediaToGallery = 'save_media_to_gallery';
  static const String _keyShowMessagePreview = 'show_message_preview';
  static const String _keyGroupNotifications = 'group_notifications';
  static const String _keyMentionNotifications = 'mention_notifications';
  static const String _keyReactionNotifications = 'reaction_notifications';

  static bool getCompactMode() => _prefs?.getBool(_keyCompactMode) ?? false;
  static Future<void> setCompactMode(bool value) async {
    await _prefs?.setBool(_keyCompactMode, value);
  }

  static bool getShowTimestamps() =>
      _prefs?.getBool(_keyShowTimestamps) ?? true;
  static Future<void> setShowTimestamps(bool value) async {
    await _prefs?.setBool(_keyShowTimestamps, value);
  }

  static bool getShowReadReceipts() =>
      _prefs?.getBool(_keyShowReadReceipts) ?? true;
  static Future<void> setShowReadReceipts(bool value) async {
    await _prefs?.setBool(_keyShowReadReceipts, value);
  }

  static bool getShowOnlineStatus() =>
      _prefs?.getBool(_keyShowOnlineStatus) ?? true;
  static Future<void> setShowOnlineStatus(bool value) async {
    await _prefs?.setBool(_keyShowOnlineStatus, value);
  }

  static bool getSwipeToReply() => _prefs?.getBool(_keySwipeToReply) ?? false;
  static Future<void> setSwipeToReply(bool value) async {
    await _prefs?.setBool(_keySwipeToReply, value);
  }

  static bool getSwipeNavigation() =>
      _prefs?.getBool(_keySwipeNavigation) ?? false;
  static Future<void> setSwipeNavigation(bool value) async {
    await _prefs?.setBool(_keySwipeNavigation, value);
  }

  static bool getDoubleTapToLike() =>
      _prefs?.getBool(_keyDoubleTapToLike) ?? true;
  static Future<void> setDoubleTapToLike(bool value) async {
    await _prefs?.setBool(_keyDoubleTapToLike, value);
  }

  static bool getMessageAnimations() =>
      _prefs?.getBool(_keyMessageAnimations) ?? true;
  static Future<void> setMessageAnimations(bool value) async {
    await _prefs?.setBool(_keyMessageAnimations, value);
  }

  static bool getHapticFeedback() =>
      _prefs?.getBool(_keyHapticFeedback) ?? true;
  static Future<void> setHapticFeedback(bool value) async {
    await _prefs?.setBool(_keyHapticFeedback, value);
  }

  static bool getSoundEffects() => _prefs?.getBool(_keySoundEffects) ?? true;
  static Future<void> setSoundEffects(bool value) async {
    await _prefs?.setBool(_keySoundEffects, value);
  }

  static bool getShowTypingIndicator() =>
      _prefs?.getBool(_keyShowTypingIndicator) ?? true;
  static Future<void> setShowTypingIndicator(bool value) async {
    await _prefs?.setBool(_keyShowTypingIndicator, value);
  }

  static bool getAutoPlayMedia() => _prefs?.getBool(_keyAutoPlayMedia) ?? true;
  static Future<void> setAutoPlayMedia(bool value) async {
    await _prefs?.setBool(_keyAutoPlayMedia, value);
  }

  static bool getSaveMediaToGallery() =>
      _prefs?.getBool(_keySaveMediaToGallery) ?? true;
  static Future<void> setSaveMediaToGallery(bool value) async {
    await _prefs?.setBool(_keySaveMediaToGallery, value);
  }

  static bool getShowMessagePreview() =>
      _prefs?.getBool(_keyShowMessagePreview) ?? true;
  static Future<void> setShowMessagePreview(bool value) async {
    await _prefs?.setBool(_keyShowMessagePreview, value);
  }

  static bool getGroupNotifications() =>
      _prefs?.getBool(_keyGroupNotifications) ?? true;
  static Future<void> setGroupNotifications(bool value) async {
    await _prefs?.setBool(_keyGroupNotifications, value);
  }

  static bool getMentionNotifications() =>
      _prefs?.getBool(_keyMentionNotifications) ?? true;
  static Future<void> setMentionNotifications(bool value) async {
    await _prefs?.setBool(_keyMentionNotifications, value);
  }

  static bool getReactionNotifications() =>
      _prefs?.getBool(_keyReactionNotifications) ?? true;
  static Future<void> setReactionNotifications(bool value) async {
    await _prefs?.setBool(_keyReactionNotifications, value);
  }

  // Browser settings
  static const String _keyReadingMode = 'reading_mode';
  static const String _keyAutoTranslate = 'auto_translate';
  static const String _keyPhishingProtection = 'phishing_protection';
  static const String _keyHttpsOnly = 'https_only';
  static const String _keyBiometricProtection = 'biometric_protection';
  static const String _keyAcceptCookies = 'accept_cookies';

  static bool getReadingMode() => _prefs?.getBool(_keyReadingMode) ?? false;
  static Future<void> setReadingMode(bool value) async {
    await _prefs?.setBool(_keyReadingMode, value);
  }

  static bool getAutoTranslate() => _prefs?.getBool(_keyAutoTranslate) ?? false;
  static Future<void> setAutoTranslate(bool value) async {
    await _prefs?.setBool(_keyAutoTranslate, value);
  }

  static bool getPhishingProtection() =>
      _prefs?.getBool(_keyPhishingProtection) ?? true;
  static Future<void> setPhishingProtection(bool value) async {
    await _prefs?.setBool(_keyPhishingProtection, value);
  }

  static bool getHttpsOnly() => _prefs?.getBool(_keyHttpsOnly) ?? false;
  static Future<void> setHttpsOnly(bool value) async {
    await _prefs?.setBool(_keyHttpsOnly, value);
  }

  static bool getBiometricProtection() =>
      _prefs?.getBool(_keyBiometricProtection) ?? false;
  static Future<void> setBiometricProtection(bool value) async {
    await _prefs?.setBool(_keyBiometricProtection, value);
  }

  static bool getAcceptCookies() => _prefs?.getBool(_keyAcceptCookies) ?? true;
  static Future<void> setAcceptCookies(bool value) async {
    await _prefs?.setBool(_keyAcceptCookies, value);
  }

  // Storage & backup
  static bool getAutoCleanMedia() =>
      _prefs?.getBool(_keyAutoCleanMedia) ?? true;
  static Future<void> setAutoCleanMedia(bool value) async {
    await _prefs?.setBool(_keyAutoCleanMedia, value);
  }

  static bool getAutoCleanCache() =>
      _prefs?.getBool(_keyAutoCleanCache) ?? false;
  static Future<void> setAutoCleanCache(bool value) async {
    await _prefs?.setBool(_keyAutoCleanCache, value);
  }

  static bool getAutoBackupEnabled() =>
      _prefs?.getBool(_keyAutoBackupEnabled) ?? true;
  static Future<void> setAutoBackupEnabled(bool value) async {
    await _prefs?.setBool(_keyAutoBackupEnabled, value);
  }

  // Chat style settings
  static const String _keyGradientBubbles = 'gradient_bubbles';
  static const String _keyMessageShadow = 'message_shadow';
  static const String _keyDecorativeIcons = 'decorative_icons';

  static bool getGradientBubbles() =>
      _prefs?.getBool(_keyGradientBubbles) ?? true;
  static Future<void> setGradientBubbles(bool value) async {
    await _prefs?.setBool(_keyGradientBubbles, value);
  }

  static bool getMessageShadow() => _prefs?.getBool(_keyMessageShadow) ?? true;
  static Future<void> setMessageShadow(bool value) async {
    await _prefs?.setBool(_keyMessageShadow, value);
  }

  static bool getDecorativeIcons() =>
      _prefs?.getBool(_keyDecorativeIcons) ?? true;
  static Future<void> setDecorativeIcons(bool value) async {
    await _prefs?.setBool(_keyDecorativeIcons, value);
  }

  // Bubble radius and background opacity
  static const String _keyBubbleRadius = 'bubble_radius';
  static const String _keyChatBackgroundOpacity = 'chat_background_opacity';

  static double getBubbleRadius() =>
      _prefs?.getDouble(_keyBubbleRadius) ?? 16.0;
  static Future<void> setBubbleRadius(double value) async {
    await _prefs?.setDouble(_keyBubbleRadius, value);
  }

  static double getChatBackgroundOpacity() =>
      _prefs?.getDouble(_keyChatBackgroundOpacity) ?? 0.3;
  static Future<void> setChatBackgroundOpacity(double value) async {
    await _prefs?.setDouble(_keyChatBackgroundOpacity, value);
  }

  // Additional privacy settings
  static const String _keyHideLastSeenTime = 'hide_last_seen_time';
  static const String _keyHideTypingStatus = 'hide_typing_status';
  static const String _keyScreenshotProtection = 'screenshot_protection';
  static const String _keyHideForwarding = 'hide_forwarding';
  static const String _keyHideCopying = 'hide_copying';
  static const String _keyHidePhoneNumber = 'hide_phone_number';
  static const String _keyCloudSync = 'cloud_sync';

  static bool getHideLastSeenTime() =>
      _prefs?.getBool(_keyHideLastSeenTime) ?? false;
  static Future<void> setHideLastSeenTime(bool value) async {
    await _prefs?.setBool(_keyHideLastSeenTime, value);
    try {
      await UserApi().updateMe(settings: _serverSettingsMap());
    } catch (_) {}
  }

  /// Карта настроек для сервера (show_online, hide_last_seen). Используется при синхронизации.
  static Map<String, dynamic> _serverSettingsMap() => {
        'show_online': getShowOnline(),
        'hide_last_seen': getHideLastSeenTime(),
      };

  static bool getHideTypingStatus() =>
      _prefs?.getBool(_keyHideTypingStatus) ?? false;
  static Future<void> setHideTypingStatus(bool value) async {
    await _prefs?.setBool(_keyHideTypingStatus, value);
  }

  static bool getScreenshotProtection() =>
      _prefs?.getBool(_keyScreenshotProtection) ?? false;
  static Future<void> setScreenshotProtection(bool value) async {
    await _prefs?.setBool(_keyScreenshotProtection, value);
  }

  static bool getHideForwarding() =>
      _prefs?.getBool(_keyHideForwarding) ?? false;
  static Future<void> setHideForwarding(bool value) async {
    await _prefs?.setBool(_keyHideForwarding, value);
  }

  static bool getHideCopying() => _prefs?.getBool(_keyHideCopying) ?? false;
  static Future<void> setHideCopying(bool value) async {
    await _prefs?.setBool(_keyHideCopying, value);
  }

  static bool getHidePhoneNumber() =>
      _prefs?.getBool(_keyHidePhoneNumber) ?? false;
  static Future<void> setHidePhoneNumber(bool value) async {
    await _prefs?.setBool(_keyHidePhoneNumber, value);
  }

  static bool getCloudSync() => _prefs?.getBool(_keyCloudSync) ?? true;
  static Future<void> setCloudSync(bool value) async {
    await _prefs?.setBool(_keyCloudSync, value);
  }

  // Group specific settings
  static const String _keyGroupOnlyAdminsPost = 'group_only_admins_post_';
  static const String _keyGroupOnlyAdminsAdd = 'group_only_admins_add_';
  static const String _keyGroupVisibility = 'group_visibility_';

  static bool getGroupOnlyAdminsPost(String chatId) =>
      _prefs?.getBool(_keyGroupOnlyAdminsPost + chatId) ?? false;
  static Future<void> setGroupOnlyAdminsPost(String chatId, bool value) async {
    await _prefs?.setBool(_keyGroupOnlyAdminsPost + chatId, value);
  }

  static bool getGroupOnlyAdminsAdd(String chatId) =>
      _prefs?.getBool(_keyGroupOnlyAdminsAdd + chatId) ?? false;
  static Future<void> setGroupOnlyAdminsAdd(String chatId, bool value) async {
    await _prefs?.setBool(_keyGroupOnlyAdminsAdd + chatId, value);
  }

  static bool getGroupVisibility(String chatId) =>
      _prefs?.getBool(_keyGroupVisibility + chatId) ?? true;
  static Future<void> setGroupVisibility(String chatId, bool value) async {
    await _prefs?.setBool(_keyGroupVisibility + chatId, value);
  }

  // Premium
  static const String _keyIsPremium = 'is_premium';
  static const String _keyPremiumType = 'premium_type';

  static bool getIsPremium() => _prefs?.getBool(_keyIsPremium) ?? false;
  static Future<void> setIsPremium(bool value) async {
    await _prefs?.setBool(_keyIsPremium, value);
  }

  static String getPremiumType() => _prefs?.getString(_keyPremiumType) ?? '';
  static Future<void> setPremiumType(String type) async {
    await _prefs?.setString(_keyPremiumType, type);
  }
}
