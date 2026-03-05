import 'package:LinkLian/features/community/controllers/community_controller.dart';
import 'package:LinkLian/core/services/api_client.dart';
import 'package:LinkLian/features/assignment/data/repositories/assignment_repository.dart';
import 'package:LinkLian/features/assignment/presentation/controllers/class_assignment_controller.dart';
import 'package:LinkLian/features/shared/repositories/class_feed_repository.dart';
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

  // ─── Helper: ensure a dependency is registered ────────────────────────────

  /// Register a controller/repository only if it's not already registered.
  /// Returns the instance.
  T _ensurePut<T>(T Function() factory, {bool permanent = false}) {
    if (!Get.isRegistered<T>()) {
      return Get.put<T>(factory(), permanent: permanent);
    }
    return Get.find<T>();
  }

  /// Safely delete a controller if it exists.
  void _safeDelete<T>({bool force = false}) {
    if (Get.isRegistered<T>()) {
      Get.delete<T>(force: force);
    }
  }

  // ─── Ensure shared repositories (permanent, created once) ─────────────────

  void _ensureAssignmentDependencies() {
    _ensurePut<AssignmentRepository>(
      () => AssignmentRepository(apiClient: Get.find<ApiClient>()),
      permanent: true,
    );
    _ensurePut<ClassFeedRepository>(
      () => ClassFeedRepository(),
      permanent: true,
    );
  }

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
    // 1) Ensure repositories exist
    _ensureAssignmentDependencies();

    // 2) Register or re-use ClassAssignmentController
    if (!Get.isRegistered<ClassAssignmentController>()) {
      Get.put<ClassAssignmentController>(
        ClassAssignmentController(
          Get.find<AssignmentRepository>(),
          Get.find<ClassFeedRepository>(),
        ),
      );
    }

    // 3) Reinitialise with new args (handles same-section skip internally)
    Get.find<ClassAssignmentController>().reinitialise(args);

    // 4) Update navigation state
    classAssignmentArgs.value = args;
    isShowingClassAssignment.value = true;
  }

  void hideClassAssignment() {
    isShowingClassAssignment.value = false;
    classAssignmentArgs.value = null;

    // Dispose the controller to free memory
    _safeDelete<ClassAssignmentController>(force: true);
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

    // Also dispose ClassAssignmentController on role change
    if (isShowingClassAssignment.value) {
      _safeDelete<ClassAssignmentController>(force: true);
    }
    isShowingClassAssignment.value = false;
    classAssignmentArgs.value = null;

    // Delete ClassAssignmentController to clear stale state on role change
    if (Get.isRegistered<ClassAssignmentController>()) {
      Get.delete<ClassAssignmentController>(force: true);
    }

    if (Get.isRegistered<CommunityController>()) {
      Get.delete<CommunityController>(force: true);
    }
  }
}
