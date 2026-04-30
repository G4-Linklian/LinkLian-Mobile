import 'dart:async';

import 'package:LinkLian/core/utils/logger.dart';
import 'package:LinkLian/features/chat/presentation/pages/ai_chat_detail.page.dart';
import 'package:LinkLian/features/chat/presentation/services/ai_summary_notification_service.dart';
import 'package:LinkLian/features/auth/controller/auth_controller.dart';
import 'package:LinkLian/features/shared/repositories/ai_chat_repository.dart';
import 'package:LinkLian/core/services/socket_service.dart';
import 'package:LinkLian/features/shared/repositories/qna_repository.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get/get.dart';
import 'class_detail_filter.dart';
import '../../../shared/repositories/post_repository.dart';
import '../../../shared/repositories/class_feed_repository.dart';
import 'class_feed_controller.dart';
import '../../../shared/models/post_model.dart';
import '../../../../core/utils/online_presence_utils.dart';
import 'package:flutter/material.dart';
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

  final Rxn<dynamic> activeLive = Rxn<dynamic>();
  final hasLiveHistory = false.obs;
  final liveHistoryCount = 0.obs;

  static const int maxAISelectCount = 1;

  final schedules = <Map<String, dynamic>>[].obs;

  int _offset = 0;
  final int _limit = 10;

  final PostRepository _postRepository = PostRepository();
  final ClassFeedRepository _classFeedRepository = ClassFeedRepository();
  final QnaRepository _qnaRepository = QnaRepository();
  final SocketService _socket = SocketService();
  final ScrollController scrollController = ScrollController();
  StreamSubscription<dynamic>? _qaSubscription;
  // Timer? _activeLivePollingTimer;
  int? _joinedSectionId;

  DateTime? _lastFetchTime;
  static const _refreshThresholdSeconds = 30;
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
    appLog.info('[ClassDetail] onInit called');
  }

  @override
  void onReady() {
    super.onReady();
    appLog.info('[ClassDetail] onReady called');
    appLog.info('[ClassDetail] onReady called');

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
      appLog.error(
        '[ClassDetail] sectionId is null',
        actionPage: 'ClassDetailScreen',
      );
      return;
    }

    final isNewSection = sectionId.value != newSectionId;

    if (isNewSection) {
      selectedFilter.value = ClassPostFilter.all;
      _lastFetchTime = null;
      posts.clear();
      hasMore.value = true;
      _offset = 0;
      appLog.info(
        'New section - reset & reload',
        actionPage: 'ClassDetailScreen',
      );
    }

    sectionId.value = newSectionId;
    subjectNameTh.value = args['subjectName'] as String? ?? '';
    effectiveClassName.value =
        (args['className'] as String?) ??
        (args['sectionName'] as String?) ??
        '';

    fetchClassDetailFromFeed();
    unawaited(fetchHasLiveHistory());

    if (isNewSection) {
      fetchPosts();
    } else {
      refreshIfNeeded();
    }
    fetchActiveLive();
    unawaited(_connectSectionLiveSocket());
    // _startActiveLivePolling();
  }

  // void _startActiveLivePolling() {
  //   _activeLivePollingTimer?.cancel();
  //   // เพิ่มเป็น 60 วินาที เพื่อลดการยิง API รัวๆ (อาศัย WebSocket ช่วยอัปเดตแบบเรียลไทม์แทน)
  //   _activeLivePollingTimer = Timer.periodic(const Duration(seconds: 60), (_) {
  //     if (sectionId.value == null) return;
  //     unawaited(fetchActiveLive());
  //     unawaited(fetchHasLiveHistory());
  //   });
  // }

  Future<void> _connectSectionLiveSocket() async {
    final currentSectionId = sectionId.value;
    if (currentSectionId == null) {
      return;
    }

    final auth = Get.isRegistered<AuthController>()
        ? Get.find<AuthController>()
        : null;
    final userId = auth?.userId.value;
    if (userId == null) {
      return;
    }

    try {
      if (!_socket.isQaConnected) {
        final qaSocketUrl =
            '${dotenv.env['SOCKET_URL'] ?? 'wss://uat-socket.linklian.org/ws'}/qa';
        await _socket.connectQaLive(qaSocketUrl);
      }

      if (_joinedSectionId != currentSectionId) {
        if (_joinedSectionId != null) {
          _socket.leaveQaSectionRoom(
            userId: userId,
            sectionId: _joinedSectionId!,
          );
        }
        _socket.joinQaSectionRoom(userId: userId, sectionId: currentSectionId);
        _joinedSectionId = currentSectionId;
      }

      await _qaSubscription?.cancel();
      _qaSubscription = _socket.qaStream.listen(_handleQaSocketEvent);
    } catch (e) {
      appLog.error('[ClassDetail] QA socket connect error: $e');
    }
  }

  void _handleQaSocketEvent(dynamic event) {
    if (event is! Map) return;

    final root = Map<String, dynamic>.from(event);
    final nestedData = root['data'] is Map
        ? Map<String, dynamic>.from(root['data'] as Map)
        : null;

    final type = (root['type'] ?? nestedData?['type'])?.toString();
    if (type == null || type.isEmpty) return;

    final payloadRaw = root['payload'] ?? nestedData?['payload'] ?? root;
    final payload = payloadRaw is Map
        ? Map<String, dynamic>.from(payloadRaw)
        : <String, dynamic>{};

    final payloadSectionId = _toInt(payload['section_id']);
    final currentSectionId = sectionId.value;
    if (payloadSectionId != null &&
        currentSectionId != null &&
        payloadSectionId != currentSectionId) {
      return;
    }

    if (type == 'QA_LIVE_STARTED') {
      unawaited(fetchActiveLive());
      return;
    }

    if (type == 'QA_LIVE_ENDED') {
      activeLive.value = null;
      unawaited(fetchHasLiveHistory());
    }
  }

  int? _toInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value.trim());
    return null;
  }

  Future<void> refreshIfNeeded() async {
    if (sectionId.value == null) return;

    if (posts.isEmpty) {
      appLog.info('No posts - fetching', actionPage: 'ClassDetailScreen');
      await fetchPosts();
      return;
    }

    final lastFetch = _lastFetchTime;
    if (lastFetch == null) {
      appLog.info('Never loaded - fetching', actionPage: 'ClassDetailScreen');
      await fetchPosts();
      return;
    }

    final secondsSinceFetch = DateTime.now().difference(lastFetch).inSeconds;

    if (secondsSinceFetch >= _refreshThresholdSeconds) {
      appLog.info(
        'Data stale (${secondsSinceFetch}s) - refreshing',
        actionPage: 'ClassDetailScreen',
      );
      await fetchPosts();
      return;
    }

    appLog.info(
      'Data fresh (${secondsSinceFetch}s ago) - skip',
      actionPage: 'ClassDetailScreen',
    );
  }

  void fetchClassDetailFromFeed() {
    try {
      appLog.info('[ClassDetail] fetchClassDetailFromFeed called');

      if (sectionId.value == null) {
        appLog.info('[ClassDetail] sectionId is null, skipping fetch');
        return;
      }
      if (!Get.isRegistered<ClassFeedController>()) {
        appLog.info(
          '[ClassDetail] ClassFeedController not registered, using fallback',
        );
        _fetchClassDetailFallback();
        return;
      }

      final feedController = Get.find<ClassFeedController>();

      final classDetail = feedController.classList.firstWhereOrNull(
        (c) => c.sectionId == sectionId.value,
      );

      if (classDetail != null) {
        appLog.info('[ClassDetail] Found class detail in feed controller');
        subjectNameTh.value = classDetail.subjectNameTh;
        effectiveClassName.value = classDetail.effectiveClassName;

        _fetchTeacherName();
      } else {
        appLog.info(
          '[ClassDetail] Class detail not found in feed, using fallback',
        );
        _fetchClassDetailFallback();
      }
    } catch (e) {
      appLog.info('[ClassDetail] Error in fetchClassDetailFromFeed: $e');
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

      if (result.isNotEmpty) {
        final teacherDisplayName = result.first.fullName.isNotEmpty
            ? result.first.fullName
            : 'ไม่ระบุ';
        teacherName.value = teacherDisplayName;
        appLog.info('[ClassDetail] Teacher name set: ${teacherName.value}');
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

  Future<void> fetchPosts({
    bool loadMore = false,
    bool keepScroll = false,
  }) async {
    if (loadMore && !hasMore.value) {
      appLog.info('[ClassDetail] No more posts to load');
      return;
    }

    if (loadMore && isLoadingMore.value) {
      appLog.info('[ClassDetail] Already loading more');
      return;
    }

    if (!loadMore && isLoading.value) {
      appLog.info('[ClassDetail] Already loading');
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
          'loadMore': loadMore,
        },
        actionPage: 'ClassDetailScreen',
      );

      final result = await _postRepository.getPostInClass(
        sectionId: sectionId.value!,
        filterType: selectedFilter.value.apiValue,
        offset: _offset,
        limit: _limit,
      );

      appLog.debug(
        '[ClassDetail] fetchPosts result: ${result.length} posts',
        data: {
          'postIds': result.map((p) => p.postId).toList(),
          'isUserDeletedFlags': result.map((p) => p.isUserDeleted).toList(),
          'userSysIds': result.map((p) => p.userSysId).toList(),
        },
      );

      if (!loadMore) {
        _lastFetchTime = DateTime.now();
      }

      if (result.length < _limit) {
        hasMore.value = false;
        appLog.info('[ClassDetail] No more posts to load');
      }

      if (loadMore) {
        posts.addAll(result);
        appLog.info(
          '[ClassDetail] Added ${result.length} posts, total: ${posts.length}',
          data: {'newPosts': result.length, 'totalPosts': posts.length},
        );
      } else {
        posts.assignAll(result);
        if (result.isEmpty) {
          appLog.error(
            'Posts',
            actionPage: 'ClassDetailScreen',
            exception: 'No posts found',
          );
        } else {
          appLog.error(
            'Posts',
            actionPage: 'ClassDetailScreen',
            data: result.length,
          );
        }
      }

      final allUserIds = posts.map((post) => post.userSysId);
      OnlinePresenceUtils.subscribeOnlineStatus(
        socketService: _socket,
        userSysIds: allUserIds,
      );

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
      selectedPostIdsForAI.remove(postId);
    } else {
      if (selectedPostIdsForAI.length < maxAISelectCount) {
        selectedPostIdsForAI.add(postId);
      }
    }
  }

  bool canSelectForAI(int postContentId) {
    return selectedPostIdsForAI.contains(postContentId) ||
        selectedPostIdsForAI.length < maxAISelectCount;
  }

  void clearAISelections() {
    selectedPostIdsForAI.clear();
  }

  Future<void> generateAISummary() async {
    if (selectedPostIdsForAI.isEmpty) return;

    try {
      final repo = AIChatRepository();
      final postContentId = selectedPostIdsForAI.first;
      final selectedPost = posts.firstWhereOrNull(
        (post) => post.postContentId == postContentId,
      );
      final attachments =
          selectedPost?.attachments
              ?.map(
                (attachment) => {
                  "url": attachment.fileUrl,
                  "type": attachment.fileType,
                  "name": attachment.fileName,
                  "original_name": attachment.originalName,
                },
              )
              .toList() ??
          const <Map<String, dynamic>>[];
      final summaryFuture = repo.generateSummary(postContentId);

      AISummaryNotificationService.watchSummary(
        summaryFuture: summaryFuture,
        postContentId: postContentId,
        fallbackPostTitle: (selectedPost?.title.isNotEmpty ?? false)
            ? selectedPost!.title
            : "AI Chat",
        content: selectedPost?.content ?? "",
        attachments: List<Map<String, dynamic>>.from(attachments),
      );

      selectedPostIdsForAI.clear();

      Get.to(
        () => AIChatDetailPage(
          title: (selectedPost?.title.isNotEmpty ?? false)
              ? selectedPost!.title
              : "AI Chat",
          documentTitle: 'AI Chat',
          aiChatId: 0,
          summary: "",
          content: selectedPost?.content ?? "",
          attachments: attachments,
          postContentId: postContentId,
          initialSummaryFuture: summaryFuture,
        ),
      );
    } catch (e) {
      //Get.snackbar("Error", "ไม่สามารถสร้าง AI Chat ได้");
    }
  }

  Future<void> fetchActiveLive() async {
    try {
      if (sectionId.value == null) {
        activeLive.value = null;
        return;
      }

      final res = await _qnaRepository.getActiveLive(
        sectionId: sectionId.value!,
      );

      activeLive.value = res?.toJson();
    } catch (e) {
      activeLive.value = null;
    }
  }

  Future<void> fetchHasLiveHistory() async {
    try {
      if (sectionId.value == null) {
        hasLiveHistory.value = false;
        liveHistoryCount.value = 0;
        return;
      }

      final history = await _qnaRepository.getLiveHistory(
        sectionId: sectionId.value!,
      );
      hasLiveHistory.value = history.isNotEmpty;
      liveHistoryCount.value = history.length;
    } catch (e) {
      hasLiveHistory.value = false;
      liveHistoryCount.value = 0;
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
    final auth = Get.isRegistered<AuthController>()
        ? Get.find<AuthController>()
        : null;
    final userId = auth?.userId.value;
    final joinedSectionId = _joinedSectionId;
    if (userId != null && joinedSectionId != null) {
      _socket.leaveQaSectionRoom(userId: userId, sectionId: joinedSectionId);
    }
    _qaSubscription?.cancel();
    _joinedSectionId = null;
    scrollController.dispose();
    selectedPostIdsForAI.clear();
    super.onClose();
  }
}
