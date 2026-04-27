import 'package:LinkLian/config/app_routes.dart';
import 'package:LinkLian/core/services/api_client.dart';
import 'package:LinkLian/features/chat/presentation/controllers/chat.controller.dart';
import 'package:LinkLian/features/community/data/repositories/community_member_repository.dart';
import 'package:LinkLian/features/community/data/repositories/community_post_repository.dart';
import 'package:LinkLian/features/community/data/repositories/community_repository.dart';
import 'package:LinkLian/features/shared/repositories/profile_repository.dart';
import 'package:LinkLian/features/profile/data/repositories/teaching_schedule_repository.dart';
import 'package:LinkLian/features/profile/data/repositories/report_repository.dart';
import 'package:LinkLian/features/community/presentation/controllers/community_controller.dart';
import 'package:LinkLian/features/community/presentation/controllers/community_detail_controller.dart';
import 'package:LinkLian/features/community/presentation/pages/community_detail_page.dart';
import 'package:LinkLian/features/profile/presentation/controllers/profile_controller.dart';
import 'package:flutter/material.dart';
import '../../../../core/constants/colors.dart';
import '../../../../features/assignment/presentation/pages/assignment_page.dart';
import '../../../features/assignment/presentation/pages/class_assignment_page.dart';
import '../../classes/presentation/pages/classes_page.dart';
import '../../community/presentation/pages/community_page.dart';
import '../../profile/presentation/pages/profile_page.dart';
import '../../../../core/constants/linklian-icon.dart';
import '../../../core/constants/strings.dart';
import '../../../core/constants/sizes.dart';
import '../../../core/constants/logo.dart';
import '../widgets/activeIcon.dart';
import '../../notification/presentation/pages/notification_page.dart';
import '../../notification/presentation/bindings/notification_binding.dart';
import '../../../../core/services/badge_service.dart';
import '../../chat/presentation/pages/chat.page.dart';
import '../../chat/services/chat_badge_service.dart';
import '../../auth/controller/auth_controller.dart';
import 'package:get/get.dart';
import '../../classes/presentation/controllers/class_feed_controller.dart';
import '../../shared/repositories/class_feed_repository.dart';
import '../../../data/repository/semester_repository.dart';
import '../controllers/navigation_controller.dart';
import '../../classes/presentation/pages/class_detail_page.dart';
import '../../classes/presentation/controllers/create_post_controller.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _selectedIndex = 1;
  final AuthController _auth = Get.find<AuthController>();
  final NavigationController _navController = Get.find<NavigationController>();

  bool get isStudent {
    final role = _auth.roleName.value;
    return role == 'high school student' || role == 'uni student';
  }

  @override
  void initState() {
    super.initState();

    final args = Get.arguments;
    if (args is Map && args.containsKey('selectedIndex')) {
      _selectedIndex = args['selectedIndex'] as int;
    } else {
      _selectedIndex = 1;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      _navController.selectedIndex.value = _selectedIndex;
      final chats = await ChatController().getChat();
      int total = 0;
      for (final chat in chats) {
        if (chat.unreadCount != null) {
          total += chat.unreadCount!;
        }
      }
      ChatBadgeService().set(total);
    });

    _registerDependencies();

    ever<String?>(_auth.roleName, (role) {
      if (role == null) return;

      final isStudentRole =
          role == 'high school student' || role == 'uni student';

      _navController.resetForRoleChange(isStudentRole);
    });
  }

  void _registerDependencies() {
    if (!Get.isRegistered<ClassFeedController>()) {
      Get.put<ClassFeedController>(
        ClassFeedController(
          classFeedRepository: Get.find<ClassFeedRepository>(),
          semesterRepository: Get.find<SemesterRepository>(),
        ),
        permanent: true,
      );
    }
    if (!Get.isRegistered<ProfileRepository>()) {
      Get.put(ProfileRepository(Get.find<ApiClient>()), permanent: true);
    }
    if (!Get.isRegistered<TeachingScheduleRepository>()) {
      Get.put(
        TeachingScheduleRepository(Get.find<ApiClient>()),
        permanent: true,
      );
    }
    if (!Get.isRegistered<ReportRepository>()) {
      Get.put(ReportRepository(Get.find<ApiClient>()), permanent: true);
    }
    if (!Get.isRegistered<ProfileController>()) {
      Get.put(
        ProfileController(
          Get.find<ProfileRepository>(),
          Get.find<TeachingScheduleRepository>(),
        ),
        permanent: true,
      );
    }
    if (!Get.isRegistered<CommunityRepository>()) {
      Get.put(CommunityRepository(), permanent: true);
    }
    if (!Get.isRegistered<CommunityPostRepository>()) {
      Get.put(CommunityPostRepository(), permanent: true);
    }
    if (!Get.isRegistered<CommunityMemberRepository>()) {
      Get.put(CommunityMemberRepository(), permanent: true);
    }
    if (!Get.isRegistered<CommunityDetailController>()) {
      Get.put(
        CommunityDetailController(
          Get.find<CommunityRepository>(),
          Get.find<CommunityPostRepository>(),
          Get.find<CommunityMemberRepository>(),
        ),
        permanent: true,
      );
    }
    if (!Get.isRegistered<CommunityController>()) {
      Get.put(
        CommunityController(Get.find<CommunityRepository>()),
        permanent: true,
      );
    }
  }

  void _goTo(Widget page) {
    Navigator.push(context, MaterialPageRoute(builder: (context) => page));
  }

  Widget _getPageForIndex(int index) {
    if (isStudent) {
      switch (index) {
        case 0:
          return const AssignmentPage();
        case 2:
          return const CommuPage();
        case 3:
          return const ProfilePage();
        default:
          return const SizedBox.shrink();
      }
    } else {
      switch (index) {
        case 0:
          return const AssignmentPage();
        case 2:
          return const ProfilePage();
        default:
          return const SizedBox.shrink();
      }
    }
  }

  bool get _hideAddIcon {
    if (_navController.isShowingClassDetail.value && _selectedIndex == 1) {
      return true;
    }
    if (isStudent) {
      return !(_selectedIndex == 1 || _selectedIndex == 2);
    } else {
      return !(_selectedIndex == 0 || _selectedIndex == 1);
    }
  }

  bool get _hideAppBar {
    if (_navController.isShowingClassDetail.value && _selectedIndex == 1) {
      return true;
    }
    if (_navController.isShowingCommunityDetail.value && _selectedIndex == 2) {
      return true;
    }
    if (_navController.isShowingClassAssignment.value && _selectedIndex == 0) {
      return true;
    }
    return (!isStudent && _selectedIndex == 2) ||
        (isStudent && _selectedIndex == 3);
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final currentTab = _navController.selectedIndex.value;
      final showClassDetail =
          _navController.isShowingClassDetail.value && currentTab == 1;
      final showCommunityDetail =
          _navController.isShowingCommunityDetail.value && currentTab == 2;
      final showClassAssignment =
          _navController.isShowingClassAssignment.value && currentTab == 0;

      if (_selectedIndex != currentTab) {
        _selectedIndex = currentTab;
      }

      return Scaffold(
        appBar: _hideAppBar
            ? null
            : AppBar(
                backgroundColor: AppColors.white,
                elevation: 0,
                titleSpacing: AppSizes.md,
                title: Row(
                  children: [
                    Image.asset(
                      LinkLianLogos.bannerBlack,
                      height: 25,
                      fit: BoxFit.contain,
                    ),
                    const Spacer(),
                    if (!_hideAddIcon)
                      GestureDetector(
                        onTap: () {
                          if (_selectedIndex == 0) {
                            Get.toNamed(
                              AppRoutes.createPost,
                              arguments: {
                                'mode': CreatePostMode.create,
                                'source': CreatePostSource.assignmentFeed,
                                'postType': 'assignment',
                                'lockPostType': true,
                              },
                            );
                          } else if (_selectedIndex == 1) {
                            Get.toNamed(
                              AppRoutes.createPost,
                              arguments: {
                                'mode': CreatePostMode.create,
                                'source': CreatePostSource.classFeed,
                              },
                            );
                          } else if (_selectedIndex == 2) {
                            Get.toNamed(AppRoutes.createCommunity);
                          }
                        },
                        child: Icon(
                          LinkLianIcon.add,
                          color: AppColors.primaryPalette[500],
                          size: 32,
                        ),
                      ),
                    if (!_hideAddIcon) const SizedBox(width: 12),
                    Obx(() {
                      final count = BadgeService().observe(BadgeFeature.general).value;
                      return GestureDetector(
                        onTap: () => Get.to(
                          () => const NotificationPage(),
                          binding: NotificationBinding(),
                        ),
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Icon(
                              LinkLianIcon.notification,
                              color: AppColors.warningPalette[500],
                              size: 32,
                            ),
                            if (count > 0)
                              Positioned(
                                top: -4,
                                right: -6,
                                child: Container(
                                  constraints: const BoxConstraints(
                                    minWidth: 16,
                                    minHeight: 16,
                                  ),
                                  padding: const EdgeInsets.symmetric(horizontal: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.red,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: Colors.white, width: 1.5),
                                  ),
                                  child: Text(
                                    count > 99 ? '99+' : count.toString(),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 9,
                                      fontWeight: FontWeight.w700,
                                      height: 1.4,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      );
                    }),
                    const SizedBox(width: 12),
                    GestureDetector(
                      onTap: () => _goTo(const ChatPage()),
                      child: Icon(
                        LinkLianIcon.message,
                        color: AppColors.successPalette[500],
                        size: 30,
                      ),
                    ),
                    // TODO(chat-team): badge จำนวนแชทที่ยังไม่อ่าน
                    // Obx(() {
                    //   final count = BadgeService().observe(BadgeFeature.chat).value;
                    //   if (count == 0) return const SizedBox.shrink();
                    //   return Positioned(
                    //     top: -4,
                    //     right: -6,
                    //     child: Container(
                    //       constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                    //       padding: const EdgeInsets.symmetric(horizontal: 4),
                    //       decoration: BoxDecoration(
                    //         color: Colors.red,
                    //         borderRadius: BorderRadius.circular(10),
                    //         border: Border.all(color: Colors.white, width: 1.5),
                    //       ),
                    //       child: Text(
                    //         count > 99 ? '99+' : count.toString(),
                    //         style: const TextStyle(
                    //           color: Colors.white,
                    //           fontSize: 9,
                    //           fontWeight: FontWeight.w700,
                    //           height: 1.4,
                    //         ),
                    //         textAlign: TextAlign.center,
                    //       ),
                    //     ),
                    //   );
                    // }),
                    Obx(() => Stack(
                      clipBehavior: Clip.none,
                      children: [
                        GestureDetector(
                          onTap: () async {
                            _goTo(const ChatPage());
                            final chats = await ChatController().getChat();
                            int total = 0;
                            for (final chat in chats) {
                              if (chat.unreadCount != null) {
                                total += chat.unreadCount!;
                              }
                            }
                            ChatBadgeService().set(total);
                          },
                          child: Icon(
                            LinkLianIcon.message,
                            color: AppColors.successPalette[500],
                            size: 30,
                          ),
                        ),
                        if (ChatBadgeService().observe().value > 0)
                          Positioned(
                            top: -4,
                            right: -6,
                            child: Container(
                              constraints: const BoxConstraints(
                                minWidth: 16,
                                minHeight: 16,
                              ),
                              padding: const EdgeInsets.symmetric(horizontal: 4),
                              decoration: BoxDecoration(
                                color: Colors.red,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: Colors.white, width: 1.5),
                              ),
                              child: Text(
                                ChatBadgeService().observe().value > 99
                                    ? '99+'
                                    : ChatBadgeService().observe().value.toString(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                  height: 1.4,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                      ],
                    )),
                  ],
                ),
              ),
        body: _buildBody(
          showClassDetail: showClassDetail,
          showCommunityDetail: showCommunityDetail,
          showClassAssignment: showClassAssignment,
          currentTab: currentTab,
        ),
        bottomNavigationBar: _buildBottomNav(currentTab),
      );
    });
  }

  Widget _buildBody({
    required bool showClassDetail,
    required bool showCommunityDetail,
    required bool showClassAssignment,
    required int currentTab,
  }) {
    return KeyedSubtree(
      key: ValueKey(currentTab),
      child: Builder(
        builder: (_) {
          // TAB 1: ClassesPage + ClassDetailPage overlay
          if (currentTab == 1) {
            return Stack(
              children: [
                const ClassesPage(key: ValueKey('classesPage')),
                _buildSlideOverlay(
                  isVisible: showClassDetail,
                  child: const ClassDetailPage(key: ValueKey('classDetail')),
                ),
              ],
            );
          }

          // TAB 2: CommunityPage + CommunityDetailPage overlay
          if (currentTab == 2 && isStudent) {
            return Stack(
              children: [
                const CommuPage(key: ValueKey('communityPage')),
                _buildSlideOverlay(
                  isVisible: showCommunityDetail,
                  child: const CommunityDetailPage(key: ValueKey('communityDetail')),
                ),
              ],
            );
          }

          // TAB 0: AssignmentPage + ClassAssignmentPage overlay
          if (currentTab == 0) {
            return Stack(
              children: [
                const AssignmentPage(key: ValueKey('assignmentPage')),
                _buildSlideOverlay(
                  isVisible: showClassAssignment,
                  child: const ClassAssignmentPage(key: ValueKey('classAssignment')),
                ),
              ],
            );
          }

          return _getPageForIndex(currentTab);
        },
      ),
    );
  }

  Widget _buildSlideOverlay({
    required bool isVisible,
    required Widget child,
  }) {
    return IgnorePointer(
      ignoring: !isVisible,
      child: AnimatedSlide(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        offset: isVisible ? Offset.zero : const Offset(1.0, 0.0),
        child: child,
      ),
    );
  }

  Widget? _buildBottomNav(int currentTab) {
    final maxIndex = isStudent ? 3 : 2;
    final safeIndex = currentTab > maxIndex ? 1 : currentTab;

    return BottomNavigationBar(
      currentIndex: safeIndex,
      onTap: (index) {
        _navController.changeTab(index);
        setState(() => _selectedIndex = index);
      },
      type: BottomNavigationBarType.fixed,
      selectedItemColor: AppColors.primaryPalette[900],
      unselectedItemColor: AppColors.primaryPalette[800],
      backgroundColor: AppColors.primaryPalette[200],
      selectedFontSize: 12,
      unselectedFontSize: 12,
      items: isStudent
          ? const [
              BottomNavigationBarItem(
                icon: Icon(LinkLianIcon.homework),
                activeIcon: ActiveNavIcon(icon: LinkLianIcon.homework),
                label: AppStrings.homework,
              ),
              BottomNavigationBarItem(
                icon: Icon(LinkLianIcon.classroom),
                activeIcon: ActiveNavIcon(icon: LinkLianIcon.classroom),
                label: AppStrings.classroom,
              ),
              BottomNavigationBarItem(
                icon: Icon(LinkLianIcon.community),
                activeIcon: ActiveNavIcon(icon: LinkLianIcon.community),
                label: AppStrings.community,
              ),
              BottomNavigationBarItem(
                icon: Icon(LinkLianIcon.profile),
                activeIcon: ActiveNavIcon(icon: LinkLianIcon.profile),
                label: AppStrings.profile,
              ),
            ]
          : const [
              BottomNavigationBarItem(
                icon: Icon(LinkLianIcon.homework),
                activeIcon: ActiveNavIcon(icon: LinkLianIcon.homework),
                label: AppStrings.homework,
              ),
              BottomNavigationBarItem(
                icon: Icon(LinkLianIcon.classroom),
                activeIcon: ActiveNavIcon(icon: LinkLianIcon.classroom),
                label: AppStrings.classroom,
              ),
              BottomNavigationBarItem(
                icon: Icon(LinkLianIcon.profile),
                activeIcon: ActiveNavIcon(icon: LinkLianIcon.profile),
                label: AppStrings.profile,
              ),
            ],
    );
  }
}
