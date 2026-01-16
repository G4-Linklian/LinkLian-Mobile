import 'dart:io';
import 'package:dio/dio.dart';
import '../model/profile_model.dart';
import '../../core/services/api_client.dart';

class ProfileRepository {
  final ApiClient api;

  ProfileRepository(this.api);

  /// GET /profile/:userId
  Future<ProfileModel> getProfile(int userId) async {
    final res = await api.get(
      '/profile/$userId',
    );

    return ProfileModel.fromJson(res.data['data']);
  }

  /// PUT /profile/:userId
  Future<void> updateProfile(
    int userId, {
    required String firstName,
    String? middleName,
    required String lastName,
    String? phone,
  }) async {
    await api.put(
      '/profile/$userId',
      data: {
        'first_name': firstName,
        'middle_name': middleName,
        'last_name': lastName,
        'phone': phone,
      },
    );
  }

  /// POST /profile/:userId/avatar
  Future<String> uploadAvatar(int userId, File file) async {
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(file.path),
    });

    final res = await api.post(
      '/profile/$userId/avatar',
      data: formData,
    );

    return res.data['avatar_url'];
  }
}
