import 'package:flutter/material.dart';

class BookmarkCard extends StatelessWidget {
  final String title;

  const BookmarkCard({
    super.key,
    this.title = 'เตรียมตัวสอบหัวข้อโครงงาน...', // default
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.picture_as_pdf, color: Colors.red),
        title: Text(title),
        trailing: const Icon(Icons.bookmark),
      ),
    );
  }
}

