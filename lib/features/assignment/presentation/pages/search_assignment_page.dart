import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/constants/colors.dart';
import '../../../../core/constants/sizes.dart';
import '../../../../core/constants/linklian-icon.dart';
import '../../../../config/app_routes.dart';
import '../controllers/search_assignment_controller.dart';
import '../widgets/assignment_card.dart';

class SearchAssignmentPage extends StatefulWidget {
  const SearchAssignmentPage({super.key});

  @override
  State<SearchAssignmentPage> createState() => _SearchAssignmentPageState();
}

class _SearchAssignmentPageState extends State<SearchAssignmentPage> {
  final TextEditingController _searchController = TextEditingController();

  int? _sectionId;
  String _subjectName = '';
  String _role = 'student';
  late final SearchAssignmentController controller;

  @override
  void initState() {
    super.initState();
    final args = Get.arguments as Map<String, dynamic>?;

    _sectionId = args?['sectionId'] as int?;
    _subjectName = args?['subjectName'] as String? ?? '';
    _role = args?['role'] as String? ?? 'student';

    if (!Get.isRegistered<SearchAssignmentController>()) {
      Get.put(SearchAssignmentController());
    }
    controller = Get.find<SearchAssignmentController>();
    controller.init(sectionId: _sectionId, role: _role);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  bool get _isTeacher => _role == 'teacher' || _role == 'instructor';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(LinkLianIcon.back, color: AppColors.primaryPalette[800]),
          onPressed: () => Get.back(),
        ),
        title: Text(
          'ค้นหาการบ้าน',
          style: TextStyle(
            color: AppColors.primaryPalette[800]!,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Search Input
          Padding(
            padding: const EdgeInsets.all(AppSizes.md),
            child: TextField(
              controller: _searchController,
              autofocus: true,
              onChanged: controller.onKeywordChanged,
              decoration: InputDecoration(
                hintText: _subjectName.isNotEmpty
                    ? 'ค้นหาการบ้านใน $_subjectName...'
                    : 'ค้นหาการบ้าน...',
                prefixIcon: Icon(
                  Icons.search,
                  color: AppColors.primaryPalette[600],
                ),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: Icon(
                          Icons.clear,
                          color: AppColors.primaryPalette[400],
                        ),
                        onPressed: () {
                          _searchController.clear();
                          controller.clear();
                        },
                      )
                    : null,
                filled: true,
                fillColor: AppColors.primaryPalette[50],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: AppColors.primaryPalette[300]!),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: AppColors.primaryPalette[300]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide(
                    color: AppColors.primaryPalette[500]!,
                    width: 2,
                  ),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 8,
                ),
              ),
            ),
          ),

          // Results
          Expanded(child: _buildResults()),
        ],
      ),
    );
  }

  Widget _buildResults() {
    return Obx(() {
      if (controller.isLoading.value) {
        return const Center(child: CircularProgressIndicator());
      }

      if (controller.error.isNotEmpty) {
        return Center(
          child: Text(
            controller.error.value,
            style: TextStyle(color: AppColors.dangerPalette[500]),
          ),
        );
      }

      if (controller.keyword.isEmpty) {
        return _emptyHint();
      }

      if (controller.results.isEmpty) {
        return _notFound();
      }

      return ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: AppSizes.md) +
            const EdgeInsets.only(bottom: 16),
        itemCount: controller.results.length,
        itemBuilder: (_, i) {
          final assignment = controller.results[i];
          return AssignmentCard(
            assignment: assignment,
            isTeacher: _isTeacher,
            onTap: () {
              Get.toNamed(
                AppRoutes.assignmentSubmission,
                arguments: {'postId': assignment.postId},
              );
            },
          );
        },
      );
    });
  }

  Widget _emptyHint() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search, size: 64, color: AppColors.primaryPalette[300]),
          const SizedBox(height: 16),
          Text(
            'พิมพ์คำค้นหาเพื่อเริ่มต้น',
            style: TextStyle(
              fontSize: 16,
              color: AppColors.primaryPalette[400],
            ),
          ),
        ],
      ),
    );
  }

  Widget _notFound() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 64,
            color: AppColors.primaryPalette[200],
          ),
          const SizedBox(height: 16),
          Text(
            'ไม่พบการบ้านที่ตรงกัน',
            style: TextStyle(
              fontSize: 16,
              color: AppColors.primaryPalette[400],
            ),
          ),
        ],
      ),
    );
  }
}
