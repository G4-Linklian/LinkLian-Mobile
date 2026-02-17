import 'package:LinkLian/core/services/api_client.dart';
import 'package:LinkLian/data/repository/profile_repository.dart';
import 'package:LinkLian/features/community/controllers/create_post_community_controller.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_instance/src/bindings_interface.dart';
import 'package:get/get_instance/src/extension_instance.dart';

import '../../../data/repository/community_post_repository.dart';

class CreatePostCommunityBinding extends Bindings {
  @override
  void dependencies() {

    Get.lazyPut<ApiClient>(() => ApiClient());

    Get.lazyPut<ProfileRepository>(
      () => ProfileRepository(Get.find<ApiClient>()),
    );

    Get.lazyPut<CommunityPostRepository>(
      () => CommunityPostRepository(),
    );

    Get.lazyPut<CreatePostCommunityController>(
      () => CreatePostCommunityController(
        Get.find<CommunityPostRepository>(),
        Get.find<ProfileRepository>(),
      ),
    );
  }
}

