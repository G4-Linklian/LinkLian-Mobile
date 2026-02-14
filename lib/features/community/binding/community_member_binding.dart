import 'package:get/get.dart';
import '../../../data/repository/community_member_repository.dart';
import '../controllers/community_member_controller.dart';

class CommunityMemberBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(
      () => CommunityMemberController(
        CommunityMemberRepository(),
      ),
    );
  }
}
