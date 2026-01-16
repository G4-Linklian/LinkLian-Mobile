import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../data/model/profile_model.dart';
import '../../../data/repository/profile_repository.dart';
import '../../auth/controller/auth_controller.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';


class ProfileController extends GetxController {
  final ProfileRepository repo;
  ProfileController(this.repo);

  final profile = Rxn<ProfileModel>();
  final loading = false.obs;
  final saving = false.obs; 
  final ImagePicker _picker = ImagePicker();

  late TextEditingController firstNameCtrl;
  late TextEditingController lastNameCtrl;
  late TextEditingController phoneCtrl;

  bool get isStudent => profile.value?.isStudent ?? false;
  bool get isTeacher => profile.value?.isTeacher ?? false;

  // get changeAvatar => null;

  @override
  void onInit() {
    super.onInit();
    loadProfile();
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
    } finally {
      loading.value = false;
    }
  }

  Future<void> updateProfile({required String firstName, required String lastName, String? phone}) async {
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
      );

      //reload profile
      await loadProfile();

      Get.snackbar(
        'สำเร็จ',
        'บันทึกข้อมูลเรียบร้อยแล้ว',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      Get.snackbar(
        'เกิดข้อผิดพลาด',
        'ไม่สามารถบันทึกข้อมูลได้',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade100,
      );
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

    final XFile? picked =
        await _picker.pickImage(source: ImageSource.gallery);

    if (picked == null) return;

    try {
      saving.value = true;

      final avatarUrl =
          await repo.uploadAvatar(userId, File(picked.path));

      profile.value = profile.value!.copyWith(
        profilePic: avatarUrl,
      );

      await loadProfile();

      Get.snackbar(
        'สำเร็จ',
        'อัปเดตรูปโปรไฟล์เรียบร้อย',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      Get.snackbar(
        'เกิดข้อผิดพลาด',
        'ไม่สามารถอัปโหลดรูปได้',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade100,
      );
    } finally {
      saving.value = false;
    }
  }
}