import 'package:get/get.dart';
import '../controllers/class_detail_filter.dart';
import '../../../data/repository/post_repository.dart';
import '../../../data/repository/class_feed_repository.dart';
import '../controllers/class_feed_controller.dart';
import '../../../data/model/post_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter/animation.dart';

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

  int _offset = 0;
  final int _limit = 10;

  final PostRepository _postRepository = PostRepository();
  final ClassFeedRepository _classFeedRepository = ClassFeedRepository();
  final ScrollController scrollController = ScrollController();

  List<int> get effectiveSectionIds {
    return [if (sectionId.value != null) sectionId.value!];
  }

  @override
  void onInit() {
    super.onInit();
    // Don't initialize from Get.arguments here - will be called from initializeWithArgs
  }

  /// Initialize controller with args (called from ClassDetailPage)
  void initializeWithArgs(Map<String, dynamic> args) {
    final newSectionId = args['sectionId'] as int?;
    
    // ✅ Reset filter เมื่อเปลี่ยน class
    if (sectionId.value != null && sectionId.value != newSectionId) {
      selectedFilter.value = ClassPostFilter.all;
      debugPrint('📝 [ClassDetail] Filter reset to ALL for new section');
    }
    
    // If same section, don't refetch
    if (sectionId.value == newSectionId && posts.isNotEmpty) {
      debugPrint('📝 [ClassDetail] Same section with data, skipping refetch');
      return;
    }
    
    if (newSectionId != null) {
      sectionId.value = newSectionId;
      subjectNameTh.value = args['subjectName'] as String? ?? '';
      effectiveClassName.value = args['className'] as String? ?? '';
      
      // Fetch class detail and posts
      fetchClassDetailFromFeed();
      fetchPosts();
    }
  }

  /// FETCH CLASS DETAIL FROM FEED
  void fetchClassDetailFromFeed() {
    try {
      if (sectionId.value == null) return;

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
        
        // Fetch teacher name separately
        _fetchTeacherName();
      } else {
        _fetchClassDetailFallback();
      }
    } catch (e) {
      _fetchClassDetailFallback();
    }
  }

  /// FETCH TEACHER NAME FROM SECTION EDUCATOR
  Future<void> _fetchTeacherName() async {
    try {
      if (sectionId.value == null) return;

      final result = await _classFeedRepository.getSectionEducators(
        sectionId: sectionId.value!,
      );

      if (result != null && result.isNotEmpty) {
        // Get first educator (main teacher)
        final teacherDisplayName = result[0]['display_name'] ?? 'ไม่ระบุ';
        teacherName.value = teacherDisplayName;
      } else {
        teacherName.value = 'ไม่พบผู้สอนหลัก';
      }
    } catch (e) {
      debugPrint('❌ Error fetching teacher name: $e');
      teacherName.value = 'ไม่พบผู้สอนหลัก';
    }
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

  /// FETCH CLASS DETAIL FALLBACK
  Future<void> _fetchClassDetailFallback() async {
    try {
      if (sectionId.value == null) return;

      isLoading.value = true;

      final classDetail = await _classFeedRepository.getClassDetail(
        sectionId: sectionId.value!,
      );

      if (classDetail != null) {
        subjectNameTh.value = classDetail.subjectNameTh;
        effectiveClassName.value = classDetail.effectiveClassName;
      } else {
        //  Set default values
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

  /// FETCH POSTS
  Future<void> fetchPosts({bool loadMore = false, bool keepScroll = false}) async {
    if (loadMore && !hasMore.value) {
      debugPrint('⚠️ [ClassDetail] No more posts to load');
      return;
    }

    if (loadMore && isLoadingMore.value) {
      debugPrint('⚠️ [ClassDetail] Already loading more');
      return;
    }

    double? savedOffset;

    if (keepScroll && scrollController.hasClients) {
      savedOffset = scrollController.offset;
    }

    try {
      if (loadMore) {
        isLoadingMore.value = true;
        // เพิ่ม delay เล็กน้อยเพื่อให้เห็น loading indicator
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

      debugPrint('📝 [ClassDetail] Fetching posts: offset=$_offset, limit=$_limit');

      final result = await _postRepository.getPostInClass(
        sectionId: sectionId.value!,
        filterType: selectedFilter.value.apiValue,
        offset: _offset,
        limit: _limit,
      );

      debugPrint('📝 [ClassDetail] Got ${result.length} posts (hasMore: $hasMore)');
      debugPrint('📝 [ClassDetail] Current total: ${posts.length} posts');

      if (result.length < _limit) {
        hasMore.value = false;
        debugPrint('✅ [ClassDetail] No more posts to load');
      }

      if (loadMore) {
        posts.addAll(result);
        debugPrint('📝 [ClassDetail] Added ${result.length} posts, new total: ${posts.length}');
      } else {
        posts.assignAll(result);
        debugPrint('📝 [ClassDetail] Replaced with ${result.length} posts');
      }

      _offset += result.length;
      debugPrint('📝 [ClassDetail] New offset: $_offset');

    } catch (e) {
      Get.snackbar('เกิดข้อผิดพลาด', 'ไม่สามารถโหลดโพสต์ได้');
      debugPrint('❌ [ClassDetail] Error: $e');
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

  /// CHANGE FILTER
  void changeFilter(ClassPostFilter filter) {
    selectedFilter.value = filter;
    fetchPosts();
  }

  /// SELECT POST FOR AI
  void togglePostSelection(int postId) {
    if (selectedPostIdsForAI.contains(postId)) {
      selectedPostIdsForAI.remove(postId);
    } else {
      selectedPostIdsForAI.add(postId);
    }
  }

  /// GENERATE AI SUMMARY
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
      // print('❌ Error generating summary: $e');
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
