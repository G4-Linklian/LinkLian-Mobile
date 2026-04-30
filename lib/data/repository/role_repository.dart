import 'package:LinkLian/core/utils/logger.dart';

import '../../core/services/api_client.dart';
import '../model/role_model.dart';

class RoleRepository {
  final ApiClient _apiClient = ApiClient();

  /// GET ROLE (dynamic filter)
  Future<List<RoleModel>> getRoles({
    int? roleId,
    String? roleName,
    String? roleType,
    Map<String, dynamic>? access,
    bool? flagValid,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) async {
    final Map<String, dynamic> body = {};

    if (roleId != null) body['role_id'] = roleId;
    if (roleName != null) body['role_name'] = roleName;
    if (roleType != null) body['role_type'] = roleType;
    if (access != null) body['access'] = access;
    if (flagValid != null) body['flag_valid'] = flagValid;
    if (createdAt != null) {
      body['created_at'] = createdAt.toLocal().toIso8601String();
    }
    if (updatedAt != null) {
      body['updated_at'] = updatedAt.toLocal().toIso8601String();
    }

    final response = await _apiClient.post<Map<String, dynamic>>(
      '/role.get',
      data: body,
    );

    if (response.statusCode == 200 && response.data != null) {
      final list = response.data!['data'] as List;

      appLog.info('Fetched roles count: ${list.length}');

      return list
          .map((e) => RoleModel.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    }

    throw Exception('Failed to fetch roles');
  }

  /// CREATE ROLE
  Future<List<RoleModel>> createRole({
    required String roleName,
    required String roleType,
    required Map<String, dynamic> access,
    bool flagValid = true,
  }) async {
    final response = await _apiClient.post<Map<String, dynamic>>(
      '/role.create',
      data: {
        'role_name': roleName,
        'role_type': roleType,
        'access': access,
        'flag_valid': flagValid,
      },
    );

    if (response.statusCode == 201 && response.data != null) {
      final list = response.data!['data'] as List;

      return list
          .map((e) => RoleModel.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    }

    throw Exception('Failed to create role');
  }

  /// UPDATE ROLE
  Future<List<RoleModel>> updateRole({
    required int roleId,
    String? roleName,
    String? roleType,
    Map<String, dynamic>? access,
    bool? flagValid,
  }) async {
    final Map<String, dynamic> body = {'role_id': roleId};

    if (roleName != null) body['role_name'] = roleName;
    if (roleType != null) body['role_type'] = roleType;
    if (access != null) body['access'] = access;
    if (flagValid != null) body['flag_valid'] = flagValid;

    final response = await _apiClient.post<Map<String, dynamic>>(
      '/role.update',
      data: body,
    );

    if (response.statusCode == 200 && response.data != null) {
      final list = response.data!['data'] as List;

      return list
          .map((e) => RoleModel.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    }

    throw Exception('Failed to update role');
  }
}
