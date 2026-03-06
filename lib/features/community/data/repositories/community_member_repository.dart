import 'package:LinkLian/core/utils/api_response_parser.dart';
import 'package:LinkLian/features/community/data/models/community_member_model.dart';
import '../../../../core/services/api_client.dart';

class CommunityMemberRepository {
  final ApiClient _api = ApiClient();

  Future<bool> join(int communityId) async {
    final res = await _api.post('/community/member/$communityId');

    final success = ApiResponseParser.parseSuccess(res.data);

    if (!success) {
      throw Exception('Join community failed');
    }

    return true;
  }

  Future<bool> leave(int communityId) async {
    final res = await _api.delete<Map<String, dynamic>>(
      '/community/member/$communityId',
    );

    final success = ApiResponseParser.parseSuccess(res.data);

    if (!success) {
      throw Exception('Leave community failed');
    }

    return true;
  }

  Future<bool> approve(int communityId, int userId) async {
    final res = await _api.post(
      '/community/member/$communityId/approve/$userId',
    );

    final success = ApiResponseParser.parseSuccess(res.data);

    if (!success) {
      throw Exception('Approve failed');
    }

    return true;
  }

  Future<List<CommunityMemberModel>> getMembers(int communityId) async {
    final res = await _api.get<Map<String, dynamic>>(
      '/community/member/$communityId',
    );

    final root = res.data ?? {};

    return ApiResponseParser.parseList(
      root['data']?['members'],
      CommunityMemberModel.fromJson,
    );
  }

  Future<List<CommunityMemberModel>> getPendingMembers(int communityId) async {
    final res = await _api.get<Map<String, dynamic>>(
      '/community/member/$communityId/pending',
    );

    final root = res.data ?? {};

    return ApiResponseParser.parseList(
      root['data']?['members'],
      CommunityMemberModel.fromJson,
    );
  }

  Future<bool> reject(int communityId, int userId) async {
    final res = await _api.delete<Map<String, dynamic>>(
      '/community/member/$communityId/reject/$userId',
    );

    final success = ApiResponseParser.parseSuccess(res.data);

    if (!success) {
      throw Exception('Reject failed');
    }

    return true;
  }
}
