import 'package:LinkLian/features/profile/data/models/teacher_dashboard_model.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../auth/controller/auth_controller.dart';
// import '../../data/model/teacher_dashboard_model.dart';
import '../../domain/usecases/teacher_dashboard_usecases.dart';

class TeacherDashboardController extends GetxController {
  final GetTeacherDashboardUseCase getTeacherDashboardUseCase;
  final GetTeacherAvailableReportMonthsUseCase getAvailableReportMonthsUseCase;

  TeacherDashboardController({
    required this.getTeacherDashboardUseCase,
    required this.getAvailableReportMonthsUseCase,
  });

  final Rx<TeacherDashboardResponse?> dashboard = Rx<TeacherDashboardResponse?>(
    null,
  );
  final RxList<String> availableMonths = <String>[].obs;
  final Rx<String> selectedMonth = Rx<String>('');
  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;

  @override
  void onInit() {
    super.onInit();
    loadAvailableMonths();
  }

  Future<void> loadAvailableMonths() async {
    try {
      isLoading.value = true;
      // Get userId from your auth controller if available
      final userId = _getUserId();
      if (userId == null) return;

      final result = await getAvailableReportMonthsUseCase(userId: userId);
      result.fold(
        (error) {
          errorMessage.value = error;
        },
        (months) {
          availableMonths.assignAll(months);
          if (months.isNotEmpty) {
            selectedMonth.value = months.first;
            loadDashboard();
          }
        },
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loadDashboard() async {
    try {
      isLoading.value = true;
      final userId = _getUserId();
      if (userId == null) return;

      final result = await getTeacherDashboardUseCase(userId: userId);
      result.fold(
        (error) {
          errorMessage.value = error;
          dashboard.value = null;
        },
        (response) {
          dashboard.value = response;
          errorMessage.value = '';
        },
      );
    } finally {
      isLoading.value = false;
    }
  }

  void selectMonth(String month) {
    selectedMonth.value = month;
    loadDashboard();
  }

  String? _getUserId() {
    try {
      final authController = Get.find<AuthController>();
      final userId = authController.userId.value;
      return userId?.toString();
    } catch (_) {
      debugPrint(
        '[TeacherDashboardController] Error occurred while fetching user ID',
      );
      return null;
    }
  }

  String formatMonth(String monthString) {
    try {
      // Format: "2567/01" to "มกราคม 2567"
      final parts = monthString.split('/');
      if (parts.length != 2) return monthString;

      final year = int.tryParse(parts[0]) ?? 0;
      final month = int.tryParse(parts[1]) ?? 0;

      const monthNames = [
        'มกราคม',
        'กุมภาพันธ์',
        'มีนาคม',
        'เมษายน',
        'พฤษภาคม',
        'มิถุนายน',
        'กรกฎาคม',
        'สิงหาคม',
        'กันยายน',
        'ตุลาคม',
        'พฤศจิกายน',
        'ธันวาคม',
      ];

      if (month >= 1 && month <= 12) {
        return '${monthNames[month - 1]} $year';
      }
      return monthString;
    } catch (_) {
      return monthString;
    }
  }
}
