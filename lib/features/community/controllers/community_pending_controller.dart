import 'package:LinkLian/core/utils/logger.dart';
import 'package:LinkLian/features/community/controllers/community_controller.dart';
import 'package:LinkLian/features/community/controllers/community_detail_controller.dart';
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

    // ✅ ลบออกจาก list ทันที
    pendingMembers.removeWhere((e) => e.userSysId == userId);

    // ❗ ไม่ต้อง refresh ก็ได้ เพราะ removeWhere กระตุ้น .obs อยู่แล้ว
    // pendingMembers.refresh();  ← ลบได้

    // ✅ อัปเดตหน้า detail
    if (Get.isRegistered<CommunityDetailController>()) {
      final detailController = Get.find<CommunityDetailController>();
      final community = detailController.community.value;

      if (community != null) {
        detailController.community.value =
            community.copyWith(memberCount: community.memberCount + 1);
      }
    }

    // ✅ อัปเดตหน้ารวม community
    if (Get.isRegistered<CommunityController>()) {
      final commuController = Get.find<CommunityController>();

      final index = commuController.communities
          .indexWhere((c) => c.communityId == communityId);

      if (index != -1) {
        final old = commuController.communities[index];

        commuController.communities[index] =
            old.copyWith(memberCount: old.memberCount + 1);
      }
    }

  } catch (e) {
    AppLogger.info("[community]ERROR APPROVE: $e");
  }
}
//   Future<void> approve(int userId) async {
//   try {
//     await _repo.approve(communityId, userId);

//     pendingMembers.removeWhere((e) => e.userSysId == userId);
//     pendingMembers.refresh();

//     if (Get.isRegistered<CommunityDetailController>()) {
//       final detailController = Get.find<CommunityDetailController>();

//       if (detailController.community.value != null) {
//         final old = detailController.community.value!;
//         detailController.community.value =
//             old.copyWith(memberCount: old.memberCount + 1);
//       }
//     }

//     if (Get.isRegistered<CommunityController>()) {
//       final commuController = Get.find<CommunityController>();

//       final index = commuController.communities.indexWhere(
//         (c) => c.communityId == communityId,
//       );

//       if (index != -1) {
//         final old = commuController.communities[index];

//         commuController.communities[index] =
//             old.copyWith(memberCount: old.memberCount + 1);

//         commuController.communities.refresh();
//       }
//     }

//   } catch (e) {
//     print("ERROR APPROVE: $e");
//   }
// }

  // Future<void> approve(int userId) async {
  //   try {
  //     await _repo.approve(communityId, userId);

  //     final index = pendingMembers.indexWhere((e) => e.userSysId == userId);

  //     if (index != -1) {
  //       final old = pendingMembers[index];

  //       pendingMembers[index] = CommunityMemberModel(
  //         userSysId: old.userSysId,
  //         firstName: old.firstName,
  //         lastName: old.lastName,
  //         profilePic: old.profilePic,
  //         status: 'active',
  //       );
  //     }
  //   } catch (e) {
  //     print("ERROR APPROVE: $e");
  //   }
  // }


  Future<void> reject(int userId) async {
    try {
      await _repo.reject(communityId, userId);

      pendingMembers.removeWhere((e) => e.userSysId == userId);
    } catch (e) {
      AppLogger.info("[community]ERROR REJECT: $e");
    }
  }
}
