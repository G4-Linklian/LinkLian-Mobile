import 'package:get/get.dart';
import '../config/app_routes.dart';
import '../features/assignment/pages/assignment_page.dart';
import '../features/classes/pages/classes_page.dart';
import '../features/community/pages/community_page.dart';
import '../features/profile/pages/profile_page.dart';
import '../features/layout/pages/layout.dart';
import '../features/login/pages/login_page.dart';
class AppRouter {
  static final routes = [
    
    GetPage(
  name: AppRoutes.login,
  page: () => const LoginPage(),
),

    GetPage(
      name: AppRoutes.initial,
      // page: () => const LoginPage(),
      page: () => const MainPage(),
    ),
    GetPage(
      name: AppRoutes.assignment,
      page: () => const AssignmentPage(),
    ),
    GetPage(
      name: AppRoutes.classes,
      page: () => const ClassesPage(),
    ),
    GetPage(
      name: AppRoutes.community,
      page: () => const CommuPage(),
    ),
    GetPage(
      name: AppRoutes.profile,
      page: () => const ProfilePage(),
    ),
  ];
}
