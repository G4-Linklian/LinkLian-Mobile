import 'package:LinkLian/data/repository/bookmark_repository.dart';
import 'package:LinkLian/data/repository/teaching_schedule_repository.dart';
import 'package:LinkLian/features/profile/controllers/bookmark_controller.dart';
import 'package:get/get.dart';
import '../../../core/services/api_client.dart';
import '../../../data/repository/profile_repository.dart';
import '../controllers/profile_controller.dart';

class ProfileBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ApiClient>(() => ApiClient(), fenix: true);

    Get.lazyPut<ProfileRepository>(
      () => ProfileRepository(Get.find<ApiClient>()),
      fenix: true,
    );

    Get.lazyPut(
      () => ProfileController(
        Get.find<ProfileRepository>(),
        Get.find<TeachingScheduleRepository>(),
      ),
    );
  }
}
