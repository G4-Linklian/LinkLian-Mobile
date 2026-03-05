import 'package:LinkLian/core/utils/logger.dart';
import '../../classes/data/models/class_feed_model.dart';
import '../../../core/services/api_client.dart';
import '../../auth/controller/auth_controller.dart';
import 'package:get/get.dart';

class ClassFeedRepository {
  final ApiClient _apiClient = ApiClient();

  Future<List<ClassFeedModel>> getClassFeed({
    required int semesterId,
    int offset = 0,
    int limit = 10,
  }) async {
    final auth = Get.find<AuthController>();
    final userId = auth.userId.value;
    final roleName = auth.roleName.value;

    if (userId == null) throw Exception('User not authenticated');

    appLog.info('🧪 semesterId=$semesterId, userId=$userId, role=$roleName, offset=$offset, limit=$limit');

    final isTeacher = roleName == 'teacher' || roleName == 'instructor';
    final endpoint = isTeacher ? '/social-feed/feed/teacher' : '/social-feed/feed/student';

    final response = await _apiClient.get<Map<String, dynamic>>(
      endpoint,
      queryParameters: {'user_id': userId, 'semester_id': semesterId, 'offset': offset, 'limit': limit},
    );

    final responseMap = response.data;
    if (responseMap == null || responseMap['data'] == null) {
      throw Exception('Failed to fetch class feed');
    }

    final List responseData = responseMap['data'] as List;
    return responseData.map((e) => ClassFeedModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<ClassFeedModel?> getClassDetail({required int sectionId}) async {
    try {
      final response = await _apiClient.get<Map<String, dynamic>>(
        '/social-feed/post',
        queryParameters: {'section_id': sectionId},
      );
      final responseMap = response.data;
      if (responseMap == null || responseMap['data'] == null) throw Exception('Failed to fetch class feed');
      final List data = responseMap['data'];
      return ClassFeedModel.fromJson(data.first as Map<String, dynamic>);
    } catch (e) {
      appLog.info('Error fetching class detail: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>> getClassDetailFeed({
    required int sectionId,
    String? postType,
    bool? teacherOnly,
  }) async {
    final response = await _apiClient.get<Map<String, dynamic>>(
      '/social-feed/post',
      queryParameters: {'section_id': sectionId, if (postType != null) 'type': postType},
    );
    return {'success': true, 'data': response.data?['data'] ?? []};
  }

  Future<List<Map<String, dynamic>>?> getSectionEducators({required int sectionId}) async {
    try {
      final response = await _apiClient.get<List<dynamic>>('/social-feed/section-educators/$sectionId');
      if (response.data != null) {
        return response.data!.map((e) => e as Map<String, dynamic>).toList();
      }
      return null;
    } catch (e) {
      appLog.info('❌ Error fetching section educators: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> getClassInfo({required int sectionId}) async {
    try {
      final response = await _apiClient.get('/social-feed/class-info/$sectionId');
      appLog.info('📦 class-info raw response = ${response.data}');
      if (response.data is Map<String, dynamic>) {
        if (response.data['data'] != null) return Map<String, dynamic>.from(response.data['data']);
        return Map<String, dynamic>.from(response.data);
      }
      return null;
    } catch (e) {
      appLog.info('❌ Error fetching class info: $e');
      return null;
    }
  }
}
