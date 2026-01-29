class TurnConfig {
  final List<String> urls;
  final String username;
  final String credential;
  final int ttl;

  TurnConfig({
    required this.urls,
    required this.username,
    required this.credential,
    required this.ttl,
  });

  factory TurnConfig.fromJson(Map<String, dynamic> json) {
    return TurnConfig(
      urls: (json['urls'] as List).cast<String>(),
      username: json['username'] as String,
      credential: json['credential'] as String,
      ttl: (json['ttl'] as num).toInt(),
    );
  }
}


