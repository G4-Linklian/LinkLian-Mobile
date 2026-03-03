import 'package:get/get.dart';
import '../../shared/repositories/class_feed_repository.dart';

class ClassInfoController extends GetxController {
  final int sectionId;

  ClassInfoController({required this.sectionId});

  final ClassFeedRepository _repo = ClassFeedRepository();

  final isLoading = false.obs;
  final error = ''.obs;

  final schedules = <Map<String, dynamic>>[].obs;
  final members = <Map<String, dynamic>>[].obs;
  final educators = <Map<String, dynamic>>[].obs;

  @override
  void onInit() {
    super.onInit();
    fetchClassInfo();
  }

  Future<void> fetchClassInfo() async {
    try {
      isLoading.value = true;
      error.value = '';

      final data = await _repo.getClassInfo(sectionId: sectionId);

      if (data == null) {
        error.value = 'ไม่พบข้อมูล';
        return;
      }

      schedules.assignAll(
        List<Map<String, dynamic>>.from(data['schedules'] ?? []),
      );
      members.assignAll(
        List<Map<String, dynamic>>.from(data['members'] ?? []),
      );
      educators.assignAll(
        List<Map<String, dynamic>>.from(data['educators'] ?? []),
      );
    } catch (e) {
      error.value = 'ไม่สามารถโหลดข้อมูลได้';
    } finally {
      isLoading.value = false;
    }
  }

  /// รวม location แบบไม่ซ้ำ
  List<String> get uniqueLocations {
    final locations = <String>{};

    for (final schedule in schedules) {
      final room = schedule['room'] as Map<String, dynamic>?;
      final building = schedule['building'] as Map<String, dynamic>?;

      final roomNumber = room?['room_number']?.toString() ?? '';
      final buildingName = building?['building_name']?.toString() ?? '';

      if (roomNumber.isNotEmpty || buildingName.isNotEmpty) {
        locations.add([
          if (buildingName.isNotEmpty) buildingName,
          if (roomNumber.isNotEmpty) 'ห้อง $roomNumber',
        ].join(' '));
      }
    }

    return locations.toList();
  }

  String formatTime(String time) {
    if (time.isEmpty) return '';
    final parts = time.split(':');
    return parts.length >= 2 ? '${parts[0]}:${parts[1]}' : time;
  }
}