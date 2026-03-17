import '../model/semester_model.dart';
import '../../core/services/api_client.dart';
import 'package:flutter/foundation.dart';

class SemesterRepository {
  final ApiClient _apiClient = ApiClient();

  /// ============================
  /// GET SEMESTER LIST
  /// ============================
  Future<List<SemesterModel>> getSemesters({
    required int instId,
  }) async {
    debugPrint('📅 [SemesterRepo] Fetching semesters for instId: $instId');
    
    // API returns List directly, not { success, data }
    final response = await _apiClient.get<Map<String, dynamic>>(
      '/semester',
      queryParameters: {
        'inst_id': instId,
        'flag_valid': true,
      },
    );
    debugPrint('📅 [SemesterRepo] API Response: $response');
  final responseData = response.data;
  if (responseData == null) {
    debugPrint('❌ [SemesterRepo] Response data is null');
    throw Exception('Failed to fetch semester');
  }
  final data = responseData['data'] as List<dynamic>?;
  if (data == null) {
    debugPrint('❌ [SemesterRepo] Response data is null');
    throw Exception('Failed to fetch semester');
  }

    debugPrint('📅 [SemesterRepo] Got ${data.length} semesters');

    return data
        .map(
          (e) => SemesterModel.fromJson(
            e as Map<String, dynamic>,
          ),
        )
        .toList();
  }
}
