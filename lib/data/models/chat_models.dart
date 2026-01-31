import 'dart:convert';

enum ChatMessageType { text, image, voice, file, call, location, poll, sticker, video }

enum ChatType { regular, secret, cloud, group, channel }

class ChatMessage {
  final String id;
  final ChatMessageType type;
  final String? text;
  final String? mediaPath;
  final int? voiceDurationSeconds;
  final bool isMe;
  final DateTime timestamp;
  final bool isRead;
  final bool isEdited;
  final Map<String, int> reactions;
  final String? editedText;
  /// View count (from metadata.view_count on server)
  final int viewCount;
  /// TTL in seconds for secret/self-destruct (from metadata)
  final int? ttlSeconds;

  const ChatMessage({
    required this.id,
    required this.type,
    this.text,
    this.mediaPath,
    this.voiceDurationSeconds,
    required this.isMe,
    required this.timestamp,
    this.isRead = false,
    this.isEdited = false,
    this.reactions = const {},
    this.editedText,
    this.viewCount = 0,
    this.ttlSeconds,
  });

  ChatMessage copyWith({
    String? id,
    ChatMessageType? type,
    String? text,
    String? mediaPath,
    int? voiceDurationSeconds,
    bool? isMe,
    DateTime? timestamp,
    bool? isRead,
    bool? isEdited,
    Map<String, int>? reactions,
    String? editedText,
    int? viewCount,
    int? ttlSeconds,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      type: type ?? this.type,
      text: text ?? this.text,
      mediaPath: mediaPath ?? this.mediaPath,
      voiceDurationSeconds: voiceDurationSeconds ?? this.voiceDurationSeconds,
      isMe: isMe ?? this.isMe,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
      isEdited: isEdited ?? this.isEdited,
      reactions: reactions ?? this.reactions,
      editedText: editedText ?? this.editedText,
      viewCount: viewCount ?? this.viewCount,
      ttlSeconds: ttlSeconds ?? this.ttlSeconds,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'text': text,
      'mediaPath': mediaPath,
      'voiceDurationSeconds': voiceDurationSeconds,
      'isMe': isMe,
      'timestamp': timestamp.toIso8601String(),
      'isRead': isRead,
      'isEdited': isEdited,
      'reactions': reactions,
      'editedText': editedText,
      'viewCount': viewCount,
      'ttlSeconds': ttlSeconds,
    };
  }

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] as String,
      type: ChatMessageType.values.firstWhere(
        (t) => t.name == json['type'],
        orElse: () => ChatMessageType.text,
      ),
      text: json['text'] as String?,
      mediaPath: json['mediaPath'] as String?,
      voiceDurationSeconds: json['voiceDurationSeconds'] as int?,
      isMe: json['isMe'] as bool? ?? false,
      timestamp: DateTime.tryParse(json['timestamp'] as String? ?? '') ?? DateTime.now(),
      isRead: json['isRead'] as bool? ?? false,
      isEdited: json['isEdited'] as bool? ?? false,
      reactions: (json['reactions'] as Map?)?.map((key, value) => MapEntry(key.toString(), (value as num).toInt())) ?? const {},
      editedText: json['editedText'] as String?,
      viewCount: (json['viewCount'] as num?)?.toInt() ?? (json['metadata'] is Map ? ((json['metadata'] as Map)['view_count'] as num?)?.toInt() ?? 0 : 0),
      ttlSeconds: (json['ttlSeconds'] as num?)?.toInt() ?? (json['metadata'] is Map ? ((json['metadata'] as Map)['ttl_seconds'] as num?)?.toInt() : null),
    );
  }
}

/// Role in channel/group: only owner/admin can post in channels
enum ParticipantRole { owner, admin, member, restricted }

class ChatThread {
  final String id;
  final String title;
  final String avatarAsset;
  final bool isGroup;
  final ChatType chatType;
  final List<String> participantIds;
  final List<ChatMessage> messages;
  final DateTime updatedAt;
  final String? description;
  /// Public channel handle, e.g. @mimu_news; null = private
  final String? username;
  /// Cached subscriber count (channels/groups)
  final int memberCount;
  /// Private invite link token: t.mimu.app/join/{inviteToken}
  final String? inviteToken;
  /// Current user's role (for channels: only owner/admin can post)
  final ParticipantRole? participantRole;
  /// ID of pinned message (from API or set locally after pin)
  final String? pinnedMessageId;

  const ChatThread({
    required this.id,
    required this.title,
    required this.avatarAsset,
    required this.isGroup,
    this.chatType = ChatType.regular,
    required this.participantIds,
    required this.messages,
    required this.updatedAt,
    this.description,
    this.username,
    this.memberCount = 0,
    this.inviteToken,
    this.participantRole,
    this.pinnedMessageId,
  });

