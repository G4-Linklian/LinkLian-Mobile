import 'package:get/get.dart';
import '../../../data/model/community_member_model.dart';
import '../../../data/repository/community_member_repository.dart';

class CommunityPendingController extends GetxController {
  final CommunityMemberRepository _repo;

  CommunityPendingController(this._repo);

  final pendingMembers = <CommunityMemberModel>[].obs;
  final isLoading = false.obs;
  final errorMessage = RxnString();

  late int communityId;

  @override
  void onInit() {
    super.onInit();

    final args = Get.arguments;
    if (args == null || args['communityId'] == null) {
      errorMessage.value = "ไม่พบ communityId";
      return;
    }

    communityId = args['communityId'];
    loadPending();
  }

  Future<void> loadPending() async {
    try {
      isLoading.value = true;
      errorMessage.value = null;

      final raw = await _repo.getPendingMembers(communityId);

      pendingMembers.assignAll(
        raw.map((e) => CommunityMemberModel.fromJson(e)).toList(),
      );
    } catch (e) {
      errorMessage.value = "โหลดคำขอเข้าร่วมไม่สำเร็จ";
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> approve(int userId) async {
    try {
      await _repo.approve(communityId, userId);

      final index = pendingMembers.indexWhere((e) => e.userSysId == userId);

      if (index != -1) {
        final old = pendingMembers[index];

        pendingMembers[index] = CommunityMemberModel(
          userSysId: old.userSysId,
          firstName: old.firstName,
          lastName: old.lastName,
          profilePic: old.profilePic,
          status: 'active',
        );
      }
    } catch (e) {
      print("ERROR APPROVE: $e");
    }
  }

  Future<void> reject(int userId) async {
    try {
      await _repo.reject(communityId, userId);

      pendingMembers.removeWhere((e) => e.userSysId == userId);
    } catch (e) {
      print("ERROR REJECT: $e");
    }
  }
}
