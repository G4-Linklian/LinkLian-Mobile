import 'package:LinkLian/core/utils/api_response_parser.dart';
import 'package:LinkLian/core/utils/logger.dart';

import '../../../../core/services/api_client.dart';

class CommunityMemberRepository {
  final ApiClient _api = ApiClient();

  Future<void> join(int communityId) async {
    final res = await _api.post('/community/member/$communityId');

    appLog.info("[community]JOIN RESPONSE => ${res.data}");
  }

  Future<Map<String, dynamic>> leave(int communityId) async {
    final res = await _api.delete<Map<String, dynamic>>(
      '/community/member/$communityId',
    );

    final data = ApiResponseParser.parseObject<Map<String, dynamic>>(
      res.data,
      (json) => json,
    );

    return data ?? {};
  }

  Future<void> approve(int communityId, int userId) async {
    final res = await _api.post<Map<String, dynamic>>(
      '/community/member/$communityId/approve/$userId',
    );

    final data = ApiResponseParser.parseObject<Map<String, dynamic>>(
      res.data,
      (json) => json,
    );

    if (data == null) {
      throw Exception('Approve failed');
    }
  }

  Future<List<dynamic>> getMembers(int communityId) async {
    final res = await _api.get<Map<String, dynamic>>(
      '/community/member/$communityId',
    );

    final data =
        ApiResponseParser.parseObject<Map<String, dynamic>>(
          res.data,
          (json) => json,
        ) ??
        {};

    return data['members'] ?? [];
  }

  Future<List<dynamic>> getPendingMembers(int communityId) async {
    final res = await _api.get<Map<String, dynamic>>(
      '/community/member/$communityId/pending',
    );

    final data =
        ApiResponseParser.parseObject<Map<String, dynamic>>(
          res.data,
          (json) => json,
        ) ??
        {};

    return data['members'] ?? [];
  }

  Future<bool> reject(int communityId, int userId) async {
    final res = await _api.delete<Map<String, dynamic>>(
      '/community/member/$communityId/reject/$userId',
    );

    final data = ApiResponseParser.parseObject<Map<String, dynamic>>(
      res.data,
      (json) => json,
    );

    if (data == null) {
      throw Exception('Reject failed');
    }

    return true;
  }
}
