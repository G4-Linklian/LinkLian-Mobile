import 'package:get/get.dart';

import '../../shared/repositories/post_repository.dart';
import '../controllers/create_post_controller.dart';

class CreatePostBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<PostRepository>(
      () => PostRepository(),
    );

    Get.lazyPut<CreatePostController>(
      () => CreatePostController(
        postRepository: Get.find<PostRepository>(),
      ),
    );
  }
}