import 'package:flutter/foundation.dart';
import '../../core/services/api_client.dart';
import '../model/teaching_schedule_model.dart';

class TeachingScheduleRepository {
  final ApiClient apiClient;

  TeachingScheduleRepository(this.apiClient);

  /// Get teaching schedules for educator
  Future<List<TeachingScheduleModel>> getByEducator(int educatorId) async {
    try {
      debugPrint('📥 Fetching teaching schedule for educator: $educatorId');

      final response = await apiClient.get<dynamic>(
        '/profile/$educatorId/teaching-schedule',
      );

      debugPrint('📥 Response: ${response.data}');

      // Handle response format
      final data = response.data;
      if (data == null) {
        debugPrint('⚠️ Response data is null');
        return [];
      }

      // Check if response has 'data' field (from NestJS)
      List<dynamic>? scheduleList;

      if (data is Map && data.containsKey('data')) {
        scheduleList = data['data'] as List<dynamic>?;
      } else if (data is List) {
        scheduleList = data;
      }

      if (scheduleList == null || scheduleList.isEmpty) {
        debugPrint('⚠️ No schedule data found');
        return [];
      }

      debugPrint('✅ Found ${scheduleList.length} schedules');

      final schedules = scheduleList
          .map((e) => TeachingScheduleModel.fromJson(e as Map<String, dynamic>))
          .toList();

      return schedules;
    } catch (e) {
      debugPrint('❌ Error fetching teaching schedule: $e');
      return [];
    }
  }
}
