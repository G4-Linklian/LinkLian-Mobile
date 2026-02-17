import 'package:LinkLian/features/community/binding/community_binding.dart';
import 'package:LinkLian/features/community/binding/community_detail_binding.dart';
import 'package:LinkLian/features/community/binding/community_member_binding.dart';
import 'package:LinkLian/features/community/binding/community_pending_binding.dart';
import 'package:LinkLian/features/community/binding/create_community_binding.dart';
import 'package:LinkLian/features/community/binding/create_post_community_binding.dart';
import 'package:LinkLian/features/community/controllers/community_comment_controller.dart';
import 'package:LinkLian/features/community/pages/community_comment_page.dart';
import 'package:LinkLian/features/community/pages/community_detail_page.dart';
import 'package:LinkLian/features/community/pages/community_member_page.dart';
import 'package:LinkLian/features/community/pages/community_pending_page.dart';
import 'package:LinkLian/features/community/pages/community_search_page.dart';
import 'package:LinkLian/features/community/pages/create_community_page.dart';
import 'package:LinkLian/features/community/pages/create_post_commu_page.dart';
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
import '../features/assignment/pages/class_assignment_page.dart';
import '../features/assignment/bindings/class_assignment_binding.dart';
import '../features/assignment/pages/assignment_submission_page.dart';
import '../features/assignment/bindings/assignment_submission_binding.dart';
import '../features/classes/controllers/search_post_controller.dart';

class AppRouter {
  static final routes = [
    GetPage(name: AppRoutes.authGate, page: () => const AuthGate()),
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
      bindings: [ClassDetailBinding(), BookmarkBinding()],
      // Use right to left transition for normal navigation
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: AppRoutes.createPost,
      page: () => const CreatePostClassPage(),
      binding: BindingsBuilder(() {
        Get.put(CreatePostController(postRepository: PostRepository()));
      }),
    ),
    GetPage(
      name: AppRoutes.comment,
      page: () => const CommentPage(),
      binding: CommentBinding(),
    ),
    GetPage(
      name: '/search-post',
      page: () => const SearchPostPage(),
      binding: BindingsBuilder(() {
        Get.lazyPut<SearchPostController>(() => SearchPostController());
      }),
    ),
    GetPage(
      name: AppRoutes.classAssignment,
      page: () => const ClassAssignmentPage(),
      binding: ClassAssignmentBinding(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: AppRoutes.assignmentSubmission,
      page: () => const AssignmentSubmissionPage(),
      binding: AssignmentSubmissionBinding(),
      transition: Transition.rightToLeft,
    ),

    GetPage(
      name: AppRoutes.community,
      page: () => const CommuPage(),
      binding: CommunityBinding(),
    ),
    GetPage(
      name: AppRoutes.createCommunity,
      page: () => const CreateCommunityPage(),
      binding: CreateCommunityBinding(),
    ),
    GetPage(
      name: AppRoutes.communityDetail,
      page: () => const CommunityDetailPage(),
      binding: CommunityDetailBinding(),
    ),
    GetPage(
      name: AppRoutes.createPostCommunity,
      page: () => const CreatePostCommunityPage(),
      binding: CreatePostCommunityBinding(),
    ),
    GetPage(
      name: AppRoutes.communityComment,
      page: () => const CommunityCommentPage(),
      binding: BindingsBuilder(() {
        Get.put(CommunityCommentController());
      }),
    ),
    GetPage(
      name: '/community-members',
      page: () => const CommunityMemberPage(),
      binding: CommunityMemberBinding(),
    ),
    GetPage(
      name: '/community-pending',
      page: () => const CommunityPendingPage(),
      binding: CommunityPendingBinding(),
    ),
    GetPage(
      name: AppRoutes.communitySearch,
      page: () => const CommunitySearchPage(),
    ),

    GetPage(
      name: AppRoutes.profile,
      page: () => const ProfilePage(),
      binding: ProfileBinding(),
    ),
  ];
}
