import 'package:get/get.dart';
import '../../data/models/community_member_model.dart';
import '../../data/repositories/community_member_repository.dart';

class CommunityMemberController extends GetxController {
  final CommunityMemberRepository _repo;

  CommunityMemberController(this._repo);

  final members = <CommunityMemberModel>[].obs;
  final isLoading = false.obs;

  late int communityId;

  @override
  void onInit() {
    super.onInit();
    communityId = Get.arguments['communityId'];
    loadMembers();
  }

  Future<void> loadMembers() async {
    try {
      isLoading.value = true;

      final result = await _repo.getMembers(communityId);

      members.assignAll(result);
    } catch (e) {
      // Error loading members - will show empty list
    } finally {
      isLoading.value = false;
    }
  }
}
