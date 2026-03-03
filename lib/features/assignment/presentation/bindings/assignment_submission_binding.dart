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
      Get.put<SubmissionRepository>(
        SubmissionRepository(apiClient: Get.find<ApiClient>()),
        permanent: true,
      );
    }

    if (Get.isRegistered<AssignmentSubmissionController>()) {
      Get.delete<AssignmentSubmissionController>();
    }
    Get.put<AssignmentSubmissionController>(
      AssignmentSubmissionController(),
    );
  }
}
