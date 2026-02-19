// import 'package:LinkLian/features/community/controllers/community_controller.dart';
// import 'package:get/get.dart';

// /// Global navigation controller for managing bottom navigation state
// /// This allows sub-pages to change the main tab without destroying themselves
// class NavigationController extends GetxController {
//   final RxInt selectedIndex = 1.obs; // Default to ClassesPage

//   /// Track if currently showing class detail overlay
//   final RxBool isShowingClassDetail = false.obs;

//   /// Track the class detail arguments for restoration
//   final Rx<Map<String, dynamic>?> classDetailArgs = Rx<Map<String, dynamic>?>(
//     null,
//   );
//   final isShowingCommunityDetail = false.obs;
//   final communityDetailArgs = Rxn<Map<String, dynamic>>();

//   /// Change to a specific tab
//   void changeTab(int index) {
//     final previousIndex = selectedIndex.value;
//     selectedIndex.value = index;

//     if (previousIndex == 2 && index != 2) {
//       if (Get.isRegistered<CommunityController>()) {
//         Get.find<CommunityController>().resetSearch();
//       }
//     }
//     if (index != 1) {
//       isShowingClassDetail.value = false;
//       classDetailArgs.value = null;
//     }

//     if (index != 2) {
//       isShowingCommunityDetail.value = false;
//       communityDetailArgs.value = null;
//     }

//   }

//   /// Show class detail overlay
//   void showClassDetail(Map<String, dynamic> args) {
//     classDetailArgs.value = args;
//     isShowingClassDetail.value = true;
//   }

//   /// Hide class detail overlay
//   void hideClassDetail() {
//     isShowingClassDetail.value = false;
//     classDetailArgs.value = null;
//   }

//   void showCommunityDetail(Map<String, dynamic> args) {
//     communityDetailArgs.value = args;
//     isShowingCommunityDetail.value = true;
//   }

//   void hideCommunityDetail() {
//     isShowingCommunityDetail.value = false;
//   }

//   void showClassDetailFromRedirect(Map<String, dynamic> args) {
//   // Set ค่าทั้งหมดก่อน แล้วค่อย switch tab
//   // เพื่อให้ AnimatedSwitcher เห็น isShowingClassDetail=true ทันทีที่ tab เปลี่ยน
//   classDetailArgs.value = args;
//   isShowingClassDetail.value = true;
//   selectedIndex.value = 1;
// }

//   /// Check if should show class detail when switching to class tab
//   bool get shouldRestoreClassDetail =>
//       isShowingClassDetail.value && classDetailArgs.value != null;
// }

import 'package:LinkLian/features/community/controllers/community_controller.dart';
import 'package:get/get.dart';

/// Global navigation controller for managing bottom navigation state
/// This allows sub-pages to change the main tab without destroying themselves
class NavigationController extends GetxController {
  final RxInt selectedIndex = 1.obs; // Default to ClassesPage

  // ─── Class Detail ─────────────────────────────────────────────────────────
  final RxBool isShowingClassDetail = false.obs;
  final Rx<Map<String, dynamic>?> classDetailArgs =
      Rx<Map<String, dynamic>?>(null);

  // ─── Community Detail ─────────────────────────────────────────────────────
  final RxBool isShowingCommunityDetail = false.obs;
  final Rxn<Map<String, dynamic>> communityDetailArgs =
      Rxn<Map<String, dynamic>>();

  // ─── Assignment sub-page (ClassAssignmentPage) ────────────────────────────
  /// Whether tab-0 is currently showing a ClassAssignmentPage
  final RxBool isShowingClassAssignment = false.obs;
  final Rxn<Map<String, dynamic>> classAssignmentArgs =
      Rxn<Map<String, dynamic>>();

  // ─────────────────────────────────────────────────────────────────────────
  // Tab switching
  // ─────────────────────────────────────────────────────────────────────────

  /// Change to a specific tab.
  /// Sub-page state for each tab is PRESERVED so that returning to a tab
  /// restores the exact sub-page the user was on before.
  void changeTab(int index) {
    final previousIndex = selectedIndex.value;
    selectedIndex.value = index;

    // Reset community search text when leaving community tab
    if (previousIndex == 2 && index != 2) {
      if (Get.isRegistered<CommunityController>()) {
        Get.find<CommunityController>().resetSearch();
      }
    }
    // NOTE: We intentionally do NOT clear sub-page states here.
    // Each sub-page is restored when the user returns to its parent tab.
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Class Detail (Tab 1)
  // ─────────────────────────────────────────────────────────────────────────

  void showClassDetail(Map<String, dynamic> args) {
    classDetailArgs.value = args;
    isShowingClassDetail.value = true;
  }

  void hideClassDetail() {
    isShowingClassDetail.value = false;
    classDetailArgs.value = null;
  }

  /// Navigate to class detail from another tab (instant transition on the
  /// destination tab, slide only within tab 1).
  void showClassDetailFromRedirect(Map<String, dynamic> args) {
    classDetailArgs.value = args;
    isShowingClassDetail.value = true;
    selectedIndex.value = 1;
  }

  bool get shouldRestoreClassDetail =>
      isShowingClassDetail.value && classDetailArgs.value != null;

  // ─────────────────────────────────────────────────────────────────────────
  // Community Detail (Tab 2)
  // ─────────────────────────────────────────────────────────────────────────

  void showCommunityDetail(Map<String, dynamic> args) {
    communityDetailArgs.value = args;
    isShowingCommunityDetail.value = true;
  }

  void hideCommunityDetail() {
    isShowingCommunityDetail.value = false;
    communityDetailArgs.value = null;
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Class Assignment (Tab 0 sub-page)
  // ─────────────────────────────────────────────────────────────────────────

  void showClassAssignment(Map<String, dynamic> args) {
    classAssignmentArgs.value = args;
    isShowingClassAssignment.value = true;
  }

  void hideClassAssignment() {
    isShowingClassAssignment.value = false;
    classAssignmentArgs.value = null;
  }
}