  /// In channels, only owner/admin can post; members see Mute/Unmute
  bool get canPostInChannel =>
      chatType != ChatType.channel ||
      (participantRole == ParticipantRole.owner || participantRole == ParticipantRole.admin);

  ChatThread copyWith({
    String? id,
    String? title,
    String? avatarAsset,
    bool? isGroup,
    ChatType? chatType,
    List<String>? participantIds,
    List<ChatMessage>? messages,
    DateTime? updatedAt,
    String? description,
    String? username,
    int? memberCount,
    String? inviteToken,
    ParticipantRole? participantRole,
    String? pinnedMessageId,
    bool clearPinnedMessage = false,
  }) {
    return ChatThread(
      id: id ?? this.id,
      title: title ?? this.title,
      avatarAsset: avatarAsset ?? this.avatarAsset,
      isGroup: isGroup ?? this.isGroup,
      chatType: chatType ?? this.chatType,
      participantIds: participantIds ?? this.participantIds,
      messages: messages ?? this.messages,
      updatedAt: updatedAt ?? this.updatedAt,
      description: description ?? this.description,
      username: username ?? this.username,
      memberCount: memberCount ?? this.memberCount,
      inviteToken: inviteToken ?? this.inviteToken,
      participantRole: participantRole ?? this.participantRole,
      pinnedMessageId: clearPinnedMessage ? null : (pinnedMessageId ?? this.pinnedMessageId),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'avatarAsset': avatarAsset,
      'isGroup': isGroup,
      'chatType': chatType.name,
      'participantIds': participantIds,
      'messages': messages.map((m) => m.toJson()).toList(),
      'updatedAt': updatedAt.toIso8601String(),
      'description': description,
      'username': username,
      'memberCount': memberCount,
      'inviteToken': inviteToken,
      'participantRole': participantRole?.name,
      'pinnedMessageId': pinnedMessageId,
    };
  }

  factory ChatThread.empty() {
    return ChatThread(
      id: '',
      title: '',
      avatarAsset: '',
      isGroup: false,
      participantIds: [],
      messages: [],
      updatedAt: DateTime.now(),
    );
  }

  factory ChatThread.fromJson(Map<String, dynamic> json) {
    ParticipantRole? role;
    final roleStr = json['participantRole'] as String?;
    if (roleStr != null) {
      for (final r in ParticipantRole.values) {
        if (r.name == roleStr) { role = r; break; }
      }
    }
    return ChatThread(
      id: json['id'] as String,
      title: json['title'] as String,
      avatarAsset: json['avatarAsset'] as String,
      isGroup: json['isGroup'] as bool? ?? false,
      chatType: ChatType.values.firstWhere(
        (t) => t.name == json['chatType'],
        orElse: () => ChatType.regular,
      ),
      participantIds: (json['participantIds'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList(),
      messages: (json['messages'] as List<dynamic>? ?? [])
          .map((m) => ChatMessage.fromJson(Map<String, dynamic>.from(m as Map)))
          .toList(),
      updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? '') ?? DateTime.now(),
      description: json['description'] as String?,
      username: json['username'] as String?,
      memberCount: (json['memberCount'] as num?)?.toInt() ?? 0,
      inviteToken: json['inviteToken'] as String?,
      participantRole: role,
      pinnedMessageId: json['pinnedMessageId'] as String?,
    );
  }

  static List<ChatThread> decodeList(String source) {
    final data = jsonDecode(source) as List<dynamic>;
    return data.map((item) => ChatThread.fromJson(Map<String, dynamic>.from(item as Map))).toList();
  }

  static String encodeList(List<ChatThread> chats) {
    return jsonEncode(chats.map((c) => c.toJson()).toList());
  }

  bool get isOnline => false;
  bool get isTyping => false;
}

class ChatContact {
  final String id;
  final String name;
  final String avatarAsset;

  const ChatContact({
    required this.id,
    required this.name,
    required this.avatarAsset,
  });

  ChatContact copyWith({
    String? id,
    String? name,
    String? avatarAsset,
  }) {
    return ChatContact(
      id: id ?? this.id,
      name: name ?? this.name,
      avatarAsset: avatarAsset ?? this.avatarAsset,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'avatarAsset': avatarAsset,
      };

  factory ChatContact.fromJson(Map<String, dynamic> json) => ChatContact(
        id: json['id'] as String,
        name: json['name'] as String,
        avatarAsset: json['avatarAsset'] as String,
      );
}
