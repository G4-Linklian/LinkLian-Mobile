import 'package:LinkLian/core/constants/colors.dart';
import 'package:LinkLian/core/constants/linklian-icon.dart';
import 'package:flutter/material.dart';

class DashboardCard extends StatelessWidget {
  final VoidCallback onTap;
  const DashboardCard({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primaryPalette[100],
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                LinkLianIcon.dashboard,
                color: AppColors.primaryPalette[600],
              ),
            ),
            title: const Text(
              'แดชบอร์ด',
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
            trailing: const Icon(
              LinkLianIcon.chevronright,
              size: 16,
            ),
            onTap: onTap,
          ),

          const Divider(
            indent: 16,
            endIndent: 16,
          ),
        ],
      ),
    );
  }
}
