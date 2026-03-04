import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:LinkLian/data/model/community_model.dart';
import 'package:LinkLian/data/model/community_post_model.dart';
import 'package:LinkLian/data/repository/community_repository.dart';

enum JoinFilter { joined, notJoined }

class CommunityController extends GetxController {
  final CommunityRepository _repo;
  CommunityController(this._repo);

  final communities = <CommunityModel>[].obs;
  final posts = <CommunityPostModel>[].obs;
  final isLoading = false.obs;
  final selectedCommunity = Rxn<CommunityModel>();
  final searchController = TextEditingController();
  final searchKeyword = "".obs;

  final isFirstLoad = true.obs;

  final joinFilter = JoinFilter.joined.obs;

  @override
  void onInit() {
    super.onInit();

    loadCommunities();
  }

  @override
  void onReady() {
    super.onReady();

    if (communities.isEmpty && !isLoading.value) {
      loadCommunities();
    }
  }

  @override
  void onClose() {
    searchController.dispose();
    super.onClose();
  }

  Future<void> loadCommunities({String? keyword}) async {
    try {
      isLoading.value = true;

      final cleanKeyword = keyword?.trim();
      final result = await _repo.getCommunities(
        keyword: cleanKeyword == "" ? null : cleanKeyword,
      );

      if (cleanKeyword != null && cleanKeyword.isNotEmpty) {
        if (joinFilter.value == JoinFilter.joined) {
          communities.assignAll(
            result.where((c) => c.isMember || c.isPending).toList(),
          );
        } else {
          communities.assignAll(result.where((c) => c.isNone).toList());
        }
      } else {
        communities.assignAll(result);
      }
    } catch (e) {
      Get.snackbar(
        'ข้อผิดพลาด',
        'ไม่สามารถโหลดข้อมูลชุมชนได้',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  void resetSearch() {
    searchController.clear();
    searchKeyword.value = "";
    joinFilter.value = JoinFilter.joined;
    loadCommunities();
  }
}
