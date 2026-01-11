import '../../data/model/semester_model.dart';
import '../../data/repository/semester_repository.dart';

class FakeSemesterRepository implements SemesterRepository {
   @override
  String get baseUrl => '';

  @override
  Future<String?> Function() get getToken =>
      () async => null;

  @override
  Future<List<SemesterModel>> getSemesters({required int instId}) async {
    return [
      SemesterModel(
        semesterId: 6,
        semester: '2/2568',
        status: 'open',
        flagValid: true,
        startDate: DateTime(2026, 1, 12),
        endDate: DateTime(2026, 6, 4),
      ),
      SemesterModel(
        semesterId: 5,
        semester: '1/2568',
        status: 'close',
        flagValid: true,
        startDate: DateTime(2025, 12, 2),
        endDate: DateTime(2025, 12, 15),
      ),
    ];
  }
}