import 'package:get/get.dart';
import 'package:LinkLian/core/services/api_client.dart';
import '../../data/datasources/dashboard_remote_datasource.dart';
import '../../data/repositories/dashboard_repository.dart';
import '../../domain/usecases/dashboard_usecases.dart';
import '../controllers/dashboard_controller.dart';
import '../../../layout/controllers/navigation_controller.dart';

class DashboardBinding extends Bindings {
  @override
  void dependencies() {
    // Register navigation controller if not already registered
    if (!Get.isRegistered<NavigationController>()) {
      Get.put<NavigationController>(NavigationController());
    }

    // Register data sources
    Get.put<DashboardRemoteDataSource>(
      DashboardRemoteDataSource(apiClient: Get.find<ApiClient>()),
    );

    // Register repositories
    Get.put<DashboardRepository>(
      DashboardRepositoryImpl(
            remoteDataSource: Get.find<DashboardRemoteDataSource>(),
          )
          as DashboardRepository,
    );

    Get.put<GetStudentDashboardUseCase>(
      GetStudentDashboardUseCase(repository: Get.find<DashboardRepository>()),
    );

    Get.put<GetAvailableReportMonthsUseCase>(
      GetAvailableReportMonthsUseCase(
        repository: Get.find<DashboardRepository>(),
      ),
    );

    // Register controller
    Get.put<DashboardController>(
      DashboardController(
        repository: Get.find<DashboardRepository>(),
        getStudentDashboardUseCase: Get.find<GetStudentDashboardUseCase>(),
        getAvailableReportMonthsUseCase:
            Get.find<GetAvailableReportMonthsUseCase>(),
      ),
    );
  }
}
