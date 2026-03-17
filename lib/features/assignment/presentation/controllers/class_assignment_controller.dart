import 'package:LinkLian/core/utils/logger.dart';
import 'package:get/get.dart';
import '../../data/repositories/assignment_repository.dart';
import '../../../shared/repositories/class_feed_repository.dart';
import '../../data/models/assignment_model.dart';
import '../../../layout/controllers/navigation_controller.dart';

class ClassAssignmentController extends GetxController {
 ClassAssignmentController(
    this._assignmentRepository,
    this._classFeedRepository,
  );
  final AssignmentRepository _assignmentRepository;
  final ClassFeedRepository _classFeedRepository;
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
      return ['ทั้งหมด', 'ส่งแล้ว', 'ยังไม่ส่ง', 'เกินกำหนดส่ง'];
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
    args ??= Get.arguments as Map<String, dynamic>?;

    if (args != null && args.isNotEmpty) {
      sectionId = args['sectionId'] ?? 0;
      className = args['className'] ?? '';
      subjectName = args['subjectName'] ?? '';
      userRole.value = args['role'] ?? 'student';

      if (currentFilter.value.isEmpty) {
        currentFilter.value = isStudent ? 'ทั้งหมด' : 'โพสต์ล่าสุด';
      }

      _fetchTeacherName();
      fetchAssignments();
    } else {
      sectionId = 0;
      className = '';
      subjectName = '';
      currentFilter.value = 'ทั้งหมด';
    }
  }

void reinitialise(Map<String, dynamic> args) {
  final newSectionId = args['sectionId'] ?? 0;

  if (newSectionId == sectionId && _hasLoadedOnce && !_isCurrentlyLoading) {
    appLog.info(
      '⏭️ Same sectionId ($newSectionId) already loaded — skip',
      actionPage: 'ClassAssignmentScreen',
    );
    return;
  }

  appLog.info(
    '🔄 Reinitialise → sectionId: $newSectionId (was: $sectionId)',
    actionPage: 'ClassAssignmentScreen',
  );

  sectionId = newSectionId;
  className = args['className'] ?? '';
  subjectName = args['subjectName'] ?? '';
  userRole.value = args['role'] ?? 'student';
  currentFilter.value = isStudent ? 'ทั้งหมด' : 'โพสต์ล่าสุด';
  _hasLoadedOnce = false;
  _isCurrentlyLoading = false;
  _currentOffset = 0;
  _hasMoreData = true;

  teacherName.value = '';
  assignments.clear();
  filteredAssignments.clear();
  errorMessage.value = '';

  appLog.info('ClassAssignmentScreen ($newSectionId)');

  _fetchTeacherName();
  fetchAssignments();
}

  Future<void> _fetchTeacherName() async {
    try {
      final result = await _classFeedRepository.getSectionEducators(
        sectionId: sectionId,
      );

      if (result.isNotEmpty) {
        final teacherDisplayName = result.first.fullName.isNotEmpty
            ? result.first.fullName
            : 'ไม่ระบุ';
        teacherName.value = teacherDisplayName;
      } else {
        teacherName.value = 'ไม่พบผู้สอนหลัก';
      }
    } catch (e) {
      appLog.info('❌ Error fetching teacher name: $e');
      teacherName.value = 'ไม่พบผู้สอนหลัก';
    }
  }

void applyFilter(String filter) {
  currentFilter.value = filter;

  if (isStudent) {
    filteredAssignments.assignAll(_filterItems(assignments));
  } else {
    final sorted = List<AssignmentModel>.from(assignments);

    if (filter == 'โพสต์เก่าสุด') {
      sorted.sort((a, b) {
        final aDate = a.createdAt ?? DateTime(2000);
        final bDate = b.createdAt ?? DateTime(2000);
        return aDate.compareTo(bDate);
      });
    } else {
      sorted.sort((a, b) {
        final aDate = a.createdAt ?? DateTime(2000);
        final bDate = b.createdAt ?? DateTime(2000);
        return bDate.compareTo(aDate);
      });
    }

    filteredAssignments.assignAll(sorted);
  }

  appLog.info(
    '🔍 Filter: $filter → ${filteredAssignments.length} items',
    actionPage: 'ClassAssignmentScreen',
  );
}

  Future<void> fetchAssignments() async {
    appLog.info(
        '🔍 fetchAssignments called - hasLoaded: $_hasLoadedOnce, isLoading: $_isCurrentlyLoading');

    if (_hasLoadedOnce || _isCurrentlyLoading) {
      appLog.info('⚠️ Skipped - already loaded or loading');
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

      appLog.info('📦 Fetched ${result.length} assignments');

      assignments.clear();
      filteredAssignments.clear();
      assignments.assignAll(result);
      _currentOffset = result.length;
      _hasMoreData = result.length == _limit;

      applyFilter(currentFilter.value);
    } catch (e) {
      appLog.info('❌ Error: $e');
      errorMessage.value = 'ไม่สามารถโหลดข้อมูลได้';
      _hasLoadedOnce = false;
    } finally {
      isLoading.value = false;
      _isCurrentlyLoading = false;
    }
  }

Future<void> loadMoreAssignments() async {
  if (!_hasMoreData || isLoadingMore.value || _isCurrentlyLoading) return;

  isLoadingMore.value = true;

  try {
    final result = await _assignmentRepository.getClassAssignments(
      sectionId: sectionId,
      role: userRole.value,
      offset: _currentOffset,
      limit: _limit,
    );

    appLog.info('📦 Load more: got ${result.length} assignments');

    if (result.isEmpty) {
      _hasMoreData = false;
    } else {
      assignments.addAll(result);
      _currentOffset += result.length;
      _hasMoreData = result.length == _limit;

      if (isTeacher) {
        applyFilter(currentFilter.value);
      } else {
        // student: เพิ่มเฉพาะ item ใหม่ที่ตรง filter ปัจจุบัน
        final newFiltered = _filterItems(result);
        filteredAssignments.addAll(newFiltered);
      }
    }
  } catch (e) {
    appLog.error('loadMoreAssignments failed: $e', actionPage: 'ClassAssignmentScreen');
  } finally {
    isLoadingMore.value = false;
  }
}

// helper แยก filter logic ออกมา
List<AssignmentModel> _filterItems(List<AssignmentModel> items) {
  switch (currentFilter.value) {
    case 'เกินกำหนดส่ง':
      return items.where((a) =>
        a.studentStatus == 'ส่งแล้วเกินกำหนด' ||
        a.studentStatus == 'ยังไม่ส่งเกินกำหนด').toList();
    case 'ยังไม่ส่ง':
      return items.where((a) => a.studentStatus == 'ยังไม่ส่ง').toList();
    case 'ส่งแล้ว':
      return items.where((a) => a.studentStatus == 'ส่งแล้ว').toList();
    default:
      return items;
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
