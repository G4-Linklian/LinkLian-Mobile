import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../data/models/dashboard_model.dart';
import '../../data/repositories/dashboard_repository.dart';
import '../../domain/usecases/dashboard_usecases.dart';

class DashboardController extends GetxController {
  final DashboardRepository repository;
  final GetStudentDashboardUseCase getStudentDashboardUseCase;
  final GetAvailableReportMonthsUseCase getAvailableReportMonthsUseCase;

  DashboardController({
    required this.repository,
    required this.getStudentDashboardUseCase,
    required this.getAvailableReportMonthsUseCase,
  });

  // Observable
  final Rx<DashboardResponse?> dashboard = Rx<DashboardResponse?>(null);
  final RxList<String> availableMonths = <String>[].obs;
  final Rx<String> selectedMonth = Rx<String>('');
  final Rx<bool> isLoading = Rx<bool>(false);
  final Rx<String> errorMessage = Rx<String>('');

  @override
  void onInit() {
    super.onInit();
    // ดึงเดือนปัจจุบัน (เดือนที่แล้ว)
    _setDefaultMonth();
  }

  void _setDefaultMonth() {
    final now = DateTime.now();
    final lastMonth = DateTime(now.year, now.month - 1);
    final formattedMonth = DateFormat('yyyy-MM').format(lastMonth);
    selectedMonth.value = formattedMonth;
  }

  Future<void> loadAvailableMonths(int userId) async {
    _lastUserId = userId; // Store for auto-load

    final result = await getAvailableReportMonthsUseCase(
      GetAvailableReportMonthsParams(userId: userId),
    );

    result.fold(
      (failure) {
        errorMessage.value = failure.message;
      },
      (months) {
        months.sort((a, b) => b.compareTo(a));
        availableMonths.assignAll(months);
        if (availableMonths.isNotEmpty && selectedMonth.value.isEmpty) {
          selectedMonth.value = availableMonths.first;
        }
        // Auto-load dashboard with selected month
        if (selectedMonth.value.isNotEmpty) {
          loadDashboard(
            userId: userId,
            reportMonth: selectedMonth.value,
            roleType: _lastRoleType,
          );
        }
      },
    );
  }

  Future<void> loadDashboard({
    required int userId,
    required String reportMonth,
    String roleType = 'STUDENT',
  }) async {
    try {
      // Store userId and roleType for selectMonth to use
      _lastUserId = userId;
      _lastRoleType = roleType;

      isLoading.value = true;
      errorMessage.value = '';

      final result = await getStudentDashboardUseCase(
        GetStudentDashboardParams(
          userId: userId,
          reportMonth: reportMonth,
          roleType: roleType,
        ),
      );

      result.fold(
        (failure) {
          errorMessage.value = failure.message;
          dashboard.value = null;
          debugPrint('[DashboardController] Error: ${failure.message}');
        },
        (dashboardData) {
          dashboard.value = dashboardData;
          errorMessage.value = '';
          debugPrint('[DashboardController] Dashboard loaded successfully');
        },
      );
    } catch (e) {
      errorMessage.value = 'Exception: $e';
      dashboard.value = null;
      debugPrint('[DashboardController] Exception: $e');
    } finally {
      isLoading.value = false;
    }
  }

  void selectMonth(String month) {
    selectedMonth.value = month;
    // Load dashboard data when month changes
    if (_lastUserId != null) {
      loadDashboard(
        userId: _lastUserId!,
        reportMonth: month,
        roleType: _lastRoleType,
      );
    }
  }

  void setRoleType(String roleType) {
    _lastRoleType = roleType;
  }

  int? _lastUserId;
  String _lastRoleType = 'STUDENT';

  String formatMonth(String yearMonth) {
    // yearMonth เป็นรูปแบบ 'YYYY-MM' เช่น '2026-01'
    try {
      final parts = yearMonth.split('-');
      final month = int.parse(parts[1]);
      final year = int.parse(parts[0]);
      final date = DateTime(year, month);
      return DateFormat('MMMM yyyy', 'th').format(date);
    } catch (e) {
      return yearMonth;
    }
  }
}
