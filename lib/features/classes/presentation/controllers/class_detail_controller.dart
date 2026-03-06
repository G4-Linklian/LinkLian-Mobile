import 'package:LinkLian/core/utils/logger.dart';
import 'package:get/get.dart';
import 'class_detail_filter.dart';
import '../../../shared/repositories/post_repository.dart';
import '../../../shared/repositories/class_feed_repository.dart';
import 'class_feed_controller.dart';
import '../../../shared/models/post_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter/animation.dart';
import '../../../../core/utils/dialog_helper.dart';
import '../../../layout/controllers/navigation_controller.dart';

class ClassDetailController extends GetxController {
  final Rx<int?> sectionId = Rx<int?>(null);
  final Rx<String> subjectNameTh = Rx<String>('');
  final Rx<String> effectiveClassName = Rx<String>('');
  final Rx<String> teacherName = Rx<String>('');

  final Rx<ClassPostFilter> selectedFilter = ClassPostFilter.all.obs;
  final isLoading = false.obs;
  final isLoadingMore = false.obs;
  final hasMore = true.obs;
  final RxList<PostModel> posts = <PostModel>[].obs;
  final RxSet<int> selectedPostIdsForAI = <int>{}.obs;

  // Maximum posts that can be selected for AI summary
  // Currently 1, but can be increased in future for multi-select flow
  static const int maxAISelectCount = 1;

  // final isLoadingClassInfo = false.obs;
  // final RxString classInfoError = ''.obs;
  final schedules = <Map<String, dynamic>>[].obs;
  // final members = <Map<String, dynamic>>[].obs;
  // final educators = <Map<String, dynamic>>[].obs;

  int _offset = 0;
  final int _limit = 10;

  final PostRepository _postRepository = PostRepository();
  final ClassFeedRepository _classFeedRepository = ClassFeedRepository();
  final ScrollController scrollController = ScrollController();
  // เพิ่ม fields เหล่านี้ใน ClassDetailController
  DateTime? _lastFetchTime;
  int? _lastKnownPostCount;
  static const _refreshThresholdSeconds = 30; // โหลดใหม่ถ้าผ่านไป 30 วิ
  List<int> get effectiveSectionIds {
    return [if (sectionId.value != null) sectionId.value!];
  }

  List<String> get uniqueLocations {
    final locations = <String>{};

    for (final schedule in schedules) {
      final room = schedule['room'] as Map<String, dynamic>?;
      final building = schedule['building'] as Map<String, dynamic>?;

      if (room != null) {
        final roomNumber = room['room_number']?.toString() ?? '';
        final buildingName = building?['building_name']?.toString() ?? '';

        if (roomNumber.isNotEmpty || buildingName.isNotEmpty) {
          final location = [
            if (buildingName.isNotEmpty) buildingName,
            if (roomNumber.isNotEmpty) 'ห้อง $roomNumber',
          ].join(' ');

          if (location.isNotEmpty) {
            locations.add(location);
          }
        }
      }
    }

    return locations.toList();
  }

  @override
  void onInit() {
    super.onInit();
    appLog.info('[ClassDetail] onInit called');
  }

  @override
  void onReady() {
    super.onReady();
    appLog.info('[ClassDetail] onReady called');

    // Try to initialize from NavigationController if not already initialized
    if (sectionId.value == null) {
      try {
        final navController = Get.find<NavigationController>();
        final args = navController.classDetailArgs.value;

        appLog.info(
          '[ClassDetail] onReady - args from NavigationController: $args',
        );

        if (args != null) {
          appLog.info(
            '[ClassDetail] Initializing from NavigationController in onReady',
          );
          initializeWithArgs(args);
        } else {
          appLog.info('[ClassDetail] No args available in onReady');
        }
      } catch (e) {
        appLog.error('[ClassDetail] Error in onReady: $e');
      }
    } else {
      appLog.info(
        '[ClassDetail] Already initialized with sectionId: ${sectionId.value}',
      );
    }
  }

  void initializeWithArgs(Map<String, dynamic> args) {
    final newSectionId = args['sectionId'] as int?;

  if (newSectionId == null) {
    appLog.error('[ClassDetail] sectionId is null', actionPage: 'ClassDetailScreen');
    return;
  }

    final isNewSection = sectionId.value != newSectionId;

  if (isNewSection) {
    // เปลี่ยน section — reset ทุกอย่าง
    selectedFilter.value = ClassPostFilter.all;
    _lastFetchTime = null;
    _lastKnownPostCount = null;
    posts.clear();
    hasMore.value = true;
    _offset = 0;
    appLog.info('[ClassDetail] New section', data : {
      'oldSectionId': sectionId.value,
      'newSectionId': newSectionId,
    }, actionPage: 'ClassDetailScreen');
  }

    sectionId.value = newSectionId;
    subjectNameTh.value = args['subjectName'] as String? ?? '';
    effectiveClassName.value = args['className'] as String? ?? '';

    fetchClassDetailFromFeed();

  if (isNewSection) {
    fetchPosts();
  } else {
    refreshIfNeeded();
  }
}

