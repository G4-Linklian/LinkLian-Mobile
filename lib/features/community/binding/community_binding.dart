import 'package:get/get.dart';
import '../controllers/community_controller.dart';
import '../../../data/repository/community_repository.dart';

class CommunityBinding extends Bindings {
  @override
  void dependencies() {
    // ไม่จำเป็นต้องสร้างใหม่ เพราะสร้างไว้ใน main.dart แล้ว
    // แต่ถ้ายังไม่มี ให้สร้าง
    if (!Get.isRegistered<CommunityController>()) {
      Get.lazyPut<CommunityController>(
        () => CommunityController(Get.find<CommunityRepository>()),
      );
    }
  }
}