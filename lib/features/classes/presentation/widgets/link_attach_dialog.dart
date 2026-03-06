import 'package:flutter/material.dart';

class LinkAttachDialog extends StatelessWidget {
  final ValueChanged<String> onSubmit;

  const LinkAttachDialog({super.key, required this.onSubmit});

  @override
  Widget build(BuildContext context) {
    final controller = TextEditingController();

    return AlertDialog(
      title: const Text('แนบลิงก์'),
      content: TextField(
        controller: controller,
        decoration: const InputDecoration(
          hintText: 'https://example.com',
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('ยกเลิก'),
        ),
        ElevatedButton(
          onPressed: () {
            final value = controller.text.trim();
            if (value.isNotEmpty) {
              Navigator.pop(context);
              onSubmit(value);
            }
          },
          child: const Text('เพิ่ม'),
        ),
      ],
    );
  }
}