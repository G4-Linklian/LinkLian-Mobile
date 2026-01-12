import '../model/semester_model.dart';
import '../../core/services/api_client.dart';

class SemesterRepository {
  final ApiClient _apiClient = ApiClient();

  /// ============================
  /// GET SEMESTER LIST
  /// ============================
  Future<List<SemesterModel>> getSemesters({
    required int instId,
  }) async {
    final response = await _apiClient.post<Map<String, dynamic>>(
      '/semester.get',
      data: {
        'inst_id': instId,
        'flag_valid': true,
      },
    );

    final data = response.data;
    if (data == null || data['success'] != true) {
      throw Exception(data?['message'] ?? 'Failed to fetch semester');
    }

    final List list = data['data'] as List;

    return list
        .map(
          (e) => SemesterModel.fromJson(
            e as Map<String, dynamic>,
          ),
        )
        .toList();
  }
}