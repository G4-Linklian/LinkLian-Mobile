import 'package:LinkLian/core/services/api_client.dart';
import 'package:LinkLian/data/repository/profile_repository.dart';
import 'package:LinkLian/data/repository/teaching_schedule_repository.dart';
import 'package:LinkLian/features/profile/controllers/profile_controller.dart';
import 'package:flutter/material.dart';
import '../../../core/constants/colors.dart';
import '../../assignment/pages/assignment_page.dart';
import '../../classes/pages/classes_page.dart';
import '../../community/pages/community_page.dart';
import '../../profile/pages/profile_page.dart';
import '../../../core/constants/linklian-icon.dart';
import '../../../core/constants/strings.dart';
import '../../../core/constants/sizes.dart';
import '../../../core/constants/logo.dart';
import '../widgets/activeIcon.dart';
import '../../classes/pages/create_post_class_page.dart';
import '../../community/pages/create_post_commu_page.dart';
import '../../notification/pages/notification_page.dart';
import '../../chat/pages/chat.page.dart';
import '../../auth/controller/auth_controller.dart';
import 'package:get/get.dart';
import '../../classes/controllers/class_feed_controller.dart';
import '../../../data/repository/class_feed_repository.dart';
import '../../../data/repository/semester_repository.dart';
import '../../classes/bindings/create_post_binding.dart';
import '../controllers/navigation_controller.dart';
import '../../classes/pages/class_detail_page.dart';
import '../../classes/controllers/create_post_controller.dart';
import '../../../config/app_routes.dart';

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

    // Check if navigated with selectedIndex argument
    final args = Get.arguments;
    if (args is Map && args.containsKey('selectedIndex')) {
      _selectedIndex = args['selectedIndex'] as int;
    } else {
      _selectedIndex = 1; // ClassesPage ทั้ง student และ teacher
    }

    // Sync with NavigationController
  WidgetsBinding.instance.addPostFrameCallback((_) {
    _navController.selectedIndex.value = _selectedIndex;
  });

  
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
    if (!Get.isRegistered<ProfileRepository>()) {
      Get.put(ProfileRepository(Get.find<ApiClient>()), permanent: true);
    }
    if (!Get.isRegistered<TeachingScheduleRepository>()) {
      Get.put(
        TeachingScheduleRepository(Get.find<ApiClient>()),
        permanent: true,
      );
    }

    //2. แล้วค่อย put Controller
    if (!Get.isRegistered<ProfileController>()) {
      Get.put(
        ProfileController(
          Get.find<ProfileRepository>(),
          Get.find<TeachingScheduleRepository>(),
        ),
        permanent: true,
      );
    }
  }

  void _goTo(Widget page) {
    Navigator.push(context, MaterialPageRoute(builder: (context) => page));
  }

  /// Get page widget for given index (excluding class tab which is handled separately)
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
    // Hide add icon when showing class detail (it has its own)
    if (_navController.isShowingClassDetail.value && _selectedIndex == 1) {
      return true;
    }

    if (isStudent) {
      // student: แสดงเฉพาะ class (1) และ community (2)
      return !(_selectedIndex == 1 || _selectedIndex == 2);
    } else {
      // teacher: แสดงเฉพาะ assignment (0) และ class (1)
      return !(_selectedIndex == 0 || _selectedIndex == 1);
    }
  }

  bool get _hideAppBar {
    // Hide app bar when showing class detail (it has its own header)
    if (_navController.isShowingClassDetail.value && _selectedIndex == 1) {
      return true;
    }
    return (!isStudent && _selectedIndex == 2) ||
        (isStudent && _selectedIndex == 3);
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final showClassDetail =
          _navController.isShowingClassDetail.value &&
          _navController.selectedIndex.value == 1;

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
                                'source': CreatePostSource.classFeed,

                                // 🔒 บังคับเป็นการบ้าน
                                'postType': 'assignment',
                                'lockPostType': true,
                              },
                            );
                          } else if (_selectedIndex == 1) {
                            Get.to(
                              () => const CreatePostClassPage(),
                              binding: CreatePostBinding(),
                            );
                          } else if (_selectedIndex == 2) {
                            _goTo(const CreatePostCommuPage());
                          }
                        },
                        child: Icon(
                          LinkLianIcon.add,
                          color: AppColors.primaryPalette[500],
                          size: 32,
                        ),
                      ),

                    if (!_hideAddIcon) const SizedBox(width: 12),

                    GestureDetector(
                      onTap: () => _goTo(const NotificationPage()),
                      child: Icon(
                        LinkLianIcon.notification,
                        color: AppColors.warningPalette[500],
                        size: 32,
                      ),
                    ),

                    const SizedBox(width: 12),

                    GestureDetector(
                      onTap: () => _goTo(const ChatPage()),
                      child: Icon(
                        LinkLianIcon.message,
                        color: AppColors.successPalette[500],
                        size: 30,
                      ),
                    ),
                  ],
                ),
              ),
        // Use AnimatedSwitcher for smooth transition between ClassesPage and ClassDetailPage
        body: _selectedIndex == 1
            ? AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                transitionBuilder: (child, animation) {
                  // Slide from right when showing ClassDetail, slide to right when hiding
                  final isShowingDetail = child is ClassDetailPage;
                  final slideAnimation =
                      Tween<Offset>(
                        begin: isShowingDetail
                            ? const Offset(1.0, 0.0) // Slide in from right
                            : const Offset(
                                -0.3,
                                0.0,
                              ), // Slide in from left (smaller)
                        end: Offset.zero,
                      ).animate(
                        CurvedAnimation(
                          parent: animation,
                          curve: Curves.easeOutCubic,
                        ),
                      );

                  return SlideTransition(
                    position: slideAnimation,
                    child: child,
                  );
                },
                child: showClassDetail
                    ? const ClassDetailPage(key: ValueKey('classDetail'))
                    : const ClassesPage(key: ValueKey('classesPage')),
              )
            : _getPageForIndex(_selectedIndex),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: (index) {
            _navController.changeTab(index);
            setState(() {
              _selectedIndex = index;
            });
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
        ),
      );
    });
  }
}
