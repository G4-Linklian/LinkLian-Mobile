import 'package:LinkLian/features/community/controllers/community_controller.dart';
import 'package:LinkLian/features/assignment/presentation/controllers/class_assignment_controller.dart';
import 'package:get/get.dart';

class NavigationController extends GetxController {
  final RxInt selectedIndex = 1.obs; // Default to ClassesPage

  // ─── Class Detail ─────────────────────────────────────────────────────────
  final RxBool isShowingClassDetail = false.obs;
  final Rx<Map<String, dynamic>?> classDetailArgs = Rx<Map<String, dynamic>?>(
    null,
  );

  // ─── Community Detail ─────────────────────────────────────────────────────
  final RxBool isShowingCommunityDetail = false.obs;
  final Rxn<Map<String, dynamic>> communityDetailArgs =
      Rxn<Map<String, dynamic>>();

  // ─── Assignment sub-page (ClassAssignmentPage) ────────────────────────────
  final RxBool isShowingClassAssignment = false.obs;
  final Rxn<Map<String, dynamic>> classAssignmentArgs =
      Rxn<Map<String, dynamic>>();

  // Tab switching


  void changeTab(int index) {
    final previousIndex = selectedIndex.value;
    selectedIndex.value = index;

    if (previousIndex == 2 && index != 2) {
      if (Get.isRegistered<CommunityController>()) {
        Get.find<CommunityController>().resetSearch();
      }
    }
  }

  // Class Detail (Tab 1)

  void showClassDetail(Map<String, dynamic> args) {
    classDetailArgs.value = args;
    isShowingClassDetail.value = true;
  }

  void hideClassDetail() {
    isShowingClassDetail.value = false;
    classDetailArgs.value = null;
  }
  

  void showClassDetailFromRedirect(Map<String, dynamic> args) {
    classDetailArgs.value = args;
    isShowingClassDetail.value = true;
    selectedIndex.value = 1;
  }

  bool get shouldRestoreClassDetail =>
      isShowingClassDetail.value && classDetailArgs.value != null;

  // Community Detail (Tab 2)

  void showCommunityDetail(Map<String, dynamic> args) {
    communityDetailArgs.value = args;
    isShowingCommunityDetail.value = true;
  }

  void hideCommunityDetail() {
    isShowingCommunityDetail.value = false;
    communityDetailArgs.value = null;
  }

  // Class Assignment (Tab 0 sub-page)

  void showClassAssignment(Map<String, dynamic> args) {
    classAssignmentArgs.value = args;
    isShowingClassAssignment.value = true;
  }

  void hideClassAssignment() {
    isShowingClassAssignment.value = false;
    classAssignmentArgs.value = null;
  }

  void resetForRoleChange(bool isStudent) {
    final maxIndex = isStudent ? 3 : 2;

    if (selectedIndex.value > maxIndex) {
      selectedIndex.value = 1;
    }
    isShowingClassDetail.value = false;
    classDetailArgs.value = null;

    isShowingCommunityDetail.value = false;
    communityDetailArgs.value = null;

    isShowingClassAssignment.value = false;
    classAssignmentArgs.value = null;

    // Delete ClassAssignmentController to clear stale state on role change
    if (Get.isRegistered<ClassAssignmentController>()) {
      Get.delete<ClassAssignmentController>(force: true);
    }
  }
}
