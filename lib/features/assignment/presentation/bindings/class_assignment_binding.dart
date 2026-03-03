import 'package:get/get.dart';
import '../controllers/class_assignment_controller.dart';
import '../../data/repositories/assignment_repository.dart';
import '../../../shared/repositories/class_feed_repository.dart';

class ClassAssignmentBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<AssignmentRepository>()) {
      Get.put<AssignmentRepository>(AssignmentRepository(), permanent: true);
    }
    if (!Get.isRegistered<ClassFeedRepository>()) {
      Get.put<ClassFeedRepository>(ClassFeedRepository(), permanent: true);
    }

    if (Get.isRegistered<ClassAssignmentController>()) {
      Get.delete<ClassAssignmentController>();
    }

    Get.put<ClassAssignmentController>(
      ClassAssignmentController(),
      permanent: false,
    );
  }
}
