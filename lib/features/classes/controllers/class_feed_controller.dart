import 'package:get/get.dart';

import '/data/model/class_feed_model.dart';
import '/data/model/semester_model.dart';
import '/data/repository/class_feed_repository.dart';
import '/data/repository/semester_repository.dart';

class ClassFeedController extends GetxController {
  final ClassFeedRepository classFeedRepository;
  final SemesterRepository semesterRepository;

  /// inst_id ของ user (ต้องส่งมาจาก auth/session)
  final int instId;
  final String roleName;


  ClassFeedController({
    required this.classFeedRepository,
    required this.semesterRepository,
    required this.instId,
    required this.roleName,
  });

  /// ============================
  /// STATE
  /// ============================

  final RxList<ClassFeedModel> classList = <ClassFeedModel>[].obs;
  final RxList<SemesterModel> semesters = <SemesterModel>[].obs;

  final RxnInt selectedSemesterId = RxnInt();

  final RxBool isLoading = false.obs;
  final RxnString errorMessage = RxnString();

  /// ============================
  /// LIFECYCLE
  /// ============================

  @override
  void onInit() {
    super.onInit();
    loadInitialData();
  }

  /// ============================
  /// DATA FLOW
  /// ============================

  Future<void> loadInitialData() async {
    try {
      isLoading.value = true;
      errorMessage.value = null;

      await fetchSemesters();

      if (selectedSemesterId.value != null) {
        await fetchClassFeed();
      }
    } catch (e) {
      errorMessage.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }

  /// ============================
  /// FETCH SEMESTER (REAL DATA)
  /// ============================

  Future<void> fetchSemesters() async {
    final result = await semesterRepository.getSemesters(
      instId: instId,
    );

    semesters.assignAll(result);

    /// เลือก semester ที่ status = open ก่อน
    final openSemester = semesters.firstWhereOrNull(
      (s) => s.status == 'open',
    );

    selectedSemesterId.value =
        openSemester?.semesterId ?? semesters.first.semesterId;
  }

  /// ============================
  /// FETCH CLASS FEED
  /// ============================

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

  /// ============================
  /// CHANGE SEMESTER
  /// ============================

  Future<void> changeSemester(int semesterId) async {
    if (semesterId == selectedSemesterId.value) return;

    selectedSemesterId.value = semesterId;
    await fetchClassFeed();
  }

  /// ============================
  /// REFRESH
  /// ============================

  Future<void> refreshFeed() async {
    await fetchClassFeed();
  }
}