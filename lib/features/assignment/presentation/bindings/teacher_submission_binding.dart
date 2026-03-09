import 'package:get/get.dart';
import 'package:LinkLian/core/services/api_client.dart';
import '../controllers/teacher_submission_controller.dart';
import '../../data/repositories/assignment_repository.dart';
import '../../data/repositories/submission_repository.dart';

class TeacherSubmissionBinding extends Bindings {
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
      );
    }
    // TeacherSubmissionController is managed by TeacherSubmissionListTab
    // It may already be registered; only register if missing
    if (!Get.isRegistered<TeacherSubmissionController>()) {
      Get.put<TeacherSubmissionController>(
        TeacherSubmissionController(
          repo: Get.find<AssignmentRepository>(),
          submissionRepo: Get.find<SubmissionRepository>(),
        ),
      );
    }
  }
}
