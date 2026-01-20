import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/utils/dialog_helper.dart';
import '../controllers/create_post_controller.dart';

class CreatePostImagePickerButton extends StatelessWidget {
  final CreatePostController controller;
  final Icon icon;

  const CreatePostImagePickerButton({
    super.key,
    required this.controller,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: icon,
      onPressed: () => _showSheet(context),
    );
  }

  void _showSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Photo Library'),
                onTap: () => _pickImage(context, ImageSource.gallery),
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Take Photo or Video'),
                onTap: () => _pickImage(context, ImageSource.camera),
              ),
              const Divider(),
              ListTile(
                title: const Center(
                  child: Text(
                    'Cancel',
                    style: TextStyle(color: Colors.red),
                  ),
                ),
                onTap: () => Navigator.pop(context),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickImage(
    BuildContext context,
    ImageSource source,
  ) async {
    Navigator.pop(context);

    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: source,
      imageQuality: 85,
    );

    if (image == null) return;

    DialogHelper.showLoading('กำลังอัปโหลดรูป...');
    await controller.uploadFiles([File(image.path)]);
    DialogHelper.hideLoading();
  }
}