import 'package:LinkLian/features/profile/bindings/profile_binding.dart';
import 'package:LinkLian/main.dart';
import 'package:get/get.dart';
import '../config/app_routes.dart';
import '../features/assignment/pages/assignment_page.dart';
import '../features/classes/pages/classes_page.dart';
import '../features/community/pages/community_page.dart';
import '../features/profile/pages/profile_page.dart';
import '../features/layout/pages/layout.dart';
import '../features/login/pages/login_page.dart';
import '../features/classes/bindings/class_feed_binding.dart';


class AppRouter {
  static final routes = [
    GetPage(
      name: AppRoutes.authGate,
      page: () => const AuthGate(),
    ),
    GetPage(name: AppRoutes.login, page: () => const LoginPage()),

    GetPage(
      name: AppRoutes.initial,
      // page: () => const LoginPage(),
      page: () => const MainPage(),
    ),
    GetPage(name: AppRoutes.assignment, page: () => const AssignmentPage()),
    GetPage(
      name: AppRoutes.home,
      page: () => const MainPage(),
      binding: ClassFeedBinding(),
    ),
    GetPage(name: AppRoutes.community, page: () => const CommuPage()),
    GetPage(
      name: AppRoutes.profile,
      page: () => const ProfilePage(),
      binding: ProfileBinding(),
    ),
  ];
}
