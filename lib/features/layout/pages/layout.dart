import 'package:LinkLian/config/app_routes.dart';
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

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _selectedIndex = 1;
  final AuthController _auth = Get.find<AuthController>();

  bool get isStudent {
    final role = _auth.roleName.value;
    return role == 'high school student' || role == 'uni student';
  }

  @override
  void initState() {
    super.initState();

    _selectedIndex = 1; // ClassesPage ทั้ง student และ teacher


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

  List<Widget> get _pages {
    if (isStudent) {
      return const [
        AssignmentPage(),
        ClassesPage(),
        CommuPage(),
        ProfilePage(),
      ];
    } else {
      return const [AssignmentPage(), ClassesPage(), ProfilePage()];
    }
  }

  bool get _hideAddIcon {
    if (isStudent) {
      // student: แสดงเฉพาะ class (1) และ community (2)
      return !(_selectedIndex == 1 || _selectedIndex == 2);
    } else {
      // teacher: แสดงเฉพาะ assignment (0) และ class (1)
      return !(_selectedIndex == 0 || _selectedIndex == 1);
    }
  }

  bool get _hideAppBar =>
      (!isStudent && _selectedIndex == 2) || (isStudent && _selectedIndex == 3);

  @override
  Widget build(BuildContext context) {
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
                        if (_selectedIndex == 1) {
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
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        // onTap: (index) {
        //   if (
        //     (isStudent && index == 3) ||
        //     (!isStudent && index == 2)
        //   ) {
        //     // 👉 เปิด Profile ผ่าน route
        //     Get.toNamed(AppRoutes.profile);
        //     return;
        //   }
        //   setState(() {
        //     _selectedIndex = index;
        //   });
        // },
        onTap: (index) {
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
  }
}
