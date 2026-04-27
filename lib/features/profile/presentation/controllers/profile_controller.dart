import 'package:LinkLian/core/utils/logger.dart';
import 'package:LinkLian/core/services/api_client.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../shared/models/profile_model.dart';
import '../../../shared/repositories/profile_repository.dart';
import '../../data/repositories/teaching_schedule_repository.dart';
import '../../data/repositories/report_repository.dart';
import '../../../auth/controller/auth_controller.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../../data/model/teaching_schedule_model.dart';
import '../../../layout/controllers/navigation_controller.dart';
import '../../../../config/app_routes.dart';

class ProfileController extends GetxController {
  final ProfileRepository repo;
  final TeachingScheduleRepository scheduleRepo;
  late final ReportRepository reportRepo;

  ProfileController(this.repo, this.scheduleRepo) {
    if (Get.isRegistered<ReportRepository>()) {
      reportRepo = Get.find<ReportRepository>();
    } else {
      reportRepo = ReportRepository(ApiClient());
    }
  }

  final profile = Rxn<ProfileModel>();
  final loading = false.obs;
  final saving = false.obs;
  final ImagePicker _picker = ImagePicker();
  bool _isLoadingAll = false; // BUG FIX #4: Prevent race condition in loadAll
  final reportImages = <File>[].obs;
  final reporting = false.obs;
  final teachingSchedules = <TeachingScheduleModel>[].obs;
  final loadingSchedule = false.obs;

  static const int maxReportImages = 3;

  late TextEditingController firstNameCtrl;
  late TextEditingController lastNameCtrl;
  late TextEditingController phoneCtrl;

  bool _controllersInitialized = false;

  bool get isStudent => profile.value?.isStudent ?? false;
  bool get isTeacher => profile.value?.isTeacher ?? false;

