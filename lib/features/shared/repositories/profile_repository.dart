import 'dart:io';
import 'package:dio/dio.dart';
import '../models/profile_model.dart';
import '../../../core/services/api_client.dart';

class ProfileRepository {
  final ApiClient api;

  ProfileRepository(this.api);

  /// Get /profile/:userId
  Future<ProfileModel> getProfile(int userId) async {
    final res = await api.get('/profile/$userId');

    return ProfileModel.fromJson(res.data['data']);
  }

  /// Post /profile/:userId
  Future<void> updateProfile(
    int userId, {
    required String firstName,
    String? middleName,
    required String lastName,
    String? phone,
    String? profilePic,
    bool clearProfilePic = false,
  }) async {
    final Map<String, dynamic> data = {
      'first_name': firstName,
      'last_name': lastName,
    };

    if (middleName != null) {
      data['middle_name'] = middleName;
    }

    if (phone != null) {
      data['phone'] = phone;
    }

    if (clearProfilePic) {
      data['profile_pic'] = null;
    } else if (profilePic != null) {
      data['profile_pic'] = profilePic;
    }

    await api.put('/profile/$userId', data: data);
  }

  //ดึงมาจาก uploadfile
  Future<String> uploadAvatar(int userId, File file) async {
    final formData = FormData.fromMap({
      'files': await MultipartFile.fromFile(
        file.path,
        filename: file.path.split('/').last,
      ),
    });

    final res = await api.post(
      '/uploadFile/user/profile-upload',
      data: formData,
    );

    return res.data['files'][0]['fileUrl'];
  }

  Future<void> deleteAvatar(String fileUrl) async {
    final uri = Uri.parse(fileUrl);
    final pathSegments = uri.pathSegments;

    if (pathSegments.length < 2) {
      throw Exception('Invalid file URL format: $fileUrl');
    }

    final fileName = pathSegments.skip(1).join('/');

    await api.delete(
      '/deleteFile/user',
      data: {
        'fileNames': [fileName],
      },
    );
  }
}
