// lib/features/classes/bindings/class_feed_binding.dart
import 'package:get/get.dart';
import '../controllers/class_feed_controller.dart';
import '../../shared/repositories/class_feed_repository.dart';
import '../../../data/repository/semester_repository.dart';

class ClassFeedBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ClassFeedController>(
      () => ClassFeedController(
        classFeedRepository: Get.find<ClassFeedRepository>(),
        semesterRepository: Get.find<SemesterRepository>(),
      ),
      fenix: true,
    );
  }
}