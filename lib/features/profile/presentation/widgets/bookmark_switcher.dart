import 'package:LinkLian/core/constants/linklian-icon.dart';
import 'package:LinkLian/features/community/presentation/widgets/community_card_post.dart';
import 'package:LinkLian/features/shared/presentations/bookmark_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:LinkLian/core/constants/colors.dart';
import 'bookmark_card.dart';

class BookmarkSwitcher extends GetView<BookmarkController> {
  const BookmarkSwitcher({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'บุ๊กมาร์ก',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Obx(() {
                return PopupMenuButton<SortType>(
                  onSelected: controller.changeSort,
                  itemBuilder: (context) => SortType.values.map((sort) {
                    return PopupMenuItem<SortType>(
                      value: sort,
                      child: SizedBox(
                        width: 85,
                        child: Center(
                          child: Text(
                            _getSortLabel(sort),
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: AppColors.primaryPalette[900],
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),

                  offset: const Offset(0, 45),
                  elevation: 8,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  color: AppColors.primaryPalette[300],

                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primaryPalette[100],
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _getSortLabel(controller.sortType.value),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: AppColors.primaryPalette[900],
                          ),
                        ),
                        const SizedBox(width: 6),
                        Icon(
                          LinkLianIcon.filterpost,
                          size: 18,
                          color: AppColors.primaryPalette[700],
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ],
          ),
        ),

        const SizedBox(height: 16),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: Obx(() {
            return Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppColors.primaryPalette[400],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _tabButton(
                      text: 'โพสต์',
                      value: BookmarkType.post,
                      active: controller.type.value,
                      onTap: controller.changeType,
                    ),
                  ),
                  Expanded(
                    child: _tabButton(
                      text: 'ชุมชน',
                      value: BookmarkType.community,
                      active: controller.type.value,
                      onTap: controller.changeType,
                    ),
                  ),
                ],
              ),
            );
          }),
        ),

        const SizedBox(height: 14),

        Obx(() {
          if (controller.type.value == BookmarkType.community) {
            if (controller.loading.value) {
              return const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator()),
              );
            }

            if (controller.communityBookmarks.isEmpty) {
              return const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: Text('ยังไม่มีบุ๊กมาร์ก')),
              );
            }

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Column(
                children: controller.communityBookmarks
                    .map((post) => CardPostCommunity(post: post,showMoreButton: false,))
                    .toList(),
              ),
            );
          }
          if (controller.loading.value) {
            return const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator()),
            );
          }

          if (controller.bookmarks.isEmpty) {
            return const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: Text('ยังไม่มีบุ๊กมาร์ก')),
            );
          }

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Column(
              children: controller.bookmarks
                  .map(
                    (item) => BookmarkCard(
                      item: item,
                      onRemove: () {
                        controller.removeBookmark(item.postId);
                      },
                    ),
                  )
                  .toList(),
            ),
          );
        }),
      ],
    );
  }

  String _getSortLabel(SortType sort) {
    switch (sort) {
      case SortType.all:
        return 'ทั้งหมด';
      case SortType.newest:
        return 'ล่าสุด';
      case SortType.oldest:
        return 'เก่าสุด';
    }
  }

  Widget _tabButton({
    required String text,
    required BookmarkType value,
    required BookmarkType active,
    required Function(BookmarkType) onTap,
  }) {
    final isActive = value == active;

    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () => onTap(value),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? AppColors.primaryPalette[500] : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }
}
