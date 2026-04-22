import 'package:get/get.dart';
import 'package:LinkLian/core/services/api_client.dart';
import '../../data/datasources/teacher_dashboard_remote_datasource.dart';
import '../../data/repositories/teacher_dashboard_repository.dart';
import '../../domain/usecases/teacher_dashboard_usecases.dart';
import '../controllers/teacher_dashboard_controller.dart';

class TeacherDashboardBinding extends Bindings {
  @override
  void dependencies() {
    // Register data sources
    Get.put<TeacherDashboardRemoteDataSource>(
      TeacherDashboardRemoteDataSource(apiClient: Get.find<ApiClient>()),
    );

    // Register repositories
    Get.put<TeacherDashboardRepository>(
      TeacherDashboardRepository(
        remoteDataSource: Get.find<TeacherDashboardRemoteDataSource>(),
      ),
    );

    // Register use cases
    Get.put<GetTeacherDashboardUseCase>(
      GetTeacherDashboardUseCase(
        repository: Get.find<TeacherDashboardRepository>(),
      ),
    );

    Get.put<GetTeacherAvailableReportMonthsUseCase>(
      GetTeacherAvailableReportMonthsUseCase(
        repository: Get.find<TeacherDashboardRepository>(),
      ),
    );

    // Register controller
    Get.put<TeacherDashboardController>(
      TeacherDashboardController(
        getTeacherDashboardUseCase: Get.find<GetTeacherDashboardUseCase>(),
        getAvailableReportMonthsUseCase:
            Get.find<GetTeacherAvailableReportMonthsUseCase>(),
      ),
    );
  }
}
