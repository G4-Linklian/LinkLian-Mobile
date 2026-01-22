import 'package:get/get.dart';
import '../../../core/services/api_client.dart';
import '../../../data/repository/bookmark_repository.dart';
import '../controllers/bookmark_controller.dart';

class BookmarkBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<BookmarkRepository>(
      () => BookmarkRepository(Get.find<ApiClient>()),
      fenix: true,
    );

    Get.lazyPut<BookmarkController>(
      () => BookmarkController(Get.find<BookmarkRepository>()),
      fenix: true,
    );
  }
}