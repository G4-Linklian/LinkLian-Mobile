import 'package:dartz/dartz.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/usecases/usecase.dart';
import '../../data/models/dashboard_model.dart';
import '../../data/repositories/dashboard_repository.dart';

class GetStudentDashboardUseCase
    implements UseCase<DashboardResponse, GetStudentDashboardParams> {
  final DashboardRepository repository;

  GetStudentDashboardUseCase({required this.repository});

  @override
  Future<Either<Failure, DashboardResponse>> call(
    GetStudentDashboardParams params,
  ) async {
    return await repository.getStudentDashboard(
      userId: params.userId,
      reportMonth: params.reportMonth,
      roleType: params.roleType,
    );
  }
}

class GetStudentDashboardParams {
  final int userId;
  final String reportMonth;
  final String roleType; // 'STUDENT' or 'TEACHER'

  GetStudentDashboardParams({
    required this.userId,
    required this.reportMonth,
    this.roleType = 'STUDENT',
  });
}

class GetAvailableReportMonthsUseCase
    implements UseCase<List<String>, GetAvailableReportMonthsParams> {
  final DashboardRepository repository;

  GetAvailableReportMonthsUseCase({required this.repository});

  @override
  Future<Either<Failure, List<String>>> call(
    GetAvailableReportMonthsParams params,
  ) async {
    return await repository.getAvailableReportMonths(userId: params.userId);
  }
}

class GetAvailableReportMonthsParams {
  final int userId;

  GetAvailableReportMonthsParams({required this.userId});
}
