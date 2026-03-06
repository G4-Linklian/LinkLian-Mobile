import 'package:LinkLian/core/utils/logger.dart';

import '../../core/services/api_client.dart';

class CommunityMemberRepository {
  final ApiClient _api = ApiClient();

Future<void> join(int communityId) async {
  final res = await _api.post(
    '/community/member/$communityId',
  );

  AppLogger.info("[community]JOIN RESPONSE => ${res.data}");

}
  Future<Map<String, dynamic>> leave(int communityId) async {
    final res = await _api.delete<Map<String, dynamic>>(
      '/community/member/$communityId',
    );

    final root = res.data ?? {};

    if (root['success'] != true) {
      throw Exception(root['message'] ?? 'Leave failed');
    }

    return root['data'];
  }

  Future<void> approve(int communityId, int userId) async {
    final res = await _api.post<Map<String, dynamic>>(
      '/community/member/$communityId/approve/$userId',
    );

    final root = res.data ?? {};

    if (root['success'] != true) {
      throw Exception(root['message'] ?? 'Approve failed');
    }
  }

  Future<List<dynamic>> getMembers(int communityId) async {
    final res = await _api.get<Map<String, dynamic>>(
      '/community/member/$communityId',
    );

    final root = res.data ?? {};

    if (root['success'] != true) {
      throw Exception(root['message'] ?? 'Fetch members failed');
    }

    return root['data']?['members'] ?? [];
  }

  Future<List<dynamic>> getPendingMembers(int communityId) async {
    final res = await _api.get<Map<String, dynamic>>(
      '/community/member/$communityId/pending',
    );

    final root = res.data ?? {};

    if (root['success'] != true) {
      throw Exception(root['message'] ?? 'Fetch pending failed');
    }

    return root['data']?['members'] ?? [];
  }

  Future<bool> reject(int communityId, int userId) async {
    final res = await _api.delete<Map<String, dynamic>>(
      '/community/member/$communityId/reject/$userId',
    );

    final root = res.data ?? {};

    if (root['success'] != true) {
      throw Exception(root['message'] ?? 'Reject failed');
    }

    return true;
  }
}
