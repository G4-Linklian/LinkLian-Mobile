import '../../core/services/api_client.dart';

class CommunityMemberRepository {
  final ApiClient _api = ApiClient();

  Future<void> join(int communityId) async {
    await _api.post('/community/member/$communityId');
  }

  Future<void> leave(int communityId) async {
    await _api.delete('/community/member/$communityId');
  }

  Future<void> approve(int communityId, int userId) async {
    await _api.post('/community/member/$communityId/approve/$userId');
  }

  Future<List<dynamic>> getMembers(int communityId) async {
    final res = await _api.get('/community/member/$communityId');
    return res.data ?? [];
  }
  Future<List<dynamic>> getPendingMembers(int communityId) async {
  final res =
      await _api.get('/community/member/$communityId/pending');
  return res.data ?? [];
}

Future<void> reject(int communityId, int userId) async {
  await _api.delete(
      '/community/member/$communityId/reject/$userId');
}

}
