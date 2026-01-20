import 'package:LinkLian/core/constants/linklian-icon.dart';
import 'package:LinkLian/data/model/profile_model.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/profile_controller.dart';
import '../../../core/constants/colors.dart';

class AccountPage extends StatefulWidget {
  const AccountPage({super.key});

  @override
  State<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  final ProfileController controller = Get.find<ProfileController>();

  late TextEditingController firstNameCtrl;
  late TextEditingController middleNameCtrl;
  late TextEditingController lastNameCtrl;
  late TextEditingController phoneCtrl;

  bool isEditing = false;

  String? originalProfilePic;

  @override
  void initState() {
    super.initState();

    final profile = controller.profile.value;
    if (profile == null) {
      firstNameCtrl = TextEditingController();
      middleNameCtrl = TextEditingController();
      lastNameCtrl = TextEditingController();
      phoneCtrl = TextEditingController();
      return;
    }

    firstNameCtrl = TextEditingController(text: profile.firstName);
    middleNameCtrl = TextEditingController(text: profile.middleName ?? '');
    lastNameCtrl = TextEditingController(text: profile.lastName);
    phoneCtrl = TextEditingController(text: profile.phone ?? '');
    originalProfilePic = profile.profilePic;
  }

  @override
  void dispose() {
    firstNameCtrl.dispose();
    middleNameCtrl.dispose();
    lastNameCtrl.dispose();
    phoneCtrl.dispose();
    super.dispose();
  }

  void _toggleEdit() {
    setState(() {
      isEditing = !isEditing;
    });

    if (!isEditing) {
      final profile = controller.profile.value;
      if (profile != null) {
        firstNameCtrl.text = profile.firstName;
        lastNameCtrl.text = profile.lastName;
        phoneCtrl.text = profile.phone ?? '';
        // controller.restoreOriginalProfilePic(originalProfilePic);
      }
    }else{
      originalProfilePic = controller.profile.value?.profilePic;
    }
  }

  Future<void> _save() async {
    try {
      await controller.updateProfile(
        firstName: firstNameCtrl.text.trim(),
        lastName: lastNameCtrl.text.trim(),
        phone: phoneCtrl.text.trim().isEmpty
            ? null
            : phoneCtrl.text.trim(),
      );

      originalProfilePic = controller.profile.value?.profilePic;

      setState(() {
        isEditing = false;
      });

      _showResultDialog(
        success: true,
        message: 'บันทึกสำเร็จ',
      );

      await Future.delayed(const Duration(milliseconds: 1500));
      Get.back();
    } catch (e) {

      _showResultDialog(
        success: false,
        message: 'บันทึกไม่สำเร็จ',
      );
    }
  }

  void _showResultDialog({required bool success, required String message}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Align(
        alignment: Alignment.topCenter,
        child: Padding(
          padding: const EdgeInsets.only(top: 100),
          child: Material(
            color: Colors.transparent,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 40),
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 8),
              decoration: BoxDecoration(
                color: success ? AppColors.successPalette[500] : AppColors.dangerPalette[500],
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    success ? LinkLianIcon.check : LinkLianIcon.cancel,
                    color: Colors.white,
                    size: 32,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    message,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LinkLianIcon.chevronleft, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'บัญชี',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        actions: [
          if (!isEditing)
            IconButton(
              icon: const Icon(LinkLianIcon.edit, color: Colors.black),
              onPressed: _toggleEdit,
            )
          else
            TextButton(
              onPressed: _toggleEdit,
              child: Text(
                'ยกเลิก',
                style: TextStyle(
                color: AppColors.primaryPalette[800],
                fontSize: 16,
              ),
              ),
            ),
        ],
      ),
      body: Obx(() {
        final profile = controller.profile.value;

        if (profile == null) {
          return const Center(child: CircularProgressIndicator());
        }

        return Padding(
          padding: const EdgeInsets.all(16),
          child: ListView(
            children: [
              _AvatarSection(
                controller: controller,
                isEditing: isEditing,
              ),
              const SizedBox(height: 24),

              TextFormField(
                initialValue: profile.email,
                enabled: false,
                decoration: const InputDecoration(
                  labelText: 'อีเมล',
                  prefixIcon: Icon(Icons.email),
                ),
              ),

              const SizedBox(height: 16),

              TextFormField(
                controller: firstNameCtrl,
                enabled: isEditing,
                decoration: const InputDecoration(
                  labelText: 'ชื่อ',
                  prefixIcon: Icon(Icons.person),
                ),
              ),

              const SizedBox(height: 16),

              TextFormField(
                controller: lastNameCtrl,
                enabled: isEditing,
                decoration: const InputDecoration(
                  labelText: 'นามสกุล',
                  prefixIcon: Icon(Icons.person),
                ),
              ),

              const SizedBox(height: 16),

              TextFormField(
                controller: phoneCtrl,
                enabled: isEditing,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'เบอร์โทรศัพท์',
                  prefixIcon: Icon(LinkLianIcon.phone),
                ),
              ),

              const SizedBox(height: 32),

              if (isEditing)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryPalette[500],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: controller.saving.value ? null : _save,
                    child: controller.saving.value
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                            'บันทึกการเปลี่ยนแปลง',
                            style: TextStyle(fontSize: 16),
                          ),
                  ),
                ),
            ],
          ),
        );
      }),
    );
  }
}

