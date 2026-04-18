import 'package:LinkLian/features/profile/data/models/teacher_dashboard_model.dart';
import 'package:dartz/dartz.dart';
// import '../../data/models/teacher_dashboard_model.dart';
import '../../data/repositories/teacher_dashboard_repository.dart';

class GetTeacherDashboardUseCase {
  final TeacherDashboardRepository repository;

  GetTeacherDashboardUseCase({required this.repository});

  Future<Either<String, TeacherDashboardResponse>> call({
    required String userId,
  }) async {
    return await repository.getTeacherDashboard(userId: userId);
  }
}

class GetTeacherAvailableReportMonthsUseCase {
  final TeacherDashboardRepository repository;

  GetTeacherAvailableReportMonthsUseCase({required this.repository});

  Future<Either<String, List<String>>> call({required String userId}) async {
    return await repository.getAvailableReportMonths(userId: userId);
  }
}
