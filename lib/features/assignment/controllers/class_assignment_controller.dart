import 'package:LinkLian/core/utils/logger.dart';
import 'package:get/get.dart';
import '../../../data/repository/assignment_repository.dart';
import '../../../data/repository/class_feed_repository.dart';
import '../../../data/model/assignment_model.dart';

class ClassAssignmentController extends GetxController {
  final AssignmentRepository _assignmentRepository = Get.find<AssignmentRepository>();
  final ClassFeedRepository _classFeedRepository = Get.find<ClassFeedRepository>();

  final RxList<AssignmentModel> assignments = <AssignmentModel>[].obs;
  final RxList<AssignmentModel> filteredAssignments = <AssignmentModel>[].obs;
  final RxBool isLoading = false.obs;
  final RxBool isLoadingMore = false.obs; // ✅ เพิ่ม
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

    /// Filter options based on role
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
    final args = Get.arguments as Map<String, dynamic>? ?? {};
    sectionId = args['sectionId'] ?? 0;
    className = args['className'] ?? '';
    subjectName = args['subjectName'] ?? '';
    userRole.value = args['role'] ?? 'student';

    if (currentFilter.value.isEmpty) {
      currentFilter.value = isStudent ? 'ทั้งหมด' : 'โพสต์ล่าสุด';
    }

    // Fetch teacher name และ assignments พร้อมกัน
    _fetchTeacherName();
    fetchAssignments();
  }

  /// FETCH TEACHER NAME FROM SECTION EDUCATOR (เหมือน ClassDetail)
  Future<void> _fetchTeacherName() async {
    try {
      final result = await _classFeedRepository.getSectionEducators(
        sectionId: sectionId,
      );

      if (result != null && result.isNotEmpty) {
        // Get first educator (main teacher) - API returns sorted by position
        final teacherDisplayName = result[0]['display_name'] ?? 'ไม่ระบุ';
        teacherName.value = teacherDisplayName;
        AppLogger.info('👨‍🏫 Teacher name set: ${teacherName.value}');
      } else {
        teacherName.value = 'ไม่พบผู้สอนหลัก';
        AppLogger.info('⚠️ No educators found');
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
        default: // ทั้งหมด
          filteredAssignments.assignAll(assignments);
      }
    } else {
      // Teacher filters
      List<AssignmentModel> sorted = List.from(assignments);
      if (filter == 'โพสต์เก่าสุด') {
        sorted.sort((a, b) => (a.dueDate ?? DateTime(2099))
            .compareTo(b.dueDate ?? DateTime(2099)));
      } else {
        // โพสต์ล่าสุด (default)
        sorted.sort((a, b) => (b.dueDate ?? DateTime(2099))
            .compareTo(a.dueDate ?? DateTime(2099)));
      }
      filteredAssignments.assignAll(sorted);
    }

    AppLogger.info('🔍 Filter applied: $filter');
    AppLogger.info('📦 Filtered count: ${filteredAssignments.length}');
  }

  Future<void> fetchAssignments() async {
    AppLogger.info('🔍 fetchAssignments called - hasLoaded: $_hasLoadedOnce, isLoading: $_isCurrentlyLoading');
    
    if (_hasLoadedOnce || _isCurrentlyLoading) {
      AppLogger.info('⚠️ Skipped - already loaded or loading');
      return;
    }
    
    _isCurrentlyLoading = true;
    _hasLoadedOnce = true;
    AppLogger.info('✅ Starting fetch...');

    AppLogger.info('🔍 fetchAssignments called');

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

      AppLogger.info('📦 Raw result count: ${result.length}');
      AppLogger.info('📋 Raw Assignment IDs: ${result.map((a) => a.assignmentId).toList()}');
      AppLogger.info('📋 Raw Assignment Titles: ${result.map((a) => a.title).toList()}');

      assignments.clear();
      filteredAssignments.clear();

      AppLogger.info('📦 Fetched ${result.length} assignments');

      assignments.assignAll(result);
      _currentOffset = result.length;
      _hasMoreData = result.length == _limit;

      AppLogger.info('📦 assignments count after assignAll: ${assignments.length}');
      AppLogger.info('📋 Assignment IDs after assignAll: ${assignments.map((a) => a.assignmentId).toList()}');

      applyFilter(currentFilter.value);

      AppLogger.info('📦 filteredAssignments count after filter: ${filteredAssignments.length}');
      AppLogger.info('📋 Filtered Assignment IDs: ${filteredAssignments.map((a) => a.assignmentId).toList()}');
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
    if (!_hasMoreData || isLoadingMore.value) {
      AppLogger.info('⚠️ No more data or already loading');
      return;
    }

    AppLogger.info('🔄 Loading more assignments...');
    isLoadingMore.value = true;

    try {
      final result = await _assignmentRepository.getClassAssignments(
        sectionId: sectionId,
        role: userRole.value,
        offset: _currentOffset,
        limit: _limit,
      );

      AppLogger.info('📦 Loaded ${result.length} more assignments');

      if (result.isEmpty) {
        _hasMoreData = false;
        AppLogger.info('✅ No more assignments to load');
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

  // ✅ Pull to refresh (reset everything)
  Future<void> refreshAssignments() async {
    AppLogger.info('🔄 Refreshing assignments...');

    await Future.wait([
      _fetchTeacherName(),
      fetchAssignments(),
    ]);

    AppLogger.info('✅ Refresh complete');
  }
}