import 'package:LinkLian/core/constants/colors.dart';
import 'package:flutter/material.dart';
import '../../../shared/models/profile_model.dart';

class ProfileHeader extends StatelessWidget {
  final ProfileModel profile;
  const ProfileHeader({super.key, required this.profile});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          _avatar(),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (profile.code != null && profile.code!.isNotEmpty)
                      Text(
                        profile.code!,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Colors.black54,
                        ),
                      ),

                    Text(
                      profile.fullName,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),

                Text(profile.email, style: const TextStyle(color: Colors.grey)),
                if (profile.isTeacher &&
                    profile.phone != null &&
                    profile.phone!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  RichText(
                    text: TextSpan(
                      style: const TextStyle(fontSize: 12),
                      children: [
                        const TextSpan(
                          text: 'ช่องทางการติดต่อ : ',
                          style: TextStyle(
                            color: Colors.black54,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        TextSpan(
                          text: profile.phone!,
                          style: const TextStyle(
                            color: Colors.black87,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                if (!profile.isTeacher && profile.education != null) ...[
                  const SizedBox(height: 4),

                  if (profile.education!.type == 'high_school') ...[
                    if (profile.education!.studyPlan != null)
                      // Text('แผนการเรียน : ${profile.education!.studyPlan}'),
                      Text(
                        'ระดับชั้น : ${profile.education!.level}/${profile.education!.classroom}',
                      ),
                  ],

                  if (profile.education!.type == 'university') ...[
                    // Text('คณะ : ${profile.education!.faculty}'),
                    // Text('สาขา : ${profile.education!.program}'),
                    Text('ระดับชั้น : ${profile.education!.level}'),
                  ],
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _avatar() {
    final hasImage =
        profile.profilePic != null && profile.profilePic!.isNotEmpty;

    final fullName = profile.fullName.trim();

    if (hasImage) {
      return CircleAvatar(
        radius: 42,
        backgroundImage: NetworkImage(profile.profilePic!),
        onBackgroundImageError: (_, __) {},
      );
    }

    if (fullName.isEmpty) {
      return const CircleAvatar(radius: 42, child: Icon(Icons.person_off));
    }

    final parts = fullName.split(" ");

    String initials;
    if (parts.length == 1) {
      initials = parts[0][0];
    } else {
      initials = parts[0][0] + parts[1][0];
    }

    return CircleAvatar(
      radius: 42,
      child: Text(
        initials.toUpperCase(),
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 28,
          color: AppColors.primaryPalette[700],
        ),
      ),
    );
  }
}
