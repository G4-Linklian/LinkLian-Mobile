import 'dart:io';
import 'package:LinkLian/features/community/controllers/community_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import '../../../data/repository/community_repository.dart';
import '../../../data/repository/community_tag_repository.dart';
import '../../../data/model/community_tag_model.dart';

class CreateCommunityController extends GetxController {
  final CommunityRepository _repo;
  final CommunityTagRepository _tagRepo;

  CreateCommunityController(this._repo, this._tagRepo);

  final nameController = TextEditingController();
  final descriptionController = TextEditingController();

  final ruleInputController = TextEditingController();
  final rules = <String>[].obs;

  final tagInputController = TextEditingController();

  final isPrivate = false.obs;
  final isLoading = false.obs;

  final selectedTags = <String>[].obs;
  final tagSearchResult = <CommunityTagModel>[].obs;
  final isSearchingTags = false.obs;

  final selectedImage = Rxn<File>();
  final ImagePicker _picker = ImagePicker();

  @override
  void onClose() {
    nameController.dispose();
    descriptionController.dispose();
    ruleInputController.dispose();
    tagInputController.dispose();
    super.onClose();
  }

  Future<void> pickImage() async {
    final XFile? file = await _picker.pickImage(source: ImageSource.gallery);

    if (file != null) {
      selectedImage.value = File(file.path);
    }
  }

  void removeImage() {
    selectedImage.value = null;
  }

  void addRule(String rule) {
    final clean = rule.trim();
    if (clean.isEmpty) return;

    if (!rules.contains(clean)) {
      rules.add(clean);
    }

    ruleInputController.clear();
  }

  void removeRule(String rule) {
    rules.remove(rule);
  }

  Future<void> searchTag(String keyword) async {
    try {
      isSearchingTags.value = true;
      final result = await _tagRepo.searchTag(keyword: keyword);
      tagSearchResult.value = result;
    } finally {
      isSearchingTags.value = false;
    }
  }

  void addTag(String tag) {
    final clean = tag.trim().toLowerCase().replaceAll('#', '');

    if (clean.isEmpty) return;

    if (!selectedTags.contains(clean)) {
      selectedTags.add(clean);
    }

    tagInputController.clear();
  }

  void removeTag(String tag) {
    selectedTags.remove(tag);
  }

  Future<void> createCommunity() async {
    if (nameController.text.trim().isEmpty) {
      Get.snackbar("ผิดพลาด", "กรุณากรอกชื่อชุมชน");
      return;
    }


   try {
    isLoading.value = true; 

    await _repo.createCommunity(
      name: nameController.text.trim(),
      description: descriptionController.text.trim(),
      rules: rules,
      isPrivate: isPrivate.value,
      tags: selectedTags,
      imagePath: selectedImage.value?.path,
    );

    final communityController = Get.find<CommunityController>();
    await communityController.loadCommunities();

    resetForm();

    Get.back();
    Get.snackbar("สำเร็จ", "สร้างชุมชนเรียบร้อยแล้ว");
  } finally {
    isLoading.value = false; 
  }
}

  void resetForm() {
    nameController.clear();
    descriptionController.clear();
    ruleInputController.clear();

    rules.clear();
    selectedTags.clear();
    selectedImage.value = null;
    isPrivate.value = false;
  }
}
