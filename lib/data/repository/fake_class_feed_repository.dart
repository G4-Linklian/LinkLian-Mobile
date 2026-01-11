import '../../data/model/class_feed_model.dart';
import '../../data/model/class_schedule_model.dart';
import '../../data/repository/class_feed_repository.dart';


class FakeClassFeedRepository implements ClassFeedRepository {
   @override
  String get baseUrl => '';

  @override
  Future<String?> Function() get getToken =>
      () async => null;
  @override
  Future<List<ClassFeedModel>> getClassFeed({required int semesterId}) async {
    await Future.delayed(const Duration(milliseconds: 300));

    return [
      ClassFeedModel(
        sectionId: 1,
        sectionName: 'SEC 1',
        subjectCode: 'ค10101',
        subjectNameTh: 'คณิตศาสตร์พื้นฐาน',
        subjectNameEn: 'Basic Math',
        learningAreaName: 'คณิตศาสตร์',
        semester: '2/2568',
        schedules: [
          ClassScheduleModel(
            dayOfWeek: 3,
            startTime: '10:20',
            endTime: '11:10',
          ),
        ],
      ),
    ];
  }
}