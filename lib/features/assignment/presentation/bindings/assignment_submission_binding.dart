import 'package:get/get.dart';
import 'package:LinkLian/core/services/api_client.dart';
import '../controllers/assignment_submission_controller.dart';
import '../../data/repositories/assignment_repository.dart';
import '../../data/repositories/submission_repository.dart';

class AssignmentSubmissionBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<AssignmentRepository>()) {
      Get.put<AssignmentRepository>(
        AssignmentRepository(apiClient: Get.find<ApiClient>()),
        permanent: true,
      );
    }
    if (!Get.isRegistered<SubmissionRepository>()) {
      Get.lazyPut<SubmissionRepository>(
        () => SubmissionRepository(apiClient: Get.find<ApiClient>()),
        fenix: true,
      );
    }

    if (Get.isRegistered<AssignmentSubmissionController>()) {
      Get.delete<AssignmentSubmissionController>(force: true);
    }
    Get.put<AssignmentSubmissionController>(
      AssignmentSubmissionController(
        repo: Get.find<AssignmentRepository>(),
        submissionRepo: Get.find<SubmissionRepository>(),
        authController: Get.find(),
      ),
    );
  }
}
