import 'package:get/get.dart';

/// Global navigation controller for managing bottom navigation state
/// This allows sub-pages to change the main tab without destroying themselves
class NavigationController extends GetxController {
  final RxInt selectedIndex = 1.obs; // Default to ClassesPage
  
  /// Track if currently showing class detail overlay
  final RxBool isShowingClassDetail = false.obs;
  
  /// Track the class detail arguments for restoration
  final Rx<Map<String, dynamic>?> classDetailArgs = Rx<Map<String, dynamic>?>(null);

  /// Change to a specific tab
  void changeTab(int index) {
    selectedIndex.value = index;
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
  
  /// Check if should show class detail when switching to class tab
  bool get shouldRestoreClassDetail => 
      isShowingClassDetail.value && classDetailArgs.value != null;
}