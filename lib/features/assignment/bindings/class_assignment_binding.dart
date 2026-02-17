import 'package:get/get.dart';
import '../controllers/class_assignment_controller.dart';

class ClassAssignmentBinding extends Bindings {
  @override
  void dependencies() {
    // ลบ controller เก่าถ้ามี (ป้องกัน duplicate)
    if (Get.isRegistered<ClassAssignmentController>()) {
      Get.delete<ClassAssignmentController>();
    }

    // สร้าง controller ใหม่
    Get.put<ClassAssignmentController>(
      ClassAssignmentController(),
      permanent: false,
    );
  }
}