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
    print('📅 [SemesterRepo] Fetching semesters for instId: $instId');
    
    // API returns List directly, not { success, data }
    final response = await _apiClient.get<List<dynamic>>(
      '/semester',
      queryParameters: {
        'inst_id': instId,
        'flag_valid': true,
      },
    );

    final data = response.data;
    print('📅 [SemesterRepo] Response length: ${data?.length}');
    
    if (data == null) {
      print('❌ [SemesterRepo] Response data is null');
      throw Exception('Failed to fetch semester');
    }

    print('📅 [SemesterRepo] Got ${data.length} semesters');

    return data
        .map(
          (e) => SemesterModel.fromJson(
            e as Map<String, dynamic>,
          ),
        )
        .toList();
  }
}