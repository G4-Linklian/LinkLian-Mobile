import 'dart:io';
import 'package:dio/dio.dart';
import '../model/profile_model.dart';


class ProfileRepository {
  final Dio dio;

  ProfileRepository(this.dio);

  /// GET /profile/:userId
  Future<ProfileModel> getProfile(int userId) async {
    final res = await dio.get('/profile/$userId');
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
    await dio.put(
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

    final res = await dio.post(
      '/profile/$userId/avatar',
      data: formData,
    );

    return res.data['avatar_url'];
  }
}
