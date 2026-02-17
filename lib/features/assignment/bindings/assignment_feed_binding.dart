import 'package:get/get.dart';
import '../controllers/assignment_feed_controller.dart';

class AssignmentFeedBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<AssignmentFeedController>(() => AssignmentFeedController());
  }
}
