import 'package:LinkLian/features/profile/data/models/teacher_dashboard_model.dart';
import 'package:dartz/dartz.dart';
// import '../model/teacher_dashboard_model.dart';
import '../datasources/teacher_dashboard_remote_datasource.dart';

class TeacherDashboardRepository {
  final TeacherDashboardRemoteDataSource remoteDataSource;

  TeacherDashboardRepository({required this.remoteDataSource});

  Future<Either<String, TeacherDashboardResponse>> getTeacherDashboard({
    required String userId,
  }) async {
    try {
      final result = await remoteDataSource.getTeacherDashboard(userId: userId);
      return Right(result);
    } catch (e) {
      return Left(e.toString());
    }
  }

  Future<Either<String, List<String>>> getAvailableReportMonths({
    required String userId,
  }) async {
    try {
      final result = await remoteDataSource.getAvailableReportMonths(
        userId: userId,
      );
      return Right(result);
    } catch (e) {
      return Left(e.toString());
    }
  }
}
