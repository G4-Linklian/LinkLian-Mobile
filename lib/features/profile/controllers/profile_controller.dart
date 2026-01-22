import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../data/model/profile_model.dart';
import '../../../data/repository/profile_repository.dart';
import '../../../data/repository/teaching_schedule_repository.dart';
import '../../auth/controller/auth_controller.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../../../data/model/teaching_schedule_model.dart';

class ProfileController extends GetxController {
  final ProfileRepository repo;
  final TeachingScheduleRepository scheduleRepo;

  ProfileController(this.repo, this.scheduleRepo);

  final profile = Rxn<ProfileModel>();
  final loading = false.obs;
  final saving = false.obs;
  final ImagePicker _picker = ImagePicker();
  final teachingSchedules = <TeachingScheduleModel>[].obs;
  final loadingSchedule = false.obs;

  late TextEditingController firstNameCtrl;
  late TextEditingController lastNameCtrl;
  late TextEditingController phoneCtrl;

  bool get isStudent => profile.value?.isStudent ?? false;
  bool get isTeacher => profile.value?.isTeacher ?? false;

  // get changeAvatar => null;

  @override
  void onInit() {
    super.onInit();
    loadAll();
  }

  Future<void> loadAll() async {
    await loadProfile();
    await loadTeachingSchedule();
  }

  Future<void> loadProfile() async {
    try {
      loading.value = true;
      final auth = Get.find<AuthController>();
      final userId = auth.userId.value;
      if (userId == null) return;

      final data = await repo.getProfile(userId);
      profile.value = data;

      firstNameCtrl = TextEditingController(text: data.firstName);
      lastNameCtrl = TextEditingController(text: data.lastName);
      phoneCtrl = TextEditingController(text: data.phone ?? '');
      if (data.isTeacher) {
        await loadTeachingSchedule();
      }
    } finally {
      loading.value = false;
    }
  }

  Future<void> loadTeachingSchedule() async {
    if (!isTeacher) return;

    final auth = Get.find<AuthController>();
    final userId = auth.userId.value;
    if (userId == null) return;

    try {
      loadingSchedule.value = true;
      teachingSchedules.value = await scheduleRepo.getByEducator(userId);
    } finally {
      loadingSchedule.value = false;
    }
  }

  Future<void> updateProfile({
    required String firstName,
    required String lastName,
    String? phone,
  }) async {
    if (firstName.trim().isEmpty || lastName.trim().isEmpty) {
      throw Exception('กรุณาใส่ชื่อและนามสกุล');
    }

    if (phone != null &&
        phone.isNotEmpty &&
        !RegExp(r'^[0-9]{10}$').hasMatch(phone)) {
      throw Exception('กรุณากรอกเบอร์โทรให้ถูกต้อง');
    }

    final auth = Get.find<AuthController>();
    final userId = auth.userId.value;
    if (userId == null) return;

    try {
      saving.value = true;

      await repo.updateProfile(
        userId,
        firstName: firstName,
        lastName: lastName,
        phone: phone,
        profilePic: profile.value?.profilePic,
      );

      //reload profile
      await loadProfile();
    } finally {
      saving.value = false;
    }
  }

  @override
  void onClose() {
    firstNameCtrl.dispose();
    lastNameCtrl.dispose();
    phoneCtrl.dispose();
    super.onClose();
  }

  Future<void> changeAvatar() async {
    final auth = Get.find<AuthController>();
    final userId = auth.userId.value;
    if (userId == null) return;

    final XFile? picked = await _picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;

    try {
      saving.value = true;

      final fileUrl = await repo.uploadAvatar(userId, File(picked.path));

      await repo.updateProfile(
        userId,
        firstName: profile.value!.firstName,
        lastName: profile.value!.lastName,
        phone: profile.value!.phone,
        profilePic: fileUrl,
      );

      await loadProfile();
    } finally {
      saving.value = false;
    }
  }

  Future<void> pickImageFromGallery() async {
    await changeAvatar();
  }

  Future<void> pickImageFromCamera() async {
    final auth = Get.find<AuthController>();
    final userId = auth.userId.value;
    if (userId == null) return;

    final XFile? picked = await _picker.pickImage(source: ImageSource.camera);
    if (picked == null) return;

    try {
      saving.value = true;

      final fileUrl = await repo.uploadAvatar(userId, File(picked.path));
      profile.value = profile.value!.copyWith(profilePic: fileUrl);
    } finally {
      saving.value = false;
    }
  }

  Future<void> deleteAvatar() async {
    final auth = Get.find<AuthController>();
    final userId = auth.userId.value;
    if (userId == null) return;

    final currentProfile = profile.value;
    if (currentProfile == null) return;

    final currentPic = currentProfile.profilePic;
    if (currentPic == null || currentPic.isEmpty) return;

    try {
      saving.value = true;

      debugPrint('🗑️ Deleting avatar...');

      await repo.updateProfile(
        userId,
        firstName: currentProfile.firstName,
        lastName: currentProfile.lastName,
        middleName: currentProfile.middleName,
        phone: currentProfile.phone,
        clearProfilePic: true,
      );

      imageCache.clear();
      imageCache.clearLiveImages();

      await loadProfile();
    } finally {
      saving.value = false;
    }
  }

  void restoreOriginalProfilePic(String? originalPic) {
    final currentProfile = profile.value;
    if (currentProfile == null) return;

    if (originalPic == null) {
      profile.value = currentProfile.copyWith(clearProfilePic: true);
      debugPrint('AFTER DELETE avatar = ${profile.value?.profilePic}');
    } else {
      profile.value = currentProfile.copyWith(profilePic: originalPic);
    }
  }
}
