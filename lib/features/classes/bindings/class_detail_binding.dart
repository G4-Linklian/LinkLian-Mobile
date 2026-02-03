// class_detail_binding.dart
import 'package:get/get.dart';
import '../controllers/class_detail_controller.dart';

class ClassDetailBinding extends Bindings {
  @override
  void dependencies() {
    // Put controller as permanent since it's managed by MainPage now
    if (!Get.isRegistered<ClassDetailController>()) {
      Get.put<ClassDetailController>(
        ClassDetailController(),
        permanent: true,
      );
    }
  }
}