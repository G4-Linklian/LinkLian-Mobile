import 'package:LinkLian/core/utils/logger.dart';
import 'package:LinkLian/features/community/presentation/controllers/community_controller.dart';
import 'package:LinkLian/features/community/presentation/controllers/community_detail_controller.dart';
import 'package:get/get.dart';
import '../../data/models/community_member_model.dart';
import '../../data/repositories/community_member_repository.dart';

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

      pendingMembers.removeWhere((e) => e.userSysId == userId);

      //uadate in community detail page
      if (Get.isRegistered<CommunityDetailController>()) {
        final detailController = Get.find<CommunityDetailController>();
        final community = detailController.community.value;

        if (community != null) {
          detailController.community.value = community.copyWith(
            memberCount: community.memberCount + 1,
          );
        }
      }

      // update in communitypage
      if (Get.isRegistered<CommunityController>()) {
        final commuController = Get.find<CommunityController>();

        final index = commuController.communities.indexWhere(
          (c) => c.communityId == communityId,
        );

        if (index != -1) {
          final old = commuController.communities[index];

          commuController.communities[index] = old.copyWith(
            memberCount: old.memberCount + 1,
          );
        }
      }
    } catch (e) {
      appLog.info("[community]ERROR APPROVE: $e");
    }
  }

  Future<void> reject(int userId) async {
    try {
      await _repo.reject(communityId, userId);

      pendingMembers.removeWhere((e) => e.userSysId == userId);
    } catch (e) {
      appLog.info("[community]ERROR REJECT: $e");
    }
  }
}
