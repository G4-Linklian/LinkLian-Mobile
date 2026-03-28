import 'package:LinkLian/core/constants/colors.dart';
import 'package:flutter/material.dart';

class AppAvatar extends StatelessWidget {
  final String firstName;
  final String lastName;
  final String? profilePic;
  final double radius;

  const AppAvatar({
    super.key,
    required this.firstName,
    required this.lastName,
    this.profilePic,
    this.radius = 28,
  });

  @override
  Widget build(BuildContext context) {
    final isDeletedUser =
        (firstName.isEmpty && lastName.isEmpty) ||
        firstName == 'ไม่มีบัญชีผู้ใช้งาน';
    if (!isDeletedUser && profilePic != null && profilePic!.isNotEmpty) {
      return CircleAvatar(
        radius: radius,
        backgroundImage: NetworkImage(profilePic!),
        backgroundColor: Colors.grey[200],
      );
    }

    final initials =
        "${firstName.isNotEmpty ? firstName[0] : ''}"
                "${lastName.isNotEmpty ? lastName[0] : ''}"
            .toUpperCase();

    return CircleAvatar(
      radius: radius,
      backgroundColor: isDeletedUser
          ? Colors.grey
          : AppColors.primaryPalette[300],
      child: isDeletedUser
          ? const Icon(Icons.person_off, color: Colors.white)
          : Text(
              initials,
              style: TextStyle(
                fontSize: radius * 0.8,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
    );
  }
}
