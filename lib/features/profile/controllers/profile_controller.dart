import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import '../../../data/model/profile_model.dart';
import '../../../data/repository/profile_repository.dart';
import '../../../data/repository/teaching_schedule_repository.dart';
import '../../auth/controller/auth_controller.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../../../data/model/teaching_schedule_model.dart';
import 'package:flutter/foundation.dart';
import '../../layout/controllers/navigation_controller.dart';
import '../../../config/app_routes.dart';

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

  bool _controllersInitialized = false;

  bool get isStudent => profile.value?.isStudent ?? false;
  bool get isTeacher => profile.value?.isTeacher ?? false;

  /// Helper: Debug logging
  void _log(String message) {
    assert(() {
      debugPrint(message);
      return true;
    }());
  }

  @override
  void onInit() {
    super.onInit();
    _log('🎯 ProfileController onInit()');
    _setupListeners();
  }

  void _setupListeners() {
    final auth = Get.find<AuthController>();

    _log('👁️ Setting up userId listener...');

    ever<int?>(auth.userId, (userId) {
      _log('📍 userId changed: ${auth.userId.value}');

      if (userId != null) {
        _clearProfileData();
        loadAll();
      } else {
        _clearProfileData();
      }
    });

    if (auth.userId.value != null) {
      _log('📍 userId already available: ${auth.userId.value}');
      loadAll();
    }
  }

  void _clearProfileData() {
    _log('🗑️ Clearing profile data...');
    profile.value = null;
    teachingSchedules.clear();

    if (_controllersInitialized) {
      firstNameCtrl.clear();
      lastNameCtrl.clear();
      phoneCtrl.clear();
    }
  }

  Future<void> loadAll() async {
    final userId = _getUserId();
    if (userId == null) {
      _log('⚠️ Cannot load: userId is null');
      return;
    }

    _log('📥 loadAll() for userId: $userId');

    try {
      await loadProfile();
      if (isTeacher) {
        await loadTeachingSchedule();
      }
    } catch (e) {
      _log('❌ Error in loadAll: $e');
    }
  }

  int? _getUserId() {
    final auth = Get.find<AuthController>();
    final userId = auth.userId.value;

    if (userId == null) {
      _log('⚠️ userId is null in ProfileController');
      return null;
    }

    return userId;
  }

  Future<void> loadProfile() async {
    try {
      final userId = _getUserId();
      if (userId == null) return;

      loading.value = true;
      _log('📥 Loading profile for user: $userId');

      final data = await repo.getProfile(userId);

      if (!_controllersInitialized) {
        firstNameCtrl = TextEditingController(text: data.firstName);
        lastNameCtrl = TextEditingController(text: data.lastName);
        phoneCtrl = TextEditingController(text: data.phone ?? '');
        _controllersInitialized = true;
        _log('✅ TextEditingControllers initialized');
      } else {
        firstNameCtrl.text = data.firstName;
        lastNameCtrl.text = data.lastName;
        phoneCtrl.text = data.phone ?? '';
        _log('✅ TextEditingControllers updated');
      }

      profile.value = data;
      _log('✅ Profile loaded: ${data.firstName} ${data.lastName}');
    } catch (e) {
      _log('❌ Failed to load profile: $e');
      profile.value = null;
    } finally {
      loading.value = false;
    }
  }

  Future<void> loadTeachingSchedule() async {
    if (!isTeacher) {
      _log('⏭️ User is not teacher, skipping teaching schedule');
      return;
    }

    final userId = _getUserId();
    if (userId == null) return;

    try {
      loadingSchedule.value = true;
      _log('📥 Loading teaching schedule for user: $userId');

      final schedules = await scheduleRepo.getByEducator(userId);

      _log('✅ Got ${schedules.length} schedules from repository');

      teachingSchedules.assignAll(schedules);

      _log('✅ Teaching schedule loaded: ${teachingSchedules.length} items');

      // Debug: Print all schedules
      for (var i = 0; i < teachingSchedules.length; i++) {
        final s = teachingSchedules[i];
        _log(
          '  [$i] ${s.subjectName} - Day ${s.dayOfWeek} ${s.startTime}-${s.endTime}',
        );
      }
    } catch (e) {
      _log('❌ Failed to load teaching schedule: $e');
      teachingSchedules.clear();
    } finally {
      loadingSchedule.value = false;
    }
  }

  Future<void> logout() async {
    final nav = Get.find<NavigationController>();

    nav.selectedIndex.value = 1;
    nav.hideClassDetail();
    nav.hideCommunityDetail();
    nav.hideClassAssignment();

    final auth = Get.find<AuthController>();
    await auth.logout();

    Get.offAllNamed(AppRoutes.login);
  }

  Future<void> updateProfile({
    required String firstName,
    required String lastName,
    required String phone,
  }) async {
    if (firstName.trim().isEmpty || lastName.trim().isEmpty) {
      throw Exception('กรุณาใส่ชื่อและนามสกุล');
    }
    if (phone.trim().isEmpty) {
      throw Exception('กรุณากรอกเบอร์โทรศัพท์');
    }

    if (!RegExp(r'^0[0-9]{9}$').hasMatch(phone)) {
      throw Exception('กรุณากรอกเบอร์โทรให้ถูกต้อง');
    }

    final auth = Get.find<AuthController>();
    final userId = auth.userId.value;
    if (userId == null) return;

    try {
      saving.value = true;
      _log('💾 Updating profile for user $userId...');

      await repo.updateProfile(
        userId,
        firstName: firstName,
        lastName: lastName,
        phone: phone,
        profilePic: profile.value?.profilePic,
      );

      await loadProfile();
      _log('✅ Profile updated successfully');
    } catch (e) {
      _log('❌ Failed to update profile: $e');
      rethrow;
    } finally {
      saving.value = false;
    }
  }

  Future<void> changeAvatar() async {
    final userId = _getUserId();
    if (userId == null) return;

    final XFile? picked = await _picker.pickImage(source: ImageSource.gallery);
    if (picked == null) {
      _log('⏭️ Image selection cancelled');
      return;
    }

    try {
      saving.value = true;
      _log('📤 Uploading avatar for user $userId...');

      final fileUrl = await repo.uploadAvatar(userId, File(picked.path));
      _log('✅ Avatar uploaded: $fileUrl');

      await repo.updateProfile(
        userId,
        firstName: profile.value!.firstName,
        lastName: profile.value!.lastName,
        phone: profile.value!.phone,
        profilePic: fileUrl,
      );

      await loadProfile();
      _log('✅ Avatar changed successfully');
    } catch (e) {
      _log('❌ Failed to change avatar: $e');
      rethrow;
    } finally {
      saving.value = false;
    }
  }

  Future<void> pickImageFromGallery() async {
    await changeAvatar();
  }

  Future<void> pickImageFromCamera() async {
    final userId = _getUserId();
    if (userId == null) return;

    final XFile? picked = await _picker.pickImage(source: ImageSource.camera);
    if (picked == null) {
      _log('⏭️ Camera cancelled');
      return;
    }

    try {
      saving.value = true;
      _log('📤 Uploading photo from camera for user $userId...');

      final fileUrl = await repo.uploadAvatar(userId, File(picked.path));
      _log('✅ Photo uploaded: $fileUrl');

      profile.value = profile.value!.copyWith(profilePic: fileUrl);
      _log('✅ Photo updated in memory');
    } catch (e) {
      _log('❌ Failed to upload photo: $e');
      rethrow;
    } finally {
      saving.value = false;
    }
  }

  Future<void> deleteAvatar() async {
    final userId = _getUserId();
    if (userId == null) return;

    final currentProfile = profile.value;
    if (currentProfile == null) return;

    final currentPic = currentProfile.profilePic;
    if (currentPic == null || currentPic.isEmpty) {
      _log('⏭️ No avatar to delete');
      return;
    }

    try {
      saving.value = true;
      _log('🗑️ Deleting avatar for user $userId...');

      await repo.updateProfile(
        userId,
        firstName: currentProfile.firstName,
        lastName: currentProfile.lastName,
        phone: currentProfile.phone,
        clearProfilePic: true,
      );

      imageCache.clear();
      imageCache.clearLiveImages();

      await loadProfile();
      _log('✅ Avatar deleted successfully');
    } catch (e) {
      _log('❌ Failed to delete avatar: $e');
      rethrow;
    } finally {
      saving.value = false;
    }
  }

  void restoreOriginalProfilePic(String? originalPic) {
    final currentProfile = profile.value;
    if (currentProfile == null) return;

    if (originalPic == null) {
      profile.value = currentProfile.copyWith(clearProfilePic: true);
      _log('↩️ Avatar restored to deleted state');
    } else {
      profile.value = currentProfile.copyWith(profilePic: originalPic);
      _log('↩️ Avatar restored');
    }
  }

  @override
  void onClose() {
    _log('🔴 ProfileController onClose() - cleaning up');

    if (_controllersInitialized) {
      firstNameCtrl.dispose();
      lastNameCtrl.dispose();
      phoneCtrl.dispose();
    }

    _clearProfileData();
    super.onClose();
  }
}
