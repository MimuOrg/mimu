import 'package:mimu/data/services/dio_api_client.dart';
import 'package:mimu/features/calls/turn_config.dart';

class CallsApi {
  final _dio = DioApiClient().dio;

  /// TURN credentials (server returns snake_case: urls, username, credential, ttl)
  Future<TurnConfig> getTurnCredentials() async {
    final resp = await _dio.get('/calls/turn-credentials');
    final data = resp.data is Map ? Map<String, dynamic>.from(resp.data as Map) : null;
    if (data == null) throw StateError('Invalid TURN credentials response');
    return TurnConfig.fromJson(data);
  }
}


