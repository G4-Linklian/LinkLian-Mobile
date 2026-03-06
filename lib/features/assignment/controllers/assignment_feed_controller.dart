import 'package:get/get.dart';
class AssignmentFeedController extends GetxController {
  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;
  final RxString userRole = 'student'.obs;

  bool get isTeacher => userRole.value == 'teacher';
  bool get isStudent => userRole.value == 'student';

  /// Section list — populated from ClassFeedController
  final RxList<dynamic> classes = <dynamic>[].obs;

  @override
  void onInit() {
    super.onInit();
    _loadFromClassFeed();
  }

  /// Load section data from the existing ClassFeedController
  void _loadFromClassFeed() {
    try {
      // ClassFeedController is already registered globally
      // Data will be passed via setClasses() from AssignmentPage
    } catch (_) {
      // ClassFeedController not found — will be loaded in page
    }
  }

  /// Called from AssignmentPage when it has access to class feed data
  void setClasses(List<dynamic> data) {
    classes.assignAll(data);
  }

  void setRole(String role) {
    userRole.value = role;
  }
}
