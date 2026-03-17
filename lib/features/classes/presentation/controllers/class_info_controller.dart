import 'package:get/get.dart';
import '../../../shared/repositories/class_feed_repository.dart';
import '../../../classes/data/models/class_schedule_model.dart';
import '../../../shared/models/section_educator_model.dart';

class ClassInfoController extends GetxController {
  final int sectionId;

  ClassInfoController({required this.sectionId});

  final ClassFeedRepository _repo = ClassFeedRepository();

  final isLoading = false.obs;
  final error = ''.obs;

  final roomLocation = RxnString();
  final schedules = <ClassScheduleModel>[].obs;
  final members = <Map<String, dynamic>>[].obs;
  final educators = <SectionEducatorModel>[].obs;

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
        roomLocation.value = null;
        schedules.clear();
        members.clear();
        educators.clear();
        return;
      }
      final result = data;

      roomLocation.value = result.roomLocation;
      schedules.assignAll(result.schedules);
      members.assignAll(result.members);
      educators.assignAll(result.educators);
    } catch (e) {
      error.value = 'ไม่สามารถโหลดข้อมูลได้';
      roomLocation.value = null;
      schedules.clear();
      members.clear();
      educators.clear();
    } finally {
      isLoading.value = false;
    }
  }

  /// รวม location แบบไม่ซ้ำ
  List<String> get uniqueLocations {
    final locations = <String>{};

    final roomLocationText = roomLocation.value?.trim() ?? '';
    if (roomLocationText.isNotEmpty) {
      locations.add(roomLocationText);
    }

    for (final schedule in schedules) {
      final roomNumber = schedule.room?.roomNumber.toString() ?? '';
      final buildingName = schedule.building?.buildingName.toString() ?? '';

      if (roomNumber.isNotEmpty || buildingName.isNotEmpty) {
        locations.add(
          [
            if (buildingName.isNotEmpty) buildingName,
            if (roomNumber.isNotEmpty) 'ห้อง $roomNumber',
          ].join(' '),
        );
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