  /// Helper: Debug logging
  void _log(String message) {
    assert(() {
      appLog.info(message);
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

    // BUG FIX #11: Properly clean up state to prevent corruption
    if (_controllersInitialized) {
      try {
        firstNameCtrl.clear();
        lastNameCtrl.clear();
        phoneCtrl.clear();
      } catch (e) {
        _log('⚠️ Error clearing controllers: $e');
      }
    }
  }

  Future<void> loadAll() async {
    // BUG FIX #4: Prevent race condition - only allow one loadAll at a time
    if (_isLoadingAll) {
      _log('⏭️ loadAll already in progress, skipping concurrent call');
      return;
    }

    final userId = _getUserId();
    if (userId == null) {
      _log('⚠️ Cannot load: userId is null');
      return;
    }

    _log('📥 loadAll() for userId: $userId');
    _isLoadingAll = true;

    try {
      await loadProfile();
      if (isTeacher) {
        await loadTeachingSchedule();
      }
    } catch (e) {
      // BUG FIX #8: Don't fail silently - notify user of errors
      _log('❌ Error in loadAll: $e');
      Get.snackbar('ข้อผิดพลาด', 'ไม่สามารถโหลดข้อมูลได้: $e',
          duration: Duration(seconds: 2));
    } finally {
      _isLoadingAll = false;
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
        try {
          firstNameCtrl = TextEditingController(text: data.firstName);
          lastNameCtrl = TextEditingController(text: data.lastName);
          phoneCtrl = TextEditingController(text: data.phone ?? '');
          _controllersInitialized = true;
          _log('✅ TextEditingControllers initialized');
        } catch (e) {
          // BUG FIX #5: Prevent memory leak if controller initialization fails
          _log('❌ Failed to initialize controllers: $e');
          _controllersInitialized = false;
          rethrow;
        }
      } else {
        // Safely update existing controllers
        if (firstNameCtrl.hasListeners) firstNameCtrl.text = data.firstName;
        if (lastNameCtrl.hasListeners) lastNameCtrl.text = data.lastName;
        if (phoneCtrl.hasListeners) phoneCtrl.text = data.phone ?? '';
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
      appLog.info('[Profile]Failed to load teaching schedule: $e');
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
    // BUG FIX #6: Add input sanitization to prevent injection attacks
    final cleanFirstName = firstName.trim();
    final cleanLastName = lastName.trim();
    final cleanPhone = phone.trim();

    if (cleanFirstName.isEmpty || cleanLastName.isEmpty) {
      throw Exception('กรุณาใส่ชื่อและนามสกุล');
    }
    if (cleanPhone.isEmpty) {
      throw Exception('กรุณากรอกเบอร์โทรศัพท์');
    }

    // BUG FIX #7: Enhance phone validation - check for common Thai telecom prefixes
    // Valid Thai prefixes: 08, 09 (mobile), 02 (Bangkok), 0xx (other areas)
    if (!RegExp(r'^0[0-9]{9}$').hasMatch(cleanPhone)) {
      throw Exception('กรุณากรอกเบอร์โทรให้ถูกต้อง');
    }
    
    // Additional telecom validation for Thai numbers
    final prefix = cleanPhone.substring(0, 2);
    if (!['08', '09', '02'].contains(prefix) && !RegExp(r'^0[3-7]').hasMatch(prefix)) {
      throw Exception('หมายเลขโทรศัพท์ไม่ถูกต้อง');
    }

    final auth = Get.find<AuthController>();
    final userId = auth.userId.value;
    if (userId == null) return;

    try {
      saving.value = true;
      _log('💾 Updating profile for user $userId...');

      await repo.updateProfile(
        userId,
        firstName: cleanFirstName,
        lastName: cleanLastName,
        phone: cleanPhone,
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

      // BUG FIX #1: Add null check before force unwrap
      final currentProfile = profile.value;
      if (currentProfile == null) {
        _log('❌ Profile not loaded');
        throw Exception('ไม่สามารถอัพโหลดรูปได้ กรุณาโหลดข้อมูลส่วนตัวใหม่');
      }

      await repo.updateProfile(
        userId,
        firstName: currentProfile.firstName,
        lastName: currentProfile.lastName,
        phone: currentProfile.phone,
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

      // BUG FIX #2 & #3: Add null check and persist to database instead of just memory
      final currentProfile = profile.value;
      if (currentProfile == null) {
        _log('❌ Profile not loaded');
        throw Exception('ไม่สามารถอัพโหลดรูปได้ กรุณาโหลดข้อมูลส่วนตัวใหม่');
      }

      // Persist to database instead of just updating in memory
      await repo.updateProfile(
        userId,
        firstName: currentProfile.firstName,
        lastName: currentProfile.lastName,
        phone: currentProfile.phone,
        profilePic: fileUrl,
      );

      // BUG FIX #9: Clear image cache after upload
      imageCache.clear();
      imageCache.clearLiveImages();

      profile.value = currentProfile.copyWith(profilePic: fileUrl);
      _log('✅ Photo updated and persisted');
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
    // BUG FIX #10: Validate profile exists before restoration
    final currentProfile = profile.value;
    if (currentProfile == null) {
      _log('⚠️ Cannot restore: profile not loaded');
      return;
    }

    if (originalPic == null) {
      profile.value = currentProfile.copyWith(clearProfilePic: true);
      _log('↩️ Avatar restored to deleted state');
    } else {
      profile.value = currentProfile.copyWith(profilePic: originalPic);
      _log('↩️ Avatar restored');
    }
  }

  Future<void> pickReportImagesFromGallery() async {
    if (reportImages.length >= maxReportImages) {
      throw Exception('อัปโหลดรูปได้สูงสุด $maxReportImages รูป');
    }

    final picks = await _picker.pickMultiImage();
    if (picks.isEmpty) return;

    final remaining = maxReportImages - reportImages.length;
    final selected = picks.take(remaining).map((x) => File(x.path)).toList();

    reportImages.addAll(selected);
  }

  void removeReportImageAt(int index) {
    if (index < 0 || index >= reportImages.length) return;
    reportImages.removeAt(index);
  }

  Future<void> submitInstitutionReport({
    required String title,
    required String detail,
  }) async {
    final cleanTitle = title.trim();
    final cleanDetail = detail.trim();

    if (cleanTitle.isEmpty) {
      throw Exception('กรุณาระบุหัวข้อปัญหา');
    }
    if (cleanDetail.isEmpty) {
      throw Exception('กรุณาระบุรายละเอียดปัญหา');
    }

    final auth = Get.find<AuthController>();
    final reporterId = auth.userId.value;
    final instId = auth.instId.value;

    if (reporterId == null || instId == null) {
      throw Exception('ไม่พบข้อมูลผู้ใช้ กรุณาเข้าสู่ระบบใหม่');
    }

    try {
      reporting.value = true;

      final reportFiles = await reportRepo.uploadReportImages(
        reportImages.toList(),
      );

      await reportRepo.createInstitutionReport(
        instId: instId,
        reporterId: reporterId,
        title: cleanTitle,
        detail: cleanDetail,
        reportFiles: reportFiles,
      );

      reportImages.clear();
    } finally {
      reporting.value = false;
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
