import '../model/class_feed_model.dart';
import '../../core/services/api_client.dart';

class ClassFeedRepository {
  final ApiClient _apiClient = ApiClient();

  /// GET CLASS FEED BY SEMESTER
  Future<List<ClassFeedModel>> getClassFeed({required int semesterId}) async {
    print('🧪 semesterId sent to API = $semesterId');

    final response = await _apiClient.post<Map<String, dynamic>>(
      '/class',
      data: {'semester_id': semesterId},
    );

    final data = response.data;
    if (data == null || data['success'] != true) {
      throw Exception(data?['message'] ?? 'Failed to fetch class feed');
    }

    final List list = data['data'] as List;

    return list
        .map((json) => ClassFeedModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// GET CLASS DETAIL
  Future<ClassFeedModel?> getClassDetail({required int sectionId}) async {
    try {
      final response = await _apiClient.get<Map<String, dynamic>>(
        '/class',
        queryParameters: {
          'section_id': sectionId,
        },
      );

      final data = response.data;
      if (data == null || data['success'] != true) {
        return null;
      }

      final result = data['data'];
      
      if (result is List && result.isNotEmpty) {
        return ClassFeedModel.fromJson(
          result.first as Map<String, dynamic>
        );
      } else if (result is Map) {
        return ClassFeedModel.fromJson(result as Map<String, dynamic>);
      }
      
      return null;
    } catch (e) {
      print('Error fetching class detail: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>> getClassDetailFeed({
    required int sectionId,
    String? postType,
    bool? teacherOnly,
  }) async {
    final response = await _apiClient.get<Map<String, dynamic>>(
      '/class',
      queryParameters: {
        'section_id': sectionId,
        if (postType != null) 'type': postType,
        if (teacherOnly != null) 'teacher_only': teacherOnly,
      },
    );

    return response.data!;
  }
}