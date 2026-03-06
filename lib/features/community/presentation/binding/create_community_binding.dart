import 'package:get/get.dart';
import '../controllers/create_community_controller.dart';
import '../../data/repositories/community_repository.dart';
import '../../data/repositories/community_tag_repository.dart';

class CreateCommunityBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<CreateCommunityController>(
      () => CreateCommunityController(
        CommunityRepository(),
        CommunityTagRepository(),
      ),
    );
  }
}
