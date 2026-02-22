import 'package:LinkLian/core/constants/colors.dart';
import 'package:LinkLian/data/repository/community_member_repository.dart';
import 'package:LinkLian/data/repository/community_post_repository.dart';
import 'package:LinkLian/features/layout/controllers/navigation_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../data/model/community_model.dart';
import '../../../data/model/community_post_model.dart';
import '../../../data/repository/community_repository.dart';

enum CommunityPostFilter {
  newest('โพสต์ใหม่สุด', 'newest'),
  oldest('โพสต์เก่าสุด', 'oldest');

  final String label;
  final String apiValue;

  const CommunityPostFilter(this.label, this.apiValue);
}

class CommunityDetailController extends GetxController {
  final CommunityRepository _communityRepo;
  final CommunityPostRepository _postRepo;

  final community = Rxn<CommunityModel>();
  final posts = <CommunityPostModel>[].obs;
  final RxnInt currentUserId = RxnInt();
  final CommunityMemberRepository _memberRepo;

  CommunityDetailController(
    this._communityRepo,
    this._postRepo,
    this._memberRepo,
  );

  final isLoading = false.obs;
  final isLoadingMore = false.obs;
  final isCollapsed = false.obs;

  final selectedFilter = CommunityPostFilter.newest.obs;

  final scrollController = ScrollController();

  late int communityId;

  @override
  void onInit() {
    super.onInit();

    final nav = Get.find<NavigationController>();

    ever(nav.communityDetailArgs, (args) {
      if (args == null) return;
      if (args['communityId'] == null) return;

      communityId = args['communityId'] as int;
      loadDetail();
    });

    scrollController.addListener(_onScroll);
  }

  void initFromOutside(int id) async {
    communityId = id;
    await loadDetail();
  }

  void _onScroll() {
    if (scrollController.position.pixels >=
        scrollController.position.maxScrollExtent - 200) {
      loadMorePosts();
    }
  }

  Future<void> loadDetail() async {
    isLoading.value = true;

    try {
      final detail = await _communityRepo.getCommunityDetail(communityId);

      if (detail != null) {
        community.value = detail;
        currentUserId.value = detail.currentUserId ?? 0;
      }

      if (canViewContent()) {
        final feed = await _postRepo.getCommunityFeed(
          communityId: communityId,
          sort: selectedFilter.value.apiValue,
        );

        posts.assignAll(feed);
      } else {
        posts.clear();
      }
    } catch (e) {
      posts.clear();
    }

    isLoading.value = false;
  }

  Future<void> changeFilter(CommunityPostFilter filter) async {
    if (selectedFilter.value == filter) return;

    selectedFilter.value = filter;

    isLoading.value = true;
    posts.clear();

    scrollController.jumpTo(0);

    final feed = await _postRepo.getCommunityFeed(
      communityId: communityId,
      sort: filter.apiValue,
    );

    posts.assignAll(feed);

    isLoading.value = false;
  }

  Future<void> loadMorePosts() async {
    if (isLoadingMore.value) return;

    isLoadingMore.value = true;

    await Future.delayed(const Duration(seconds: 1));

    isLoadingMore.value = false;
  }

  bool canViewContent() {
    final c = community.value;
    if (c == null) return false;

    if (c.status == 'inactive') {
      if (!c.isPrivate) return true;
      return c.membershipStatus == 'active';
    }

    if (!c.isPrivate) return true;

    return c.membershipStatus == 'active';
  }

  bool canInteract() {
    final c = community.value;
    if (c == null) return false;

    if (c.status == 'inactive') return false;

    if (!c.isPrivate) return true;

    return c.membershipStatus == 'active';
  }

  bool get isCommunityClosed {
    final c = community.value;
    if (c == null) return false;
    return c.status == 'inactive';
  }

  bool get shouldShowFilter {
    return canViewContent() && posts.isNotEmpty && !isCommunityClosed;
  }

  @override
  void onClose() {
    scrollController.dispose();
    super.onClose();
  }

  Future<void> joinCommunity() async {
    try {
      await _memberRepo.join(communityId);

      await loadDetail();
    } catch (e) {
      Get.snackbar(
        "ผิดพลาด",
        "ไม่สามารถเข้าร่วมกลุ่มได้",
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  Future<void> leaveCommunity() async {
    try {
      await _memberRepo.leave(communityId);

      await loadDetail();
    } catch (e) {
      Get.snackbar(
        "ผิดพลาด",
        "ไม่สามารถออกจากกลุ่มได้",
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  void confirmLeaveCommunity(String communityName) {
    Get.bottomSheet(
      Container(
        decoration: BoxDecoration(
          color: AppColors.primaryPalette[100],
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 24),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.primaryPalette[400],
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 35),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "คุณแน่ใจหรือไม่ว่าต้องการออกจากกลุ่ม\n$communityName",
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),

                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () async {
                            Get.back();
                            await leaveCommunity();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.dangerPalette[500],
                            foregroundColor: Colors.white,
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                          ),
                          child: const Text(
                            "ออกจากกลุ่ม",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Get.back(),
                          style: OutlinedButton.styleFrom(
                            backgroundColor: Colors.grey.shade200,
                            foregroundColor: Colors.grey.shade600,
                            side: BorderSide(color: Colors.grey.shade400),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                          ),
                          child: const Text(
                            "ยกเลิก",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
      isScrollControlled: true,
    );
  }
}
