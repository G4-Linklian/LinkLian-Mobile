import 'package:LinkLian/core/constants/colors.dart';
import 'package:LinkLian/data/model/bookmark_model.dart';
import 'package:flutter/material.dart';

class BookmarkCard extends StatelessWidget {
  final BookmarkModel item;
  final VoidCallback onRemove;

  const BookmarkCard({
    super.key,
    required this.item,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// PDF Icon
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.picture_as_pdf,
              color: Colors.red,
            ),
          ),

          const SizedBox(width: 12),

          /// Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),

                Text(
                  item.content,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12),
                ),

                const SizedBox(height: 6),

                Text(
                  '${item.subjectName ?? '-'}',
                  style: const TextStyle(fontSize: 10),
                ),

                Text(
                  item.educatorName != null
                      ? 'ผู้สอน ${item.educatorName}'
                      : 'ไม่ระบุผู้สอน',
                  style: const TextStyle(fontSize: 10),
                ),
              ],
            ),
          ),

          /// Bookmark Icon (remove)
          IconButton(
            icon: const Icon(Icons.bookmark, color: Colors.orange),
            onPressed: onRemove,
          ),
        ],
      ),
    );
  }
}
