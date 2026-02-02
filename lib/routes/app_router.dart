import 'package:LinkLian/features/profile/bindings/profile_binding.dart';
import 'package:LinkLian/main.dart';
import 'package:get/get.dart';
import '../config/app_routes.dart';
import '../features/assignment/pages/assignment_page.dart';
import '../features/community/pages/community_page.dart';
import '../features/profile/pages/profile_page.dart';
import '../features/layout/pages/layout.dart';
import '../features/login/pages/login_page.dart';
import '../features/classes/bindings/class_feed_binding.dart';
import '../features/classes/pages/class_detail_page.dart';
import '../features/classes/bindings/class_detail_binding.dart';
import '../features/classes/pages/create_post_class_page.dart';
import '../features/classes/controllers/create_post_controller.dart';
import '../data/repository/post_repository.dart';
import '../features/classes/pages/comment_page.dart';
import '../features/classes/bindings/comment_binding.dart';
import '../features/profile/bindings/bookmark_binding.dart';
import '../features/classes/pages/search_post_page.dart';


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
      transition: Transition.noTransition, // No animation for tab switching
    ),
     GetPage(
      name: AppRoutes.classDetail,
      page: () => const ClassDetailPage(),
      bindings: [
        ClassDetailBinding(),
        BookmarkBinding(),
      ],
      // Use right to left transition for normal navigation
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: AppRoutes.createPost,
      page: () => const CreatePostClassPage(),
      binding: BindingsBuilder(() {
        Get.put(CreatePostController(
          postRepository: PostRepository(),
        ));
      }),
    ),
    GetPage(
      name: AppRoutes.comment,
      page: () => const CommentPage(),
      binding: CommentBinding(),
    ),
    GetPage(
      name: AppRoutes.searchPost,
      page: () => const SearchPostPage(),
    ),
    GetPage(name: AppRoutes.community, page: () => const CommuPage()),
    GetPage(
      name: AppRoutes.profile,
      page: () => const ProfilePage(),
      binding: ProfileBinding(),
    ),
  ];
}