  /// เรียกเมื่อกลับมาที่หน้านี้จากหน้าอื่น (เช่น หลังโพสต์)
  Future<void> refreshIfNeeded() async {
    if (sectionId.value == null) return;

  // ถ้าไม่มีโพสต์เลย — โหลดเสมอ
  if (posts.isEmpty) {
    appLog.info('[ClassDetail] No posts — fetching', actionPage: 'ClassDetailScreen');
    await fetchPosts();
    return;
  }

  final lastFetch = _lastFetchTime;
  if (lastFetch == null) {
    appLog.info('[ClassDetail] Never loaded — fetching', actionPage: 'ClassDetailScreen');
    await fetchPosts();
    return;
  }

    final secondsSinceFetch = DateTime.now().difference(lastFetch).inSeconds;

  if (secondsSinceFetch >= _refreshThresholdSeconds) {
    appLog.info('[ClassDetail] Data stale (${secondsSinceFetch}s) — refreshing', 
    data: {
      'lastFetch': lastFetch,
      'currentTime': DateTime.now(),
    }, 
    actionPage: 'ClassDetailScreen');
    await fetchPosts();
    return;
  }
}



  void fetchClassDetailFromFeed() {
    try {

      if (sectionId.value == null) {
        appLog.info('⚠️ [ClassDetail] sectionId is null, skipping fetch');
        return;
      }
      if (!Get.isRegistered<ClassFeedController>()) {
        _fetchClassDetailFallback();
        return;
      }

      final feedController = Get.find<ClassFeedController>();

      final classDetail = feedController.classList.firstWhereOrNull(
        (c) => c.sectionId == sectionId.value,
      );

      if (classDetail != null) {
        subjectNameTh.value = classDetail.subjectNameTh;
        effectiveClassName.value = classDetail.effectiveClassName;

        _fetchTeacherName();
      } else {
        _fetchClassDetailFallback();
      }
    } catch (e) {
      _fetchClassDetailFallback();
    }
  }

  Future<void> _fetchTeacherName() async {
    try {
      if (sectionId.value == null) {
        return;
      }

      final result = await _classFeedRepository.getSectionEducators(
        sectionId: sectionId.value!,
      );

      if (result != null && result.isNotEmpty) {
        final teacherDisplayName = result[0]['display_name'] ?? 'ไม่ระบุ';
        teacherName.value = teacherDisplayName;
        appLog.info(
          '[ClassDetail] Teacher name set: ${teacherName.value}',
        );
      } else {
        teacherName.value = 'ไม่พบผู้สอนหลัก';
        appLog.debug('[ClassDetail] No teacher found');
      }
    } catch (e) {
      appLog.info('[ClassDetail] Error fetching teacher name: $e');
      teacherName.value = 'ไม่พบผู้สอนหลัก';
    }
  }

  String formatTime(String time) {
    if (time.isEmpty) return '';

    final parts = time.split(':');
    if (parts.length >= 2) {
      return '${parts[0]}:${parts[1]}';
    }

    return time;
  }

  void removePostOptimistic(int postId) {
    posts.removeWhere((p) => p.postId == postId);
  }

  void updatePostOptimistic(PostModel updatedPost) {
    final index = posts.indexWhere(
      (p) => p.postContentId == updatedPost.postContentId,
    );

    if (index == -1) return;

    posts[index] = updatedPost;
    posts.refresh();
  }

