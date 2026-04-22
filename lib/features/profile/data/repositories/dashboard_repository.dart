import 'package:dartz/dartz.dart';
import '../../../../core/error/failure.dart';
import '../datasources/dashboard_remote_datasource.dart';
import '../models/dashboard_model.dart';

abstract class DashboardRepository {
  Future<Either<Failure, DashboardResponse>> getStudentDashboard({
    required int userId,
    required String reportMonth,
    required String roleType,
  });

  Future<Either<Failure, List<String>>> getAvailableReportMonths({
    required int userId,
  });
}

class DashboardRepositoryImpl implements DashboardRepository {
  final DashboardRemoteDataSource remoteDataSource;

  DashboardRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, DashboardResponse>> getStudentDashboard({
    required int userId,
    required String reportMonth,
    required String roleType,
  }) async {
    try {
      final result = await remoteDataSource.getStudentDashboard(
        userId: userId,
        reportMonth: reportMonth,
        roleType: roleType,
      );
      return Right(result);
    } catch (e) {
      return Left(ServerFailure(message: 'Failed to fetch dashboard: $e'));
    }
  }

  @override
  Future<Either<Failure, List<String>>> getAvailableReportMonths({
    required int userId,
  }) async {
    try {
      final result = await remoteDataSource.getAvailableReportMonths(
        userId: userId,
      );
      return Right(result);
    } catch (e) {
      return Left(ServerFailure(message: 'Failed to fetch report months: $e'));
    }
  }
}