class _AvatarSection extends StatelessWidget {
  final ProfileController controller;
  final bool isEditing;

  const _AvatarSection({
    required this.controller,
    this.isEditing = false,
  });

  void _showAvatarOptions(BuildContext context) {
    final hasProfilePic = controller.profile.value?.profilePic != null && 
                         controller.profile.value!.profilePic!.isNotEmpty;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(LinkLianIcon.photo, color: AppColors.primaryPalette[600]),
                title: const Text('เลือกจากอัลบั้ม'),
                onTap: () {
                  Navigator.pop(context);
                  controller.pickImageFromGallery();
                },
              ),
              ListTile(
                leading: Icon(LinkLianIcon.camera, color: AppColors.primaryPalette[600]),
                title: const Text('ถ่ายรูป'),
                onTap: () {
                  Navigator.pop(context);
                  controller.pickImageFromCamera();
                },
              ),
              if (hasProfilePic)
                ListTile(
                  leading: Icon(LinkLianIcon.delete, color: AppColors.dangerPalette[500]),
                  title: Text('ลบรูป', style: TextStyle(color: AppColors.dangerPalette[500])),
                  onTap: () {
                    Navigator.pop(context);
                    _confirmDelete(context);
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ยืนยันการลบรูป'),
        content: const Text('คุณต้องการลบรูปโปรไฟล์ใช่หรือไม่?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ยกเลิก'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              controller.deleteAvatar();
            },
            child: const Text('ลบ', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Obx(() {
        final profile = controller.profile.value;

        return Column(
          children: [
            GestureDetector(
              onTap: isEditing && !controller.saving.value
                  ? () => _showAvatarOptions(context)
                  : null,
              child: Stack(
                alignment: Alignment.bottomRight,
                children: [
                  _buildAvatar(profile),

                  if (isEditing)
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                        color: Colors.orange,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        LinkLianIcon.pencil,
                        size: 18,
                        color: Colors.white,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            if (isEditing)
              const Text(
                'เปลี่ยนรูปโปรไฟล์',
                style: TextStyle(color: Colors.grey),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildAvatar(ProfileModel? profile) {
  final pic = profile?.profilePic;

  if (pic != null && pic.isNotEmpty) {
    return CircleAvatar(
      radius: 48,
      backgroundColor: Colors.grey.shade200,
      child: ClipOval(
        child: Image.network(
          pic,
          width: 96,
          height: 96,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) {
            // ✅ fallback ถ้า 404
            return _buildInitialAvatar(profile);
          },
        ),
      ),
    );
  }

  return _buildInitialAvatar(profile);
}

Widget _buildInitialAvatar(ProfileModel? profile) {
  return CircleAvatar(
    radius: 48,
    child: Text(
      profile != null
          ? profile.firstName[0] + profile.lastName[0]
          : '',
      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
    ),
  );
}

}
