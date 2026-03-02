import 'package:LinkLian/core/utils/logger.dart';
import 'package:get/get.dart';
import '../../../data/repository/assignment_repository.dart';
import '../../../data/repository/class_feed_repository.dart';
import '../../../data/model/assignment_model.dart';
import '../../layout/controllers/navigation_controller.dart';

class ClassAssignmentController extends GetxController {
  final AssignmentRepository _assignmentRepository =
      Get.find<AssignmentRepository>();
  final ClassFeedRepository _classFeedRepository =
      Get.find<ClassFeedRepository>();

  final RxList<AssignmentModel> assignments = <AssignmentModel>[].obs;
  final RxList<AssignmentModel> filteredAssignments =
      <AssignmentModel>[].obs;
  final RxBool isLoading = false.obs;
  final RxBool isLoadingMore = false.obs;
  final RxString errorMessage = ''.obs;
  final RxString currentFilter = ''.obs;
  final RxString userRole = 'student'.obs;
  final RxString teacherName = ''.obs;

  late int sectionId;
  late String className;
  late String subjectName;

  int _currentOffset = 0;
  final int _limit = 10;
  bool _hasMoreData = true;

  bool get isTeacher =>
      userRole.value == 'teacher' || userRole.value == 'instructor';
  bool get isStudent =>
      userRole.value == 'high school student' ||
      userRole.value == 'uni student';

  bool _hasLoadedOnce = false;
  bool _isCurrentlyLoading = false;

  List<String> get filterOptions {
    if (isStudent) {
      return ['ทั้งหมด', 'ส่งช้า', 'ยังไม่ส่ง', 'ส่งแล้ว'];
    } else {
      return ['โพสต์ล่าสุด', 'โพสต์เก่าสุด'];
    }
  }

  @override
  void onInit() {
    super.onInit();

    Map<String, dynamic>? args;
    if (Get.isRegistered<NavigationController>()) {
      args = Get.find<NavigationController>().classAssignmentArgs.value;
    }
    args ??= Get.arguments as Map<String, dynamic>? ?? {};

    sectionId = args['sectionId'] ?? 0;
    className = args['className'] ?? '';
    subjectName = args['subjectName'] ?? '';
    userRole.value = args['role'] ?? 'student';

    if (currentFilter.value.isEmpty) {
      currentFilter.value = isStudent ? 'ทั้งหมด' : 'โพสต์ล่าสุด';
    }

    _fetchTeacherName();
    fetchAssignments();
  }


  void reinitialise(Map<String, dynamic> args) {
    final newSectionId = args['sectionId'] ?? 0;
    if (newSectionId == sectionId && _hasLoadedOnce) return;

    sectionId = newSectionId;
    className = args['className'] ?? '';
    subjectName = args['subjectName'] ?? '';
    userRole.value = args['role'] ?? 'student';

    currentFilter.value = isStudent ? 'ทั้งหมด' : 'โพสต์ล่าสุด';

    _hasLoadedOnce = false;
    _isCurrentlyLoading = false;

    teacherName.value = '';
    assignments.clear();
    filteredAssignments.clear();
    errorMessage.value = '';

    _fetchTeacherName();
    fetchAssignments();
  }

  Future<void> _fetchTeacherName() async {
    try {
      final result = await _classFeedRepository.getSectionEducators(
        sectionId: sectionId,
      );

      if (result != null && result.isNotEmpty) {
        teacherName.value = result[0]['display_name'] ?? 'ไม่ระบุ';
        AppLogger.info('👨‍🏫 Teacher name set: ${teacherName.value}');
      } else {
        teacherName.value = 'ไม่พบผู้สอนหลัก';
      }
    } catch (e) {
      AppLogger.info('❌ Error fetching teacher name: $e');
      teacherName.value = 'ไม่พบผู้สอนหลัก';
    }
  }

  void applyFilter(String filter) {
    currentFilter.value = filter;

    if (isStudent) {
      switch (filter) {
        case 'ส่งช้า':
          filteredAssignments.assignAll(
            assignments.where((a) =>
                a.studentStatus == 'ส่งแล้วเกินกำหนด' ||
                a.studentStatus == 'ยังไม่ส่งเกินกำหนด'),
          );
          break;
        case 'ยังไม่ส่ง':
          filteredAssignments.assignAll(
            assignments.where((a) =>
                a.studentStatus == 'ยังไม่ส่ง' ||
                a.studentStatus == 'ยังไม่ส่งเกินกำหนด'),
          );
          break;
        case 'ส่งแล้ว':
          filteredAssignments.assignAll(
            assignments.where((a) =>
                a.studentStatus == 'ส่งแล้ว' ||
                a.studentStatus == 'ส่งแล้วเกินกำหนด'),
          );
          break;
        default:
          filteredAssignments.assignAll(assignments);
      }
    } else {
      List<AssignmentModel> sorted = List.from(assignments);
      if (filter == 'โพสต์เก่าสุด') {
        sorted.sort((a, b) => (a.dueDate ?? DateTime(2099))
            .compareTo(b.dueDate ?? DateTime(2099)));
      } else {
        sorted.sort((a, b) => (b.dueDate ?? DateTime(2099))
            .compareTo(a.dueDate ?? DateTime(2099)));
      }
      filteredAssignments.assignAll(sorted);
    }

    AppLogger.info('🔍 Filter applied: $filter');
    AppLogger.info('📦 Filtered count: ${filteredAssignments.length}');
  }

  Future<void> fetchAssignments() async {
    AppLogger.info(
        '🔍 fetchAssignments called - hasLoaded: $_hasLoadedOnce, isLoading: $_isCurrentlyLoading');

    if (_hasLoadedOnce || _isCurrentlyLoading) {
      AppLogger.info('⚠️ Skipped - already loaded or loading');
      return;
    }

    _isCurrentlyLoading = true;
    _hasLoadedOnce = true;

    isLoading.value = true;
    errorMessage.value = '';
    _currentOffset = 0;
    _hasMoreData = true;

    try {
      final result = await _assignmentRepository.getClassAssignments(
        sectionId: sectionId,
        role: userRole.value,
        offset: _currentOffset,
        limit: _limit,
      );

      AppLogger.info('📦 Fetched ${result.length} assignments');

      assignments.clear();
      filteredAssignments.clear();
      assignments.assignAll(result);
      _currentOffset = result.length;
      _hasMoreData = result.length == _limit;

      applyFilter(currentFilter.value);
    } catch (e) {
      AppLogger.info('❌ Error: $e');
      errorMessage.value = 'ไม่สามารถโหลดข้อมูลได้';
      _hasLoadedOnce = false;
    } finally {
      isLoading.value = false;
      _isCurrentlyLoading = false;
    }
  }

  Future<void> loadMoreAssignments() async {
    if (!_hasMoreData || isLoadingMore.value) return;

    isLoadingMore.value = true;

    try {
      final result = await _assignmentRepository.getClassAssignments(
        sectionId: sectionId,
        role: userRole.value,
        offset: _currentOffset,
        limit: _limit,
      );

      if (result.isEmpty) {
        _hasMoreData = false;
      } else {
        assignments.addAll(result);
        _currentOffset += result.length;
        _hasMoreData = result.length == _limit;
        applyFilter(currentFilter.value);
      }
    } catch (e) {
      AppLogger.info('❌ Error loading more: $e');
    } finally {
      isLoadingMore.value = false;
    }
  }

  Future<void> refreshAssignments() async {
    _hasLoadedOnce = false;
    _isCurrentlyLoading = false;
    await Future.wait([
      _fetchTeacherName(),
      fetchAssignments(),
    ]);
  }
}