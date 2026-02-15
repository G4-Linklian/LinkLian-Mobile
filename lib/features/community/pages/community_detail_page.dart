import 'package:LinkLian/core/constants/linklian-icon.dart';
import 'package:LinkLian/core/utils/dialog_helper.dart';
import 'package:LinkLian/features/auth/controller/auth_controller.dart';
import 'package:LinkLian/features/community/widgets/community_card_post.dart';
import 'package:LinkLian/features/community/widgets/community_info_popup.dart';
import 'package:LinkLian/features/community/widgets/community_post_filter_widget.dart';
import 'package:LinkLian/features/layout/controllers/navigation_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/sizes.dart';
import '../../../config/app_routes.dart';
import '../controllers/community_detail_controller.dart';
import '../../../data/model/community_model.dart';

class CommunityDetailPage extends StatefulWidget {
  const CommunityDetailPage({super.key});

  @override
  State<CommunityDetailPage> createState() => _CommunityDetailPageState();
}

class _CommunityDetailPageState extends State<CommunityDetailPage> {
  late CommunityDetailController controller;
  bool _showCollapsedBar = false;

  @override
  void initState() {
    super.initState();
    controller = Get.find<CommunityDetailController>();
    controller.scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    final shouldShow = controller.scrollController.offset > 50;
    if (_showCollapsedBar != shouldShow) {
      setState(() {
        _showCollapsedBar = shouldShow;
      });
    }
  }

  @override
  void dispose() {
    controller.scrollController.removeListener(_onScroll);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final statusBarHeight = MediaQuery.of(context).padding.top;
    const bannerHeight = 90.0;

    return Scaffold(
      backgroundColor: AppColors.white,
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        final community = controller.community.value;
        if (community == null) {
          return const Center(child: Text("ไม่พบข้อมูลชุมชน"));
        }

        return Stack(
          children: [
            CustomScrollView(
              controller: controller.scrollController,
              physics: controller.canViewContent()
                  ? const AlwaysScrollableScrollPhysics()
                  : const NeverScrollableScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: bannerHeight + statusBarHeight,
                    child: Opacity(opacity: 0.6),
                  ),
                ),

                /// ================= HEADER INFO =================
                SliverToBoxAdapter(
                  child: _CommunityHeaderContent(controller: controller),
                ),

                if (controller.shouldShowFilter && !_showCollapsedBar)
                  SliverToBoxAdapter(
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 150),
                      opacity: _showCollapsedBar ? 0.0 : 1.0,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        height: _showCollapsedBar ? 0 : null,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              CommunityFilterDropdown(
                                selected: controller.selectedFilter.value,
                                onChanged: controller.changeFilter,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                if (!controller.canViewContent())
                  SliverToBoxAdapter(
                    child: _PrivateLockedView(
                      isPending:
                          controller.community.value?.membershipStatus ==
                          'pending',
                      isClosed: controller.isCommunityClosed,
                    ),
                  )
                else if (controller.posts.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.article_outlined,
                            size: 80,
                            color: AppColors.primaryPalette[700],
                          ),
                          const SizedBox(height: 20),
                          Text(
                            "ยังไม่มีโพสต์ในชุมชนนี้",
                            style: TextStyle(
                              color: AppColors.primaryPalette[700],
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSizes.md,
                    ),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate((context, index) {
                        final post = controller.posts[index];
                        return CardPostCommunity(post: post);
                      }, childCount: controller.posts.length),
                    ),
                  ),
              ],
            ),

            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Column(
                children: [
                  Container(
                    height: bannerHeight + statusBarHeight,
                    decoration: const BoxDecoration(color: Colors.white),
                    child: Stack(
                      children: [
                        /// Banner
                        Positioned.fill(
                          child: Image.network(
                            community.imageBanner,
                            fit: BoxFit.cover,
                            alignment: Alignment.center,
                          ),
                        ),

                        Positioned(
                          left: 0,
                          right: 0,
                          bottom: -1,
                          height: 30,
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  const Color.fromARGB(0, 255, 255, 255),
                                  AppColors.primaryPalette[100]!.withOpacity(
                                    0.2,
                                  ),
                                  AppColors.primaryPalette[100]!.withOpacity(
                                    0.3,
                                  ),
                                  AppColors.primaryPalette[100]!.withOpacity(
                                    0.4,
                                  ),
                                  AppColors.primaryPalette[100]!.withOpacity(
                                    0.5,
                                  ),
                                  AppColors.primaryPalette[100]!,
                                ],
                              ),
                            ),
                          ),
                        ),

                        Positioned(
                          top: statusBarHeight,
                          left: 0,
                          right: 0,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: Row(
                              children: [
                                Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    shape: BoxShape.circle,
                                  ),
                                  child: IconButton(
                                    icon: Icon(
                                      LinkLianIcon.back,
                                      color: AppColors.primaryPalette[700]!,
                                    ),
                                    onPressed: () {
                                      Get.find<NavigationController>()
                                          .hideCommunityDetail();
                                    },
                                  ),
                                ),
                                const Spacer(),

                                Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    shape: BoxShape.circle,
                                  ),
                                  child: IconButton(
                                    icon: Icon(
                                      Icons.search,
                                      color: AppColors.primaryPalette[700]!,
                                      size: 30,
                                    ),
                                    onPressed: controller.canInteract()
                                        ? () {
                                            Get.toNamed(
                                              AppRoutes.communitySearch,
                                              arguments: {
                                                'communityId':
                                                    controller.communityId,
                                                'communityName':
                                                    community.communityName,
                                              },
                                            );
                                          }
                                        : null,
                                  ),
                                ),

                                const SizedBox(width: 8),

                                Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    shape: BoxShape.circle,
                                  ),
                                  child: IconButton(
                                    icon: Icon(
                                      LinkLianIcon.add,
                                      color: AppColors.primaryPalette[500],
                                      size: 30,
                                    ),

                                    onPressed: controller.canInteract()
                                        ? () async {
                                            final result = await Get.toNamed(
                                              AppRoutes.createPostCommunity,
                                              arguments: {
                                                'community_id':
                                                    controller.communityId,
                                                'userId': controller
                                                    .currentUserId
                                                    .value,
                                              },
                                            );
                                            if (result == true) {
                                              controller.loadDetail();
                                              DialogHelper.showNotification(
                                                title: 'โพสต์สำเร็จ',
                                                message:
                                                    'ระบบได้บันทึกโพสต์ของคุณเรียบร้อยแล้ว',
                                                type: NotificationType.success,
                                              );
                                            }
                                          }
                                        : null,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    height: _showCollapsedBar ? 150 : 0,
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 200),
                      opacity: _showCollapsedBar ? 1.0 : 0.0,
                      child: SingleChildScrollView(
                        physics: const NeverScrollableScrollPhysics(),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.primaryPalette[100],
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      community.communityName,
                                      style: const TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.w800,
                                        color: Colors.black,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 6),

