import 'package:get/get.dart';
import '../controllers/community_controller.dart';
import '../../../data/repository/community_repository.dart';

class CommunityBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<CommunityController>()) {
      Get.lazyPut<CommunityController>(
        () => CommunityController(Get.find<CommunityRepository>()),
      );
    }
  }
}