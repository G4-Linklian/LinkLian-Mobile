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
import '../../chat/pages/chat_page.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _selectedIndex = 0;

  void _goTo(Widget page) {
    Navigator.push(context, MaterialPageRoute(builder: (context) => page));
  }

  final List<Widget> _pages = [
    const AssignmentPage(),
    const ClassesPage(),
    const CommuPage(),
    const ProfilePage(),
  ];

  bool get _hideAppBar => _selectedIndex == 3;
  bool get _hideAddIcon => _selectedIndex == 0;

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
                          _goTo(
                            const CreatePostClassPage(),
                          ); 
                        } else if (_selectedIndex == 2) {
                          _goTo(
                            const CreatePostCommuPage(),
                          );
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
        items: [
          BottomNavigationBarItem(
            icon: const Icon(LinkLianIcon.homework),
            // 2. เรียกใช้ Widget ใหม่ตรงนี้
            activeIcon: const ActiveNavIcon(icon: LinkLianIcon.homework),
            label: AppStrings.homework,
          ),
          BottomNavigationBarItem(
            icon: const Icon(LinkLianIcon.classroom),
            activeIcon: const ActiveNavIcon(icon: LinkLianIcon.classroom),
            label: AppStrings.classroom,
          ),
          BottomNavigationBarItem(
            icon: const Icon(LinkLianIcon.community),
            activeIcon: const ActiveNavIcon(icon: LinkLianIcon.community),
            label: AppStrings.community,
          ),
          BottomNavigationBarItem(
            icon: const Icon(LinkLianIcon.profile),
            activeIcon: const ActiveNavIcon(icon: LinkLianIcon.profile),
            label: AppStrings.profile,
          ),
        ],
      ),
    );
  }
}