                                  if (!community.isMember)
                                    ElevatedButton(
                                      onPressed: community.isPending
                                          ? null
                                          : () {
                                              controller.joinCommunity();
                                            },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: community.isPending
                                            ? Colors.grey.shade300
                                            : AppColors.buttonPalette[100],
                                        foregroundColor: community.isPending
                                            ? Colors.grey.shade600
                                            : AppColors.buttonPalette[600],
                                        side: BorderSide(
                                          color: community.isPending
                                              ? Colors.grey.shade400
                                              : AppColors.buttonPalette[600]!,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 14,
                                          vertical: 6,
                                        ),
                                        minimumSize: Size.zero,
                                        tapTargetSize:
                                            MaterialTapTargetSize.shrinkWrap,
                                      ),
                                      child: Text(
                                        community.isPending
                                            ? "รอยืนยัน"
                                            : community.isPrivate
                                            ? "ขอเข้าร่วม"
                                            : "เข้าร่วมกลุ่ม",
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),

                                  const SizedBox(width: 3),
                                  IconButton(
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                    icon: Icon(
                                      Icons.info_outline,
                                      color: AppColors.primaryPalette[600],
                                      size: 24,
                                    ),
                                    onPressed: () {
                                      showModalBottomSheet(
                                        context: context,
                                        isScrollControlled: true,
                                        backgroundColor: Colors.transparent,
                                        builder: (_) => CommunityInfoPopup(
                                          communityId: controller.communityId,
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),

                            if (controller.shouldShowFilter)
                              TweenAnimationBuilder<double>(
                                duration: const Duration(milliseconds: 250),
                                tween: Tween<double>(
                                  begin: 0.0,
                                  end: _showCollapsedBar ? 1.0 : 0.0,
                                ),
                                curve: const Interval(
                                  0.3,
                                  1.0,
                                  curve: Curves.easeInOut,
                                ),
                                builder: (context, value, child) {
                                  return SizedBox(
                                    height: 60 * value,
                                    child: Opacity(
                                      opacity: value,
                                      child: value > 0.1
                                          ? child
                                          : const SizedBox.shrink(),
                                    ),
                                  );
                                },
                                child: Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 10,
                                  ),
                                  decoration: const BoxDecoration(
                                    color: Colors.white,
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      CommunityFilterDropdown(
                                        selected:
                                            controller.selectedFilter.value,
                                        onChanged: controller.changeFilter,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      }),
    );
  }
}

class _CommunityHeaderContent extends StatelessWidget {
  final CommunityDetailController controller;

