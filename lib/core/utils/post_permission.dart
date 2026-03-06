import '../../features/auth/controller/auth_controller.dart';
import '../../features/shared/models/post_model.dart';

class PostPermission {
  final PostModel post;
  final AuthController auth;

  PostPermission({required this.post, required this.auth});

  int get _currentUserId => auth.userId.value ?? 0;

  /// โพสต์เป็นของตัวเองหรือไม่
  bool get _isOwner => post.userSysId == _currentUserId;

  /// แสดงปุ่ม ... เฉพาะเจ้าของโพสต์เท่านั้น
  bool get canShowMore => _isOwner;

  /// แก้ไขได้เฉพาะเจ้าของโพสต์
  bool get canEdit => _isOwner;

  /// ลบได้เฉพาะเจ้าของโพสต์
  bool get canDelete => _isOwner;
}
