import 'package:get/get.dart';
import '../../data/repositories/community_member_repository.dart';
import '../controllers/community_pending_controller.dart';

class CommunityPendingBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(
      () => CommunityPendingController(
        CommunityMemberRepository(),
      ),
    );
  }
}