  const _CommunityHeaderContent({required this.controller});

  @override
  Widget build(BuildContext context) {
    final CommunityModel community = controller.community.value!;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.primaryPalette[100]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  community.communityName,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: Colors.black,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),

              if (!community.isMember && !controller.isCommunityClosed)
                ElevatedButton(
                  onPressed: community.isPending
                      ? null
                      : () {
                          controller.joinCommunity();
                        },

                  style: ElevatedButton.styleFrom(
                    backgroundColor: community.isPending
                        ? Colors.grey.shade300
                        : AppColors.buttonPalette[100],

                    foregroundColor: community.isPending
                        ? Colors.grey.shade600
                        : AppColors.buttonPalette[600],

                    side: BorderSide(
                      color: community.isPending
                          ? Colors.grey.shade400
                          : AppColors.buttonPalette[600]!,
                    ),

                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 6,
                    ),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),

                  child: Text(
                    community.isPending
                        ? "รอยืนยัน"
                        : community.isPrivate
                        ? "ขอเข้าร่วม"
                        : "เข้าร่วมกลุ่ม",
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),

              if (controller.isCommunityClosed)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    border: Border.all(color: Colors.grey.shade400),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    "ชุมชนถูกปิด",
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ),

              const SizedBox(width: 4),

              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: Icon(
                  Icons.info_outline,
                  color: AppColors.primaryPalette[600],
                  size: 24,
                ),
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    builder: (_) =>
                        CommunityInfoPopup(communityId: controller.communityId),
                  );
                },
              ),
            ],
          ),

          const SizedBox(height: 4),

          /// Tag
          if (community.tags.isNotEmpty)
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: community.tags.map((tag) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primaryPalette[300],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    "#$tag",
                    style: const TextStyle(
                      fontSize: 10,
                      color: Colors.black,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                );
              }).toList(),
            ),

          const SizedBox(height: 10),

          Text(
            "สมาชิก ${community.memberCount} คน",
            style: const TextStyle(
              fontSize: 15,
              color: Colors.black,
              fontWeight: FontWeight.w600,
            ),
          ),

          const SizedBox(height: 6),

          Text(
            community.description ?? "",
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 14, color: Colors.black87),
          ),
        ],
      ),
    );
  }
}

class _PrivateLockedView extends StatelessWidget {
  final bool isPending;
  final bool isClosed;

  const _PrivateLockedView({required this.isPending, required this.isClosed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.6,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.lock, size: 80, color: Colors.blue.shade400),
            const SizedBox(height: 20),
            Text(
              isClosed
                  ? "ชุมชนถูกปิด"
                  : isPending
                  ? "คำขอเข้าร่วมกำลังรอยืนยัน"
                  : "นี่คือกลุ่มส่วนบุคคล",
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(
              isClosed
                  ? "กลุ่มนี้ถูกปิดโดยเจ้าของ คุณสามารถดูข้อมูลรายละเอียดได้เท่านั้น"
                  : isPending
                  ? "กรุณารอเจ้าของกลุ่มอนุมัติ"
                  : "เข้าร่วมกลุ่มเพื่อดูหรือมีส่วนร่วมในการสนทนา",
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 15, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
