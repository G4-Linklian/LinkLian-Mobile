import 'dart:async';

import 'package:LinkLian/core/constants/colors.dart';
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
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.controller.searchTag('');
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    searchController.dispose();
    super.dispose();
  }

  void _addNewTag(String tagName) {
    final cleanTag = tagName.replaceAll('#', '').trim().toLowerCase();
    if (cleanTag.isNotEmpty && !widget.controller.selectedTags.contains(cleanTag)) {
      widget.controller.addTag(cleanTag);
      searchController.clear();
      widget.controller.searchTag(''); // รีเซ็ตการค้นหา
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        padding: const EdgeInsets.all(20),
        height: 470,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "เลือกแท็ก",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            Obx(
              () => widget.controller.selectedTags.isNotEmpty
                  ? SizedBox(
                      height: 32,
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
                              backgroundColor: AppColors.primaryPalette[200],
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: BorderSide(
                                  color: AppColors.primaryPalette[400]!,
                                  width: 1,
                                ),
                              ),
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
                if (_debounce?.isActive ?? false) {
                  _debounce!.cancel();
                }
                _debounce = Timer(const Duration(milliseconds: 500), () {
                  widget.controller.searchTag(clean);
                });
              },
              onSubmitted: (value) {
                final clean = value.replaceAll('#', '').trim().toLowerCase();
                
                // เช็คว่า tag นี้มีใน database หรือไม่
                final existsInDatabase = widget.controller.tagSearchResult
                    .any((tag) => tag.tagName.toLowerCase() == clean);
                
                // ถ้าไม่มีใน database และยังไม่ได้เลือก ให้เพิ่ม tag ใหม่
                if (clean.isNotEmpty && 
                    !existsInDatabase && 
                    !widget.controller.selectedTags.contains(clean)) {
                  _addNewTag(clean);
                } else if (existsInDatabase) {
                  // ถ้ามีใน database ให้เพิ่มจากรายการ
                  final tag = widget.controller.tagSearchResult
                      .firstWhere((t) => t.tagName.toLowerCase() == clean);
                  widget.controller.addTag(tag.tagName);
                  searchController.clear();
                  widget.controller.searchTag('');
                }
              },
              decoration: InputDecoration(
                hintText: "ค้นหาแท็ก...",
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.grey.shade100,
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 8,
                  horizontal: 8,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide(
                    color: AppColors.primaryPalette[300]!,
                    width: 1,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: Obx(() {
                if (widget.controller.isSearchingTags.value) {
                  return const Center(child: CircularProgressIndicator());
                }

                final filteredList = widget.controller.tagSearchResult
                    .where(
                      (tag) => !widget.controller.selectedTags.contains(
                        tag.tagName.toLowerCase(),
                      ),
                    )
                    .toList();

                final searchText = searchController.text.replaceAll('#', '').trim();
                final hasSearchText = searchText.isNotEmpty;
                final noResults = filteredList.isEmpty && hasSearchText;

                if (noResults) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.add_circle_outline,
                          size: 48,
                          color: AppColors.primaryPalette[400],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          "ไม่พบแท็ก \"$searchText\"",
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "กด Enter เพื่อเพิ่มแท็กใหม่",
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.primaryPalette[600],
                          ),
                        ),
                      ],
                    ),
                  );
                }

                if (filteredList.isEmpty) {
                  return const Center(child: Text("ไม่พบแท็ก"));
                }

                return Scrollbar(
                  thickness: 4,
                  radius: const Radius.circular(24),
                  thumbVisibility: true,
                  child: ListView.builder(
                    itemCount: filteredList.length,
                    itemBuilder: (context, index) {
                      final tag = filteredList[index];
                      return ListTile(
                        title: Text("#${tag.tagName}"),
                        onTap: () {
                          widget.controller.addTag(tag.tagName);
                        },
                      );
                    },
                  ),
                );
              }),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Get.back();
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(
                  "บันทึก",
                  style: TextStyle(
                    fontSize: 16,
                    color: AppColors.primaryPalette[700]!,
                  ),
                ),
              ),
            ),
            const Padding(padding: EdgeInsets.all(8)),
          ],
        ),
      ),
    );
  }
}