import 'package:get/get.dart';
import '../../../data/repository/role_repository.dart';
import '../../../data/model/role_model.dart';
import '../../../core/utils/dialog_helper.dart';
import '../../../core/utils/logger.dart';

class AssignmentController extends GetxController {
  var isLoading = false.obs;
  final RoleRepository _roleRepository = RoleRepository();
  // var role = Rxn<RoleModel>();
  var roles = <RoleModel>[].obs;
  var errorMessage = ''.obs;

  @override
  void onInit() {
    super.onInit();
      }

  Future<void> fetchRole({
    int? roleId,
    String? roleName,
    String? roleType,
    Map<String, dynamic>? access,
    bool? flagValid,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      final response = await _roleRepository.getRoles(
        roleId: roleId,
        roleName: roleName,
        roleType: roleType,
        access: access,
        flagValid: flagValid,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );

      roles.value = response;

      DialogHelper.showNotification(
        title: "Call role successfully!",
        message: null,
        type: NotificationType.success,
      );
    } catch (e) {
      // Handle error
      DialogHelper.showNotification(
        title: "Failed to call role",
        message: e.toString(),
        type: NotificationType.error,
      );
      AppLogger.error('Error fetching role: $e');
      // throw Exception('Failed to fetch role');
      return;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> createRole({
    required String roleName,
    required String roleType,
    required Map<String, dynamic> access,
    bool flagValid = true,
  }) async {
    try {
      isLoading.value = true;
      roles.value = await _roleRepository.createRole(
        roleName: roleName,
        roleType: roleType,
        access: access,
        flagValid: flagValid,
      );
      DialogHelper.showNotification(
        title: "Create role successfully!",
        message: null,
        type: NotificationType.success,
      );
    } catch (e) {
      // Handle error
      DialogHelper.showNotification(
        title: "Failed to Create role",
        message: e.toString(),
        type: NotificationType.error,
      );
      AppLogger.error('Error creating role: $e');
      throw Exception('Failed to create role');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> updateRole({
    required int roleId,
    String? roleName,
    String? roleType,
    Map<String, dynamic>? access,
    bool? flagValid,
  }) async {
    try {
      isLoading.value = true;
      roles.value = await _roleRepository.updateRole(
        roleId: roleId,
        roleName: roleName,
        roleType: roleType,
        access: access,
        flagValid: flagValid,
      );
      DialogHelper.showNotification(
        title: "Update role successfully!",
        message: null,
        type: NotificationType.success,
      );
    } catch (e) {
      // Handle error
      DialogHelper.showNotification(
        title: "Failed to Update role",
        message: e.toString(),
        type: NotificationType.error,
      );
      AppLogger.error('Error updating role: $e');
      throw Exception('Failed to update role');
    } finally {
      isLoading.value = false;
    }
  }
}
