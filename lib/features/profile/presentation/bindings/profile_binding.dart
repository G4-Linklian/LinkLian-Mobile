import 'package:LinkLian/features/shared/repositories/bookmark_repository.dart';
import 'package:LinkLian/features/profile/data/repositories/teaching_schedule_repository.dart';
import 'package:LinkLian/features/shared/presentations/bookmark_controller.dart';
import 'package:get/get.dart';
import '../../../../core/services/api_client.dart';
import '../../../shared/repositories/profile_repository.dart';
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
