import 'package:LinkLian/core/constants/colors.dart';
import 'package:flutter/material.dart';
import 'bookmark_card.dart';

enum BookmarkType { post, community }
enum SortType { all, newest, oldest }

class BookmarkSwitcher extends StatefulWidget {
  const BookmarkSwitcher({super.key});

  @override
  State<BookmarkSwitcher> createState() => _BookmarkSwitcherState();
}

class _BookmarkSwitcherState extends State<BookmarkSwitcher> {
  BookmarkType type = BookmarkType.post;
  SortType sort = SortType.all;

  @override
  Widget build(BuildContext context) {
    return Column(
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

              /// Filter Dropdown
              PopupMenuButton<SortType>(
                onSelected: (value) {
                  setState(() => sort = value);
                },
                itemBuilder: (context) => const [
                  PopupMenuItem(
                    value: SortType.all,
                    child: Text('ทั้งหมด'),
                  ),
                  PopupMenuItem(
                    value: SortType.newest,
                    child: Text('ล่าสุด'),
                  ),
                  PopupMenuItem(
                    value: SortType.oldest,
                    child: Text('เก่าสุด'),
                  ),
                ],
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.primaryPalette[100],
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _getSortLabel(sort),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Icon(Icons.filter_list, size: 16),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: AppColors.primaryPalette[400],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Expanded(child: _tabButton('โพสต์', BookmarkType.post)),
                Expanded(child: _tabButton('ชุมชน', BookmarkType.community)),
              ],
            ),
          ),
        ),

        const SizedBox(height: 14),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Column(
            children: _buildContent(),
          ),
        ),
      ],
    );
  }

  Widget _tabButton(String text, BookmarkType value) {
    final isActive = type == value;

    return GestureDetector(
      onTap: () => setState(() => type = value),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 4),
        decoration: BoxDecoration(
          color: isActive ? AppColors.primaryPalette[500] : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Text(
            text,
            style: TextStyle(
              color: isActive ? Colors.white : Colors.black87,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }

  String _getSortLabel(SortType sortType) {
    switch (sortType) {
      case SortType.all:
        return 'ทั้งหมด';
      case SortType.newest:
        return 'ล่าสุด';
      case SortType.oldest:
        return 'เก่าสุด';
    }
  }

  List<Widget> _buildContent() {
    if (type == BookmarkType.post) {
      switch (sort) {
        case SortType.all:
          return const [
            BookmarkCard(title: 'โพสต์ A'),
            BookmarkCard(title: 'โพสต์ B'),
            BookmarkCard(title: 'โพสต์ C'),
          ];
        case SortType.newest:
          return const [
            BookmarkCard(title: 'โพสต์ใหม่ล่าสุด'),
            BookmarkCard(title: 'โพสต์ก่อนหน้า'),
          ];
        case SortType.oldest:
          return const [
            BookmarkCard(title: 'โพสต์เก่าสุด'),
            BookmarkCard(title: 'โพสต์เก่ากว่า'),
          ];
      }
    } else {
      switch (sort) {
        case SortType.all:
          return const [
            BookmarkCard(title: 'ชุมชน A'),
            BookmarkCard(title: 'ชุมชน B'),
          ];
        case SortType.newest:
          return const [
            BookmarkCard(title: 'ชุมชนล่าสุด'),
            BookmarkCard(title: 'ชุมชนก่อนหน้า'),
          ];
        case SortType.oldest:
          return const [
            BookmarkCard(title: 'ชุมชนเก่าสุด'),
            BookmarkCard(title: 'ชุมชนเก่ากว่า'),
          ];
      }
    }
  }
}
