import 'dart:convert';

enum ChatMessageType { text, image, voice, file, call, location, poll, sticker }

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
    );
  }
}

class ChatThread {
  final String id;
  final String title;
  final String avatarAsset;
  final bool isGroup;
  final ChatType chatType;
  final List<String> participantIds;
  final List<ChatMessage> messages;
  final DateTime updatedAt;

  const ChatThread({
    required this.id,
    required this.title,
    required this.avatarAsset,
    required this.isGroup,
    this.chatType = ChatType.regular,
    required this.participantIds,
    required this.messages,
    required this.updatedAt,
  });

  ChatThread copyWith({
    String? id,
    String? title,
    String? avatarAsset,
    bool? isGroup,
    ChatType? chatType,
    List<String>? participantIds,
    List<ChatMessage>? messages,
    DateTime? updatedAt,
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
    };
  }

  factory ChatThread.fromJson(Map<String, dynamic> json) {
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
