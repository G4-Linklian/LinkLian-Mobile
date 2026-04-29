import 'package:LinkLian/core/utils/logger.dart';
import 'package:get/get.dart';

import '../../data/models/class_feed_model.dart';
import '/data/model/semester_model.dart';
import '/features/shared/repositories/class_feed_repository.dart';
import '/data/repository/semester_repository.dart';
import '../../../auth/controller/auth_controller.dart';

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
  final RxBool isLoadingMore = false.obs;
  final RxBool hasMore = true.obs;
  final RxnString errorMessage = RxnString();
  
  int _offset = 0;
  final int _limit = 10;

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
        clearClassData();
        loadInitialData();
      } else {
        clearClassData();
      }
    });

    // Load if instId already available
    if (auth.instId.value != null) {
      loadInitialData();
    }
  }

  /// Clear all class data
  void clearClassData() {
    classList.clear();
    semesters.clear();
    selectedSemesterId.value = null;
    errorMessage.value = null;
    _offset = 0;
    hasMore.value = true;
  }

  Future<void> loadInitialData() async {
    try {
      isLoading.value = true;
      errorMessage.value = null;
      appLog.info('🚀 [ClassFeed] Loading initial data for instId: ${auth.instId.value}');

      await fetchSemesters();
    } finally {
      isLoading.value = false;
    }
  }

  /// FETCH SEMESTER
  Future<void> fetchSemesters() async {
    try {
      appLog.info('[ClassFeed] Fetching semesters for instId: ${auth.instId.value}', data: {
        'instId': auth.instId.value,
      });
      final result = await semesterRepository.getSemesters(
        instId: auth.instId.value!,
      );

      appLog.info('[ClassFeed] Got ${result.length} semesters', data: {
        'instId': auth.instId.value,
        'semesterCount': result.length,
      });
      
      semesters.assignAll(result);

      final openSemester = semesters.firstWhereOrNull(
        (s) => s.status == 'open',
      );

      selectedSemesterId.value =
          openSemester?.semesterId ?? (semesters.isNotEmpty ? semesters.first.semesterId : null);

      appLog.info('[ClassFeed] Selected semester', data: {
        'selectedSemesterId': selectedSemesterId.value,
      });

      if (selectedSemesterId.value != null) {
        await fetchClassFeed();
      } else {
      }
    } catch (e) {
      errorMessage.value = e.toString();
    }
  }

  Future<void> fetchClassFeed({bool loadMore = false}) async {
    if (selectedSemesterId.value == null) {
      return;
    }

    if (loadMore && !hasMore.value) {
      return;
    }

    if (loadMore && isLoadingMore.value) {
      return;
    }

    try {
      if (loadMore) {
        isLoadingMore.value = true;
      } else {
        isLoading.value = true;
        _offset = 0;
        classList.clear();
        hasMore.value = true;
      }

      errorMessage.value = null;

      appLog.info('🏫 [ClassFeed] Fetching class feed for semester: ${selectedSemesterId.value}, offset: $_offset, limit: $_limit');

      final result = await classFeedRepository.getClassFeed(
        semesterId: selectedSemesterId.value!,
        offset: _offset,
        limit: _limit,
      );

      appLog.info('[ClassFeed] Fetched ${result.length} classes', data: {
        'semesterId': selectedSemesterId.value,
        'offset': _offset,
        'limit': _limit,
        'fetchedCount': result.length,
      });

      if (result.length < _limit) {
        hasMore.value = false;
      }

      if (loadMore) {
        classList.addAll(result);
      } else {
        classList.assignAll(result);
      }

      _offset += result.length;

    } catch (e) {
      errorMessage.value = e.toString();
    } finally {
      isLoading.value = false;
      isLoadingMore.value = false;
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
    clearClassData();
    super.onClose();
  }
}
