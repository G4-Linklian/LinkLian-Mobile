import '../../core/services/api_client.dart';
import '../model/teaching_schedule_model.dart';

class TeachingScheduleRepository {
  final ApiClient api;
  TeachingScheduleRepository(this.api);

  Future<List<TeachingScheduleModel>> getByEducator(int userSysId) async {
    final res = await api.post(
      '/section.educator.get',
      data: {
        'user_sys_id': userSysId,
        'from_profile': true,
        'join_building': true,
      },
    );

    final List list = res.data['data'];
    return list
        .map((e) => TeachingScheduleModel.fromJson(e))
        .toList();
  }
}
