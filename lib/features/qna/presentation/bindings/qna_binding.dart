import 'package:get/get.dart';
import '../controllers/live_controller.dart';

class QnaBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<LiveController>(() => LiveController());
  }
}
