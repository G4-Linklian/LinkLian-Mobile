// class_detail_binding.dart
import 'package:get/get.dart';
import '../controllers/class_detail_controller.dart';

class ClassDetailBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ClassDetailController>(
      () => ClassDetailController(),
    );
  }
}