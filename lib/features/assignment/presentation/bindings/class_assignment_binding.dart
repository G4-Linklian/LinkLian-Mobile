import 'package:get/get.dart';
import 'package:LinkLian/core/services/api_client.dart';
import '../controllers/class_assignment_controller.dart';
import '../../data/repositories/assignment_repository.dart';
import '../../../shared/repositories/class_feed_repository.dart';

class ClassAssignmentBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<AssignmentRepository>()) {
      Get.put<AssignmentRepository>(
        AssignmentRepository(apiClient: Get.find<ApiClient>()),
        permanent: true,
      );
    }
    if (!Get.isRegistered<ClassFeedRepository>()) {
      Get.lazyPut<AssignmentRepository>(
  () => AssignmentRepository(apiClient: Get.find<ApiClient>()),
  fenix: true,
);
    }

    if (Get.isRegistered<ClassAssignmentController>()) {
      Get.delete<ClassAssignmentController>(force: true);
    }

    Get.put<ClassAssignmentController>(
      ClassAssignmentController(
        Get.find<AssignmentRepository>(),
        Get.find<ClassFeedRepository>(),
      ),
      permanent: false,
    );
  }
}
