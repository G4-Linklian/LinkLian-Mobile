import 'package:LinkLian/core/utils/logger.dart';
import 'package:get/get.dart';
import '../controllers/class_detail_filter.dart';
import '../../../data/repository/post_repository.dart';
import '../../../data/repository/class_feed_repository.dart';
import '../controllers/class_feed_controller.dart';
import '../../../data/model/post_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter/animation.dart';
import '../../../core/utils/dialog_helper.dart';
import '../../layout/controllers/navigation_controller.dart';

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

  final isLoadingClassInfo = false.obs;
  final RxString classInfoError = ''.obs;
  final schedules = <Map<String, dynamic>>[].obs;
  final members = <Map<String, dynamic>>[].obs;
  final educators = <Map<String, dynamic>>[].obs;

  int _offset = 0;
  final int _limit = 10;

  final PostRepository _postRepository = PostRepository();
  final ClassFeedRepository _classFeedRepository = ClassFeedRepository();
  final ScrollController scrollController = ScrollController();

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
    AppLogger.info('📝 [ClassDetail] onInit called');
  }

  @override
  void onReady() {
    super.onReady();
    AppLogger.info('📝 [ClassDetail] onReady called');
    
    // Try to initialize from NavigationController if not already initialized
    if (sectionId.value == null) {
      try {
        final navController = Get.find<NavigationController>();
        final args = navController.classDetailArgs.value;
        
        AppLogger.info('📝 [ClassDetail] onReady - args from NavigationController: $args');
        
        if (args != null) {
          AppLogger.info('📝 [ClassDetail] Initializing from NavigationController in onReady');
          initializeWithArgs(args);
        } else {
          AppLogger.info('⚠️ [ClassDetail] No args available in onReady');
        }
      } catch (e) {
        AppLogger.info('❌ [ClassDetail] Error in onReady: $e');
      }
    } else {
      AppLogger.info('📝 [ClassDetail] Already initialized with sectionId: ${sectionId.value}');
    }
  }

  void initializeWithArgs(Map<String, dynamic> args) {
    final newSectionId = args['sectionId'] as int?;
    
    AppLogger.info('📝 [ClassDetail] initializeWithArgs called');
    AppLogger.info('📝 [ClassDetail] newSectionId: $newSectionId');
    AppLogger.info('📝 [ClassDetail] current sectionId: ${sectionId.value}');
    AppLogger.info('📝 [ClassDetail] subjectName from args: ${args['subjectName']}');
    AppLogger.info('📝 [ClassDetail] className from args: ${args['className']}');
    
    if (sectionId.value != null && sectionId.value != newSectionId) {
      selectedFilter.value = ClassPostFilter.all;
      AppLogger.info('📝 [ClassDetail] Filter reset to ALL for new section');
    }
    
    if (sectionId.value == newSectionId && posts.isNotEmpty) {
      AppLogger.info('📝 [ClassDetail] Same section with data, skipping refetch');
      return;
    }
    
    if (newSectionId != null) {
      // Set values immediately
      sectionId.value = newSectionId;
      subjectNameTh.value = args['subjectName'] as String? ?? '';
      effectiveClassName.value = args['className'] as String? ?? '';
      
      AppLogger.info('📝 [ClassDetail] Values set:');
      AppLogger.info('  - sectionId: ${sectionId.value}');
      AppLogger.info('  - subjectNameTh: ${subjectNameTh.value}');
      AppLogger.info('  - effectiveClassName: ${effectiveClassName.value}');
      
      // Fetch additional data
      fetchClassDetailFromFeed();
      fetchPosts();
    } else {
      AppLogger.info('❌ [ClassDetail] newSectionId is null!');
    }
  }

  void fetchClassDetailFromFeed() {
    try {
      AppLogger.info('📝 [ClassDetail] fetchClassDetailFromFeed called');
      
      if (sectionId.value == null) {
        AppLogger.info('⚠️ [ClassDetail] sectionId is null, skipping fetch');
        return;
      }

      if (!Get.isRegistered<ClassFeedController>()) {
        AppLogger.info('⚠️ [ClassDetail] ClassFeedController not registered, using fallback');
        _fetchClassDetailFallback();
        return;
      }

      final feedController = Get.find<ClassFeedController>();

      final classDetail = feedController.classList.firstWhereOrNull(
        (c) => c.sectionId == sectionId.value,
      );

      if (classDetail != null) {
        AppLogger.info('✅ [ClassDetail] Found class detail in feed controller');
        subjectNameTh.value = classDetail.subjectNameTh;
        effectiveClassName.value = classDetail.effectiveClassName;
        
        AppLogger.info('  - Updated subjectNameTh: ${subjectNameTh.value}');
        AppLogger.info('  - Updated effectiveClassName: ${effectiveClassName.value}');
        
        _fetchTeacherName();
      } else {
        AppLogger.info('⚠️ [ClassDetail] Class detail not found in feed, using fallback');
        _fetchClassDetailFallback();
      }
    } catch (e) {
      AppLogger.info('❌ [ClassDetail] Error in fetchClassDetailFromFeed: $e');
      _fetchClassDetailFallback();
    }
  }

  Future<void> _fetchTeacherName() async {
    try {
      AppLogger.info('📝 [ClassDetail] _fetchTeacherName called');
      
      if (sectionId.value == null) {
        AppLogger.info('⚠️ [ClassDetail] sectionId is null, skipping teacher fetch');
        return;
      }

      final result = await _classFeedRepository.getSectionEducators(
        sectionId: sectionId.value!,
      );

      if (result != null && result.isNotEmpty) {
        final teacherDisplayName = result[0]['display_name'] ?? 'ไม่ระบุ';
        teacherName.value = teacherDisplayName;
        AppLogger.info('✅ [ClassDetail] Teacher name set: ${teacherName.value}');
      } else {
        teacherName.value = 'ไม่พบผู้สอนหลัก';
        AppLogger.info('⚠️ [ClassDetail] No teacher found');
      }
    } catch (e) {
      AppLogger.info('❌ [ClassDetail] Error fetching teacher name: $e');
      teacherName.value = 'ไม่พบผู้สอนหลัก';
    }
  }

  Future<void> fetchClassInfo() async {
    try {
      if (sectionId.value == null) return;

      isLoadingClassInfo.value = true;
      classInfoError.value = '';

      final data = await _classFeedRepository.getClassInfo(
        sectionId: sectionId.value!,
      );

      if (data != null) {
        schedules.assignAll(
          List<Map<String, dynamic>>.from(data['schedules'] ?? []),
        );
        members.assignAll(
          List<Map<String, dynamic>>.from(data['members'] ?? []),
        );
        educators.assignAll(
          List<Map<String, dynamic>>.from(data['educators'] ?? []),
        );
      } else {
        classInfoError.value = 'ไม่พบข้อมูล';
      }
    } catch (e) {
      AppLogger.info('❌ Error fetching class info: $e');
      classInfoError.value = 'ไม่สามารถโหลดข้อมูลได้';
    } finally {
      isLoadingClassInfo.value = false;
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
      AppLogger.info('📝 [ClassDetail] _fetchClassDetailFallback called');
      
      if (sectionId.value == null) {
        AppLogger.info('⚠️ [ClassDetail] sectionId is null in fallback');
        return;
      }

      isLoading.value = true;

      final classDetail = await _classFeedRepository.getClassDetail(
        sectionId: sectionId.value!,
      );

      if (classDetail != null) {
        subjectNameTh.value = classDetail.subjectNameTh;
        effectiveClassName.value = classDetail.effectiveClassName;
        
        AppLogger.info('✅ [ClassDetail] Fallback success:');
        AppLogger.info('  - subjectNameTh: ${subjectNameTh.value}');
        AppLogger.info('  - effectiveClassName: ${effectiveClassName.value}');
      } else {
        subjectNameTh.value = 'ไม่ระบุ';
        effectiveClassName.value = 'ไม่ระบุ';
        AppLogger.info('⚠️ [ClassDetail] Fallback returned null');
      }
    } catch (e) {
      AppLogger.info('❌ [ClassDetail] Fallback error: $e');
      subjectNameTh.value = 'ไม่ระบุ';
      effectiveClassName.value = 'ไม่ระบุ';
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> fetchPosts({bool loadMore = false, bool keepScroll = false}) async {
    if (loadMore && !hasMore.value) {
      AppLogger.info('⚠️ [ClassDetail] No more posts to load');
      return;
    }

    if (loadMore && isLoadingMore.value) {
      AppLogger.info('⚠️ [ClassDetail] Already loading more');
      return;
    }

    double? savedOffset;

    if (keepScroll && scrollController.hasClients) {
      savedOffset = scrollController.offset;
    }

    try {
      if (loadMore) {
        isLoadingMore.value = true;
        await Future.delayed(const Duration(milliseconds: 300));
      } else {
        isLoading.value = true;
        _offset = 0;
        posts.clear();
        hasMore.value = true;
      }

      if (sectionId.value == null) {
        throw Exception('sectionId is null');
      }

      AppLogger.info('📝 [ClassDetail] Fetching posts: offset=$_offset, limit=$_limit');

      final result = await _postRepository.getPostInClass(
        sectionId: sectionId.value!,
        filterType: selectedFilter.value.apiValue,
        offset: _offset,
        limit: _limit,
      );

      AppLogger.info('📝 [ClassDetail] Got ${result.length} posts (hasMore: $hasMore)');
      AppLogger.info('📝 [ClassDetail] Current total: ${posts.length} posts');

      if (result.length < _limit) {
        hasMore.value = false;
        AppLogger.info('✅ [ClassDetail] No more posts to load');
      }

      if (loadMore) {
        posts.addAll(result);
        AppLogger.info('📝 [ClassDetail] Added ${result.length} posts, new total: ${posts.length}');
      } else {
        posts.assignAll(result);
        AppLogger.info('📝 [ClassDetail] Replaced with ${result.length} posts');
      }

      _offset += result.length;
      AppLogger.info('📝 [ClassDetail] New offset: $_offset');

    } catch (e) {
      Get.snackbar('เกิดข้อผิดพลาด', 'ไม่สามารถโหลดโพสต์ได้');
      AppLogger.info('❌ [ClassDetail] Error: $e');
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
      selectedPostIdsForAI.remove(postId);
    } else {
      selectedPostIdsForAI.add(postId);
    }
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