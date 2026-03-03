import 'package:get/get.dart';
import '../../../data/model/assignment_model.dart';
import '../../../data/repository/assignment_repository.dart';

class SearchAssignmentController extends GetxController {
  final AssignmentRepository _assignmentRepository = Get.find<AssignmentRepository>();

  final RxBool isLoading = false.obs;
  final RxString error = ''.obs;
  final RxList<AssignmentModel> results = <AssignmentModel>[].obs;
  final RxString keyword = ''.obs;

  int? sectionId;
  String role = 'student';

  Worker? _debounceWorker;

  void init({int? sectionId, String? role}) {
    this.sectionId = sectionId;
    this.role = role ?? 'student';

    _debounceWorker = debounce<String>(
      keyword,
      (value) {
        _search(value);
      },
      time: const Duration(milliseconds: 500),
    );
  }

  void onKeywordChanged(String value) {
    keyword.value = value.trim();
  }

  Future<void> _search(String value) async {
    final q = value.trim();

    if (q.isEmpty) {
      results.clear();
      error.value = '';
      return;
    }

    if (sectionId == null) {
      error.value = 'ไม่พบข้อมูลห้องเรียน';
      return;
    }

    try {
      isLoading.value = true;
      error.value = '';

      final assignments = await _assignmentRepository.searchAssignments(
        sectionId: sectionId!,
        keyword: q,
        role: role,
      );

      results.assignAll(assignments);
    } catch (e) {
      error.value = 'ไม่สามารถค้นหาได้';
    } finally {
      isLoading.value = false;
    }
  }

  void clear() {
    keyword.value = '';
    results.clear();
    error.value = '';
  }

  @override
  void onClose() {
    _debounceWorker?.dispose();
    super.onClose();
  }
}
