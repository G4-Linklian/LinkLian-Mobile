import 'dart:io';
import 'package:LinkLian/core/constants/linklian-icon.dart';
import 'package:LinkLian/data/model/profile_model.dart';
import 'package:LinkLian/features/auth/controller/auth_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../controllers/profile_controller.dart';
import '../../../core/constants/colors.dart';
import 'package:image_picker/image_picker.dart';

class NoEmojiInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // RegExp สำหรับตรวจจับอิโมจิและสัญลักษณ์พิเศษ
    final emojiRegex = RegExp(
      r'[\u{1F600}-\u{1F64F}]|[\u{1F300}-\u{1F5FF}]|[\u{1F680}-\u{1F6FF}]|'
      r'[\u{1F700}-\u{1F77F}]|[\u{1F780}-\u{1F7FF}]|[\u{1F800}-\u{1F8FF}]|'
      r'[\u{1F900}-\u{1F9FF}]|[\u{1FA00}-\u{1FA6F}]|[\u{1FA70}-\u{1FAFF}]|'
      r'[\u{2600}-\u{26FF}]|[\u{2700}-\u{27BF}]|[\u{1F1E6}-\u{1F1FF}]',
      unicode: true,
    );

    if (emojiRegex.hasMatch(newValue.text)) {
      return oldValue;
    }
    return newValue;
  }
}

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
  String? draftProfilePic;

  @override
  void initState() {
    super.initState();

    final profile = controller.profile.value;
    if (profile == null) {
      firstNameCtrl = TextEditingController();
      //middleNameCtrl = TextEditingController();
      lastNameCtrl = TextEditingController();
      phoneCtrl = TextEditingController();
      return;
    }

    firstNameCtrl = TextEditingController(text: profile.firstName);
    //middleNameCtrl = TextEditingController(text: profile.middleName ?? '');
    lastNameCtrl = TextEditingController(text: profile.lastName);
    phoneCtrl = TextEditingController(text: profile.phone ?? '');
    originalProfilePic = profile.profilePic;
    draftProfilePic = profile.profilePic;
  }

  @override
  void dispose() {
    firstNameCtrl.dispose();
    //middleNameCtrl.dispose();
    lastNameCtrl.dispose();
    phoneCtrl.dispose();
    super.dispose();
  }

  void _toggleEdit() {
    setState(() {
      isEditing = !isEditing;
    });

    if (!isEditing) {
      draftProfilePic = originalProfilePic;
      final profile = controller.profile.value;
      if (profile != null) {
        firstNameCtrl.text = profile.firstName;
        lastNameCtrl.text = profile.lastName;
        phoneCtrl.text = profile.phone ?? '';
        // controller.restoreOriginalProfilePic(originalProfilePic);
      }
    } else {
      originalProfilePic = controller.profile.value?.profilePic;
      draftProfilePic = originalProfilePic;
    }
  }

  Future<void> _save() async {
    final firstName = firstNameCtrl.text.trim();
    final lastName = lastNameCtrl.text.trim();
    final phone = phoneCtrl.text.trim();

    if (firstName.isEmpty || lastName.isEmpty) {
      _showResultDialog(success: false, message: 'กรุณากรอกชื่อและนามสกุล');
      return;
    }
    if (phone.isNotEmpty && !RegExp(r'^0[0-9]{9}$').hasMatch(phone)) {
      _showResultDialog(success: false, message: 'กรุณากรอกเบอร์โทรให้ถูกต้อง');
      return;
    }

    try {
      final auth = Get.find<AuthController>();
      final userId = auth.userId.value!;

      if (draftProfilePic != originalProfilePic) {
        if (draftProfilePic == null) {
          await controller.repo.updateProfile(
            userId,
            firstName: firstName,
            lastName: lastName,
            phone: phone,
            clearProfilePic: true,
          );
        } else {
          final url = await controller.repo.uploadAvatar(
            userId,
            File(draftProfilePic!),
          );

          await controller.repo.updateProfile(
            userId,
            firstName: firstName,
            lastName: lastName,
            phone: phone,
            profilePic: url,
          );
        }
      } else {
        await controller.updateProfile(
          firstName: firstName,
          lastName: lastName,
          phone: phone.isEmpty ? null : phone,
        );
      }

      await controller.loadProfile();
      originalProfilePic = controller.profile.value?.profilePic;

      setState(() {
        isEditing = false;
      });

      _showResultDialog(success: true, message: 'บันทึกสำเร็จ');
      //await Future.delayed(const Duration(milliseconds: 1500));
      // Get.back(result: true);
      // Get.back();
    } catch (e) {
      _showResultDialog(success: false, message: 'บันทึกไม่สำเร็จ');
    }
  }

  void _showResultDialog({required bool success, required String message}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Align(
        alignment: Alignment.topCenter,
        child: Padding(
          padding: const EdgeInsets.only(top: 24),
          child: Material(
            color: Colors.transparent,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 40),
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 8),
              decoration: BoxDecoration(
                color: success
                    ? AppColors.successPalette[500]
                    : AppColors.dangerPalette[500],
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
                isEditing: isEditing,
                avatarUrl: draftProfilePic,
                profile: profile,
                onPickGallery: () async {
                  final XFile? picked = await ImagePicker().pickImage(
                    source: ImageSource.gallery,
                  );
                  if (picked != null) {
                    setState(() {
                      draftProfilePic = picked.path;
                    });
                  }
                },
                onPickCamera: () async {
                  final XFile? picked = await ImagePicker().pickImage(
                    source: ImageSource.camera,
                  );
                  if (picked != null) {
                    setState(() {
                      draftProfilePic = picked.path;
                    });
                  }
                },
                onDelete: () {
                  setState(() {
                    draftProfilePic = null;
                  });
                },
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
                inputFormatters: [NoEmojiInputFormatter(),],
                decoration: const InputDecoration(
                  labelText: 'ชื่อ',
                  prefixIcon: Icon(Icons.person),
                ),
              ),

              const SizedBox(height: 16),

              TextFormField(
                controller: lastNameCtrl,
                enabled: isEditing,
                inputFormatters: [NoEmojiInputFormatter(),],
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
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(10),
                  NoEmojiInputFormatter(),
                ],
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
  final bool isEditing;
  final String? avatarUrl;
  final ProfileModel profile;
  final VoidCallback onPickGallery;
  final VoidCallback onPickCamera;
  final VoidCallback onDelete;

  const _AvatarSection({
    required this.isEditing,
    required this.avatarUrl,
    required this.profile,
    required this.onPickGallery,
    required this.onPickCamera,
    required this.onDelete,
  });
  void _showAvatarOptions(BuildContext context) {
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
                leading: Icon(
                  LinkLianIcon.photo,
                  color: AppColors.primaryPalette[600],
                ),
                title: const Text('เลือกจากอัลบั้ม'),
                onTap: () {
                  Navigator.pop(context);
                  onPickGallery();
                },
              ),
              ListTile(
                leading: Icon(
                  LinkLianIcon.camera,
                  color: AppColors.primaryPalette[600],
                ),
                title: const Text('ถ่ายรูป'),
                onTap: () {
                  Navigator.pop(context);
                  onPickCamera();
                },
              ),
              if (avatarUrl != null)
                ListTile(
                  leading: Icon(
                    LinkLianIcon.delete,
                    color: AppColors.dangerPalette[500],
                  ),
                  title: Text(
                    'ลบรูป',
                    style: TextStyle(color: AppColors.dangerPalette[500]),
                  ),
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
              onDelete();
              //controller.deleteAvatar();
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
      child: Column(
        children: [
            GestureDetector(
              onTap: isEditing ? () => _showAvatarOptions(context) : null,
              child: Stack(
                alignment: Alignment.bottomRight,
                children: [
                  _buildAvatar(profile),
                  if (isEditing)
                    Container(
                      padding: EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppColors.primaryPalette[600],
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
        ),
      );
  }

  Widget _buildAvatar(ProfileModel? profile) {
    if (avatarUrl != null && avatarUrl!.isNotEmpty) {
      return CircleAvatar(
        radius: 48,
        backgroundColor: Colors.grey.shade200,
        child: ClipOval(
          child: avatarUrl!.startsWith('http')
              ? Image.network(
                  avatarUrl!,
                  width: 96,
                  height: 96,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) {
                    return _buildInitialAvatar();
                  },
                )
              : Image.file(
                  File(avatarUrl!),
                  width: 96,
                  height: 96,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) {
                    return _buildInitialAvatar();
                  },
                ),
        ),
      );
    }
    return _buildInitialAvatar();
  }

  Widget _buildInitialAvatar() {
    String initials = '';
    if (profile.firstName.isNotEmpty) {
      initials += profile.firstName[0].toUpperCase();
    }
    if (profile.lastName.isNotEmpty) {
      initials += profile.lastName[0].toUpperCase();
    }

    return CircleAvatar(
      radius: 48,
      backgroundColor: AppColors.primaryPalette[500],
      child: Text(
        initials,
        style: const TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }
}
