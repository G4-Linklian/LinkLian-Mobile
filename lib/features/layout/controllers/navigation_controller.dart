import 'package:LinkLian/features/community/controllers/community_controller.dart';
import 'package:get/get.dart';

/// Global navigation controller for managing bottom navigation state
/// This allows sub-pages to change the main tab without destroying themselves
class NavigationController extends GetxController {
  final RxInt selectedIndex = 1.obs; // Default to ClassesPage

  /// Track if currently showing class detail overlay
  final RxBool isShowingClassDetail = false.obs;

  /// Track the class detail arguments for restoration
  final Rx<Map<String, dynamic>?> classDetailArgs = Rx<Map<String, dynamic>?>(
    null,
  );
  final isShowingCommunityDetail = false.obs;
  final communityDetailArgs = Rxn<Map<String, dynamic>>();

  /// Change to a specific tab
  void changeTab(int index) {
    final previousIndex = selectedIndex.value;
    selectedIndex.value = index;

    if (previousIndex == 2 && index != 2) {
      if (Get.isRegistered<CommunityController>()) {
        Get.find<CommunityController>().resetSearch();
      }
    }
    if (index != 1) {
      isShowingClassDetail.value = false;
      classDetailArgs.value = null;
    }

    if (index != 2) {
      isShowingCommunityDetail.value = false;
      communityDetailArgs.value = null;
    }

  }

  /// Show class detail overlay
  void showClassDetail(Map<String, dynamic> args) {
    classDetailArgs.value = args;
    isShowingClassDetail.value = true;
  }

  /// Hide class detail overlay
  void hideClassDetail() {
    isShowingClassDetail.value = false;
    classDetailArgs.value = null;
  }

  void showCommunityDetail(Map<String, dynamic> args) {
    communityDetailArgs.value = args;
    isShowingCommunityDetail.value = true;
  }

  void hideCommunityDetail() {
    isShowingCommunityDetail.value = false;
  }

  /// Check if should show class detail when switching to class tab
  bool get shouldRestoreClassDetail =>
      isShowingClassDetail.value && classDetailArgs.value != null;
}
