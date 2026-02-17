import 'package:LinkLian/data/repository/community_member_repository.dart';
import 'package:get/get.dart';
import '../../../data/repository/community_repository.dart';
import '../../../data/repository/community_post_repository.dart';
import '../controllers/community_detail_controller.dart';

class CommunityDetailBinding extends Bindings {
  @override
  void dependencies() {

    Get.lazyPut<CommunityRepository>(() => CommunityRepository());
    Get.lazyPut<CommunityPostRepository>(() => CommunityPostRepository());
    Get.lazyPut<CommunityMemberRepository>(() => CommunityMemberRepository());

    Get.lazyPut<CommunityDetailController>(
      () => CommunityDetailController(
        Get.find<CommunityRepository>(),
        Get.find<CommunityPostRepository>(),
         Get.find<CommunityMemberRepository>(),
      ),
    );
  }
}
