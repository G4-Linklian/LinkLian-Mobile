import '../model/class_feed_model.dart';
import '../../core/services/api_client.dart';
import '../../features/auth/controller/auth_controller.dart';
import 'package:get/get.dart';
import 'package:flutter/foundation.dart';

class ClassFeedRepository {
  final ApiClient _apiClient = ApiClient();

  /// GET CLASS FEED BY SEMESTER (based on user role)
  Future<List<ClassFeedModel>> getClassFeed({
    required int semesterId,
    int offset = 0,
    int limit = 10,
  }) async {
    final auth = Get.find<AuthController>();
    final userId = auth.userId.value;
    final roleName = auth.roleName.value;
    
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    print('🧪 semesterId sent to API = $semesterId, userId = $userId, role = $roleName, offset = $offset, limit = $limit');

    // Determine endpoint based on role
    final isTeacher = roleName == 'teacher' || roleName == 'instructor';
    final endpoint = isTeacher 
        ? '/social-feed/feed/teacher'
        : '/social-feed/feed/student';

    // API returns List directly
    final response = await _apiClient.get<List<dynamic>>(
      endpoint,
      queryParameters: {
        'user_id': userId,
        'semester_id': semesterId,
        'offset': offset,
        'limit': limit,
      },
    );

    final data = response.data;
    print('🏫 [ClassFeedRepo] Got response: ${data?.length} items');
    
    if (data == null) {
      throw Exception('Failed to fetch class feed');
    }

    return data
        .map((json) => ClassFeedModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// GET CLASS DETAIL (posts in section)
  Future<ClassFeedModel?> getClassDetail({required int sectionId}) async {
    try {
      final response = await _apiClient.get<List<dynamic>>(
        '/social-feed/post',
        queryParameters: {
          'section_id': sectionId,
        },
      );

      final data = response.data;
      if (data == null || data.isEmpty) {
        return null;
      }

      return ClassFeedModel.fromJson(data.first as Map<String, dynamic>);
    } catch (e) {
      print('Error fetching class detail: $e');
      return null;
    }
  }

  /// GET POSTS IN CLASS with optional filter
  Future<Map<String, dynamic>> getClassDetailFeed({
    required int sectionId,
    String? postType,
    bool? teacherOnly,
  }) async {
    final response = await _apiClient.get<List<dynamic>>(
      '/social-feed/post',
      queryParameters: {
        'section_id': sectionId,
        if (postType != null) 'type': postType,
      },
    );

    return {
      'success': true,
      'data': response.data ?? [],
    };
  }

  /// GET SECTION EDUCATORS
  /// Returns list of educators for a section
  Future<List<Map<String, dynamic>>?> getSectionEducators({
    required int sectionId,
  }) async {
    try {
      final response = await _apiClient.get<List<dynamic>>(
        '/social-feed/section-educators/$sectionId',
      );

      if (response.data != null) {
        return response.data!
            .map((e) => e as Map<String, dynamic>)
            .toList();
      }
      return null;
    } catch (e) {
      debugPrint('❌ Error fetching section educators: $e');
      return null;
    }
  }

  
  /// GET CLASS INFO (schedules, members, educators)
  Future<Map<String, dynamic>?> getClassInfo({
    required int sectionId,
  }) async {
    try {
      final response = await _apiClient.get<Map<String, dynamic>>(
        '/social-feed/class-info/$sectionId',
      );
      return response.data;
    } catch (e) {
      debugPrint('❌ Error fetching class info: $e');
      return null;
    }
  }
}