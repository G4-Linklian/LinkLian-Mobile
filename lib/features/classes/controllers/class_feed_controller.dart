import 'package:get/get.dart';

import '/data/model/class_feed_model.dart';
import '/data/model/semester_model.dart';
import '/data/repository/class_feed_repository.dart';
import '/data/repository/semester_repository.dart';
import '../../auth/controller/auth_controller.dart';

class ClassFeedController extends GetxController {
  final ClassFeedRepository classFeedRepository;
  final SemesterRepository semesterRepository;

  late final AuthController auth;

  ClassFeedController({
    required this.classFeedRepository,
    required this.semesterRepository,
  });

  int get instId => auth.instId.value!;
  String get roleName => auth.roleName.value!;

  final RxList<ClassFeedModel> classList = <ClassFeedModel>[].obs;
  final RxList<SemesterModel> semesters = <SemesterModel>[].obs;

  final RxnInt selectedSemesterId = RxnInt();

  final RxBool isLoading = false.obs;
  final RxnString errorMessage = RxnString();

  @override
  void onInit() {
    super.onInit();
    _setupListeners();
  }

  /// Setup listeners for user/instId changes
  void _setupListeners() {
    auth = Get.find<AuthController>();

    // Listen to instId changes (when user changes)
    ever<int?>(auth.instId, (instId) {
      if (instId != null) {
        _clearClassData();
        loadInitialData();
      } else {
        _clearClassData();
      }
    });

    // Load if instId already available
    if (auth.instId.value != null) {
      loadInitialData();
    }
  }

  /// Clear all class data
  void _clearClassData() {
    classList.clear();
    semesters.clear();
    selectedSemesterId.value = null;
    errorMessage.value = null;
  }

  Future<void> loadInitialData() async {
    try {
      isLoading.value = true;
      errorMessage.value = null;

      await fetchSemesters();
    } finally {
      isLoading.value = false;
    }
  }

  /// FETCH SEMESTER
  Future<void> fetchSemesters() async {
    try {
      final result = await semesterRepository.getSemesters(
        instId: auth.instId.value!,
      );

      semesters.assignAll(result);

      final openSemester = semesters.firstWhereOrNull(
        (s) => s.status == 'open',
      );

      selectedSemesterId.value =
          openSemester?.semesterId ?? semesters.first.semesterId;

      await fetchClassFeed();
    } catch (e) {
      errorMessage.value = e.toString();
    }
  }

  Future<void> fetchClassFeed() async {
    if (selectedSemesterId.value == null) return;

    try {
      isLoading.value = true;
      errorMessage.value = null;

      final result = await classFeedRepository.getClassFeed(
        semesterId: selectedSemesterId.value!,
      );

      classList.assignAll(result);
    } catch (e) {
      errorMessage.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> changeSemester(int semesterId) async {
    if (semesterId == selectedSemesterId.value) return;

    selectedSemesterId.value = semesterId;
    await fetchClassFeed();
  }

  Future<void> refreshFeed() async {
    await fetchClassFeed();
  }

  @override
  void onClose() {
    _clearClassData();
    super.onClose();
  }
}
