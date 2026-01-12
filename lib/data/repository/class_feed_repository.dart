import '../model/class_feed_model.dart';
import '../../core/services/api_client.dart';

class ClassFeedRepository {
  final ApiClient _apiClient = ApiClient();

  /// ============================
  /// GET CLASS FEED BY SEMESTER
  /// ============================
  Future<List<ClassFeedModel>> getClassFeed({
    required int semesterId,
  }) async {
      print('🧪 semesterId sent to API = $semesterId');

    final response = await _apiClient.post<Map<String, dynamic>>(
      '/class',
      data: {
        'semester_id': semesterId,
      },
    );

    final data = response.data;
    if (data == null || data['success'] != true) {
      throw Exception(data?['message'] ?? 'Failed to fetch class feed');
    }

    final List list = data['data'] as List;

    return list
        .map(
          (json) => ClassFeedModel.fromJson(
            json as Map<String, dynamic>,
          ),
        )
        .toList();
  }
}