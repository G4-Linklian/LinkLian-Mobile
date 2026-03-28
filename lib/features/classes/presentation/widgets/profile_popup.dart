import 'package:LinkLian/core/utils/chat_navigation_helper.dart';
import 'package:LinkLian/features/auth/controller/auth_controller.dart';
import 'package:LinkLian/features/shared/models/profile_model.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/constants/colors.dart';

class ProfilePopup extends StatelessWidget {
  final ProfileModel profile;

  const ProfilePopup({super.key, required this.profile});

  @override
  Widget build(BuildContext context) {
    final isTeacher = profile.isTeacher;
    final auth = Get.find<AuthController>();
    final viewerRole = auth.roleName.value?.toLowerCase();
    final isDeletedUser = profile.fullName.isEmpty;
    final viewerIsTeacher =
        viewerRole == 'teacher' || viewerRole == 'instructor';

    final targetIsTeacher = profile.isTeacher;

    final isSelf = auth.userId.value == profile.userSysId;

   final canSendMessage =
    viewerIsTeacher != targetIsTeacher &&
    !isSelf &&
    !isDeletedUser;

    final role = profile.roleName.toLowerCase();

    final isHighSchool = role.contains('high school');
    final isUniversity = role.contains('uni');

    final codeLabel = isHighSchool ? "รหัสนักเรียน" : "รหัสนักศึกษา";

    return GestureDetector(
      onTap: () => Get.back(),
      child: Material(
        color: Colors.black45,
        child: Center(
          child: GestureDetector(
            onTap: () {},
            child: Container(
              width: 320,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    /// PROFILE IMAGE
                    CircleAvatar(
                      radius: 40,
                      backgroundImage: profile.profilePic != null
                          ? NetworkImage(profile.profilePic!)
                          : null,
                      child: profile.profilePic == null
                          ? Text(
                              profile.fullName.isNotEmpty
                                  ? profile.fullName[0]
                                  : "?",
                              style: const TextStyle(fontSize: 28),
                            )
                          : null,
                    ),

                    const SizedBox(height: 12),

                    /// NAME
                    Text(
                      profile.fullName.isNotEmpty
                          ? profile.fullName
                          : "ผู้ใช้นี้ไม่ได้ใช้งานแล้ว",

                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 4),

                    /// ROLE
                    Text(
                      profile.roleName == "teacher"
                          ? "ครู"
                          : profile.roleName == "instructor"
                          ? "อาจารย์"
                          : profile.roleName == "high school student"
                          ? "นักเรียน"
                          : profile.roleName == "uni student"
                          ? "นักศึกษา"
                          : profile.roleName,
                      style: TextStyle(color: Colors.grey[600]),
                    ),

                    const SizedBox(height: 16),

                    /// STUDENT INFO
                    if (profile.isStudent) ...[
                      _infoRow(codeLabel, profile.code ?? "-"),
                      const SizedBox(height: 6),
                      _infoRow(
                        "ระดับชั้น",
                        profile.education != null
                            ? isUniversity
                                  ? profile.education!.classroom != null &&
                                            profile
                                                .education!
                                                .classroom!
                                                .isNotEmpty &&
                                            profile.education!.classroom != "-"
                                        ? "${profile.education!.level ?? '-'} ชั้นปี ${profile.education!.classroom}"
                                        : "${profile.education!.level ?? '-'}"
                                  : "${profile.education!.level ?? '-'} / ${profile.education!.classroom ?? '-'}"
                            : "-",
                      ),
                      const SizedBox(height: 6),
                      _infoRow("อีเมล", profile.email),
                    ],

                    /// TEACHER INFO
                    if (isTeacher) ...[
                      _infoRow("อีเมล", profile.email),
                      const SizedBox(height: 6),
                      _infoRow("ช่องทางการติดต่อ", profile.phone ?? "-"),
                    ],

                    const SizedBox(height: 20),

                    /// MESSAGE BUTTON
                    if (canSendMessage)
                      ElevatedButton(
                        onPressed: () async {
                          Get.back();

                          await openChatWithUser(profile);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryPalette[600],
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        child: const Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 10,
                          ),
                          child: Text("ส่งข้อความ"),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _infoRow(String title, String value) {
    return Row(
      children: [
        Text("$title : ", style: const TextStyle(fontWeight: FontWeight.w600)),
        Expanded(child: Text(value)),
      ],
    );
  }
}
