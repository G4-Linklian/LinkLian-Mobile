import '../../features/auth/controller/auth_controller.dart';
import '../../../data/model/post_model.dart';

class PostPermission {
  final PostModel post;
  final AuthController auth;

  PostPermission({required this.post, required this.auth});

  bool get isOwner => post.userSysId == auth.userId.value;

  bool get isTeacher =>
      auth.roleName.value == 'teacher' || auth.roleName.value == 'instructor';

  bool get isAdmin => auth.roleName.value == 'admin';

  bool get isStudent =>
      auth.roleName.value == 'high school student' ||
      auth.roleName.value == 'uni student';

  /// CRUD
  bool get canEdit => isOwner || isAdmin;
  bool get canDelete => isOwner || isAdmin;

  /// UI / Feature
  bool get canSelectAI => isStudent;
  bool get canReport => !isOwner;
  bool get canShowMore => canEdit || canDelete || canReport;
}
