import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/create_community_controller.dart';

class TagSelectionPopup extends StatefulWidget {
  final CreateCommunityController controller;

  const TagSelectionPopup({super.key, required this.controller});

  @override
  State<TagSelectionPopup> createState() => _TagSelectionPopupState();
}

class _TagSelectionPopupState extends State<TagSelectionPopup> {
  final searchController = TextEditingController();

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.controller.searchTag('');
    });
  }

  void _addTagAndClear(String value) {
    final clean = value.trim().replaceAll('#', '');

    if (clean.isEmpty) return;

    widget.controller.addTag(clean);
    searchController.clear();

    widget.controller.searchTag('');
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Container(
        padding: const EdgeInsets.all(20),
        height: 500,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "เลือกแท็ก",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Get.back(),
                ),
              ],
            ),

            const SizedBox(height: 12),

            Obx(
              () => widget.controller.selectedTags.isNotEmpty
                  ? SizedBox(
                      height: 40,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: widget.controller.selectedTags.length,
                        itemBuilder: (context, index) {
                          final tag = widget.controller.selectedTags[index];

                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: Chip(
                              label: Text("#$tag"),
                              deleteIcon: const Icon(Icons.close, size: 16),
                              onDeleted: () => widget.controller.removeTag(tag),
                              backgroundColor: const Color(0xFFFFE4B5),
                            ),
                          );
                        },
                      ),
                    )
                  : const SizedBox.shrink(),
            ),

            const SizedBox(height: 12),

            TextField(
              controller: searchController,
              autofocus: true,
              onChanged: (value) {
                final clean = value.replaceAll('#', '').trim();

                widget.controller.searchTag(clean);
              },

              onSubmitted: (value) {
                _addTagAndClear(value);
              },
              decoration: InputDecoration(
                hintText: "พิมพ์แล้วกด Enter เพื่อเพิ่มแท็ก",
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),

            const SizedBox(height: 16),

            Expanded(
              child: Obx(() {
                if (widget.controller.isSearchingTags.value) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (widget.controller.tagSearchResult.isEmpty) {
                  return const Center(child: Text("ไม่พบแท็ก"));
                }

                return ListView.builder(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  itemCount: widget.controller.tagSearchResult.length,
                  itemBuilder: (context, index) {
                    final tag = widget.controller.tagSearchResult[index];

                    final isSelected = widget.controller.selectedTags.contains(
                      tag.tagName.toLowerCase(),
                    );

                    return ListTile(
                      title: Text("#${tag.tagName}"),
                      trailing: isSelected
                          ? const Icon(Icons.check, color: Colors.blue)
                          : null,
                      onTap: () {
                        widget.controller.addTag(tag.tagName);
                      },
                    );
                  },
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}
