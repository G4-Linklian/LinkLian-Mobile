// lib/features/classes/bindings/class_feed_binding.dart
import 'package:get/get.dart';
import '../../auth/controller/auth_controller.dart';
import '../controllers/class_feed_controller.dart';
import '../../../data/repository/class_feed_repository.dart';
import '../../../data/repository/semester_repository.dart';

class ClassFeedBinding extends Bindings {
  @override
  void dependencies() {
    // ⚠️ ไม่อ่านค่า session ที่นี่
    Get.lazyPut<ClassFeedController>(
      () => ClassFeedController(
        classFeedRepository: Get.find<ClassFeedRepository>(),
        semesterRepository: Get.find<SemesterRepository>(),
      ),
      fenix: true,
    );
  }
}