import 'package:get/get.dart';
import '../controllers/assignment_submission_controller.dart';

class AssignmentSubmissionBinding extends Bindings {
  @override
  void dependencies() {
    if (Get.isRegistered<AssignmentSubmissionController>()) {
      Get.delete<AssignmentSubmissionController>();
    }

    Get.put<AssignmentSubmissionController>(
      AssignmentSubmissionController(),
    );
  }
}