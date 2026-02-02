import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/linklian-icon.dart';
import '../../../core/constants/strings.dart';
import '../../auth/controller/auth_controller.dart';

/// Bottom navigation bar configuration based on role
class NavigationConfig {
  final List<NavigationItem> items;
  
  NavigationConfig({required this.items});
}

/// Individual navigation item
class NavigationItem {
  final String label;
  final IconData icon;
  final IconData? activeIcon;
  final int index;
  
  NavigationItem({
    required this.label,
    required this.icon,
    this.activeIcon,
    required this.index,
  });
}

/// Reusable bottom navigation bar widget
class MainNavigationBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onIndexChanged;
  final bool hideAddIcon;
  final VoidCallback? onAddPressed;
  final VoidCallback? onNotificationPressed;
  final VoidCallback? onChatPressed;
  
  const MainNavigationBar({
    super.key,
    required this.currentIndex,
    required this.onIndexChanged,
    this.hideAddIcon = false,
    this.onAddPressed,
    this.onNotificationPressed,
    this.onChatPressed,
  });

  /// Get navigation config based on user role
  static NavigationConfig getNavigationConfig(String? role) {
    final isStudent = role == 'high school student' || role == 'uni student';
    
    if (isStudent) {
      return NavigationConfig(items: [
        NavigationItem(
          label: AppStrings.homework,
          icon: LinkLianIcon.homework,
          index: 0,
        ),
        NavigationItem(
          label: AppStrings.classroom,
          icon: LinkLianIcon.classroom,
          index: 1,
        ),
        NavigationItem(
          label: AppStrings.community,
          icon: LinkLianIcon.community,
          index: 2,
        ),
        NavigationItem(
          label: AppStrings.profile,
          icon: LinkLianIcon.profile,
          index: 3,
        ),
      ]);
    } else {
      return NavigationConfig(items: [
        NavigationItem(
          label: AppStrings.homework,
          icon: LinkLianIcon.homework,
          index: 0,
        ),
        NavigationItem(
          label: AppStrings.classroom,
          icon: LinkLianIcon.classroom,
          index: 1,
        ),
        NavigationItem(
          label: AppStrings.profile,
          icon: LinkLianIcon.profile,
          index: 2,
        ),
      ]);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Get.find<AuthController>();
    final config = MainNavigationBar.getNavigationConfig(auth.roleName.value);
    
    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: onIndexChanged,
      type: BottomNavigationBarType.fixed,
      selectedItemColor: AppColors.primaryPalette[900],
      unselectedItemColor: AppColors.primaryPalette[800],
      backgroundColor: AppColors.primaryPalette[200],
      selectedFontSize: 12,
      unselectedFontSize: 12,
      items: config.items.map((item) {
        return BottomNavigationBarItem(
          icon: Icon(item.icon),
          activeIcon: _buildActiveIcon(item.icon),
          label: item.label,
        );
      }).toList(),
    );
  }

  /// Build active icon with background
  Widget _buildActiveIcon(IconData icon) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: AppColors.primaryPalette[300],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, size: 24),
    );
  }
}

/// Reusable top app bar with actions (add, notification, chat)
class MainAppBar extends StatelessWidget implements PreferredSizeWidget {
  final bool showAddIcon;
  final VoidCallback? onAddPressed;
  final VoidCallback? onNotificationPressed;
  final VoidCallback? onChatPressed;
  final Widget? titleWidget;

  const MainAppBar({
    super.key,
    this.showAddIcon = true,
    this.onAddPressed,
    this.onNotificationPressed,
    this.onChatPressed,
    this.titleWidget,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: AppColors.white,
      elevation: 0,
      titleSpacing: 0,
      title: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: titleWidget ?? const SizedBox.shrink(),
      ),
      actions: [
        if (showAddIcon && onAddPressed != null)
          GestureDetector(
            onTap: onAddPressed,
            child: Icon(
              LinkLianIcon.add,
              color: AppColors.primaryPalette[500],
              size: 32,
            ),
          ),
        if (showAddIcon && onAddPressed != null) const SizedBox(width: 12),
        if (onNotificationPressed != null)
          GestureDetector(
            onTap: onNotificationPressed,
            child: Icon(
              LinkLianIcon.notification,
              color: AppColors.warningPalette[500],
              size: 32,
            ),
          ),
        if (onNotificationPressed != null) const SizedBox(width: 12),
        if (onChatPressed != null)
          GestureDetector(
            onTap: onChatPressed,
            child: Icon(
              LinkLianIcon.message,
              color: AppColors.successPalette[500],
              size: 30,
            ),
          ),
        const SizedBox(width: 12),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}