  Future<void> _fetchClassDetailFallback() async {
    try {
      appLog.info('[ClassDetail] _fetchClassDetailFallback called');

      if (sectionId.value == null) {
        appLog.info('[ClassDetail] sectionId is null in fallback');
        return;
      }

      isLoading.value = true;

      final classDetail = await _classFeedRepository.getClassDetail(
        sectionId: sectionId.value!,
      );

      if (classDetail != null) {
        subjectNameTh.value = classDetail.subjectNameTh;
        effectiveClassName.value = classDetail.effectiveClassName;

        appLog.info('[ClassDetail] Fallback success:');
      } else {
        subjectNameTh.value = 'ไม่ระบุ';
        effectiveClassName.value = 'ไม่ระบุ';
      }
    } catch (e) {
      subjectNameTh.value = 'ไม่ระบุ';
      effectiveClassName.value = 'ไม่ระบุ';
    } finally {
      isLoading.value = false;
    }
  }

Future<void> fetchPosts({bool loadMore = false, bool keepScroll = false}) async {
  if (loadMore && !hasMore.value) {
    return;
  }

  if (loadMore && isLoadingMore.value) {
    appLog.warning('[ClassDetail] Already loading more');
    return;
  }

  // ป้องกันโหลดซ้ำขณะที่กำลังโหลดอยู่
  if (!loadMore && isLoading.value) {
    appLog.warning('[ClassDetail] Already loading');
    return;
  }

    double? savedOffset;
    if (keepScroll && scrollController.hasClients) {
      savedOffset = scrollController.offset;
    }

  try {
    if (loadMore) {
      isLoadingMore.value = true;
    } else {
      isLoading.value = true;
      _offset = 0;
      posts.clear();
      hasMore.value = true;
    }

      if (sectionId.value == null) {
        throw Exception('sectionId is null');
      }

    appLog.info(
      '[ClassDetail]', 
      data: {
        'sectionId': sectionId.value,
        'offset': _offset,
        'loadMore': loadMore
      },
      actionPage: 'ClassDetailScreen',
    );

      final result = await _postRepository.getPostInClass(
        sectionId: sectionId.value!,
        filterType: selectedFilter.value.apiValue,
        offset: _offset,
        limit: _limit,
      );

    if (!loadMore) {
      _lastFetchTime = DateTime.now();
      _lastKnownPostCount = result.length;
    }

    if (result.length < _limit) {
      hasMore.value = false;
      appLog.info('[ClassDetail] No more posts to load');
    }

    if (loadMore) {
      posts.addAll(result);
      appLog.info(
        '[ClassDetail] Added ${result.length} posts, total: ${posts.length}', 
        data: {
          'newPosts': result.length,
          'totalPosts': posts.length,
        },
      );
    } else {
      posts.assignAll(result);
      if (result.isEmpty) {
        appLog.error('Posts', actionPage: 'ClassDetailScreen', exception: 'No posts found');
      } else {
        appLog.error('Posts', actionPage: 'ClassDetailScreen', data: result.length);
      }
    }

    _offset += result.length;

  } catch (e) {
    appLog.error('fetchPosts failed: $e', actionPage: 'ClassDetailScreen');
    Get.snackbar('เกิดข้อผิดพลาด', 'ไม่สามารถโหลดโพสต์ได้');
  } finally {
    isLoading.value = false;
    isLoadingMore.value = false;

      if (savedOffset != null && scrollController.hasClients) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          final offset = savedOffset!;
          final max = scrollController.position.maxScrollExtent;
          scrollController.jumpTo(offset > max ? max : offset);
        });
      }
    }
  }

  void changeFilter(ClassPostFilter filter) {
    selectedFilter.value = filter;
    fetchPosts();
  }

  void togglePostSelection(int postId) {
    if (selectedPostIdsForAI.contains(postId)) {
      // Deselect
      selectedPostIdsForAI.remove(postId);
    } else {
      // Check if can select more (respects maxAISelectCount limit)
      if (selectedPostIdsForAI.length < maxAISelectCount) {
        selectedPostIdsForAI.add(postId);
      }
      // If already at max, do nothing (UI should prevent this)
    }
  }

  /// Check if a post can be selected for AI
  /// Returns true if the post is already selected OR there's room for more selections
  bool canSelectForAI(int postId) {
    return selectedPostIdsForAI.contains(postId) ||
        selectedPostIdsForAI.length < maxAISelectCount;
  }

  /// Clear all AI selections (useful when returning from AI flow)
  void clearAISelections() {
    selectedPostIdsForAI.clear();
  }

  Future<void> generateAISummary() async {
    if (selectedPostIdsForAI.isEmpty) {
      Get.snackbar('แจ้งเตือน', 'กรุณาเลือกโพสต์อย่างน้อย 1 โพสต์');
      return;
    }

    try {
      Get.snackbar(
        'กำลังสรุป',
        'กำลังสรุปโพสต์ ${selectedPostIdsForAI.length} รายการ...',
      );
    } catch (e) {
      Get.snackbar('เกิดข้อผิดพลาด', 'ไม่สามารถสรุปเนื้อหาได้');
    }
  }

  void scrollToTop() {
    Future.delayed(const Duration(milliseconds: 300), () {
      if (scrollController.hasClients) {
        scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void onClose() {
    scrollController.dispose();
    selectedPostIdsForAI.clear();
    super.onClose();
  }
}
