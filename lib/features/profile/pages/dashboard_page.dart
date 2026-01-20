import 'package:LinkLian/core/constants/linklian-icon.dart';
import 'package:flutter/material.dart';
import '../../classes/widgets/semester_selector.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(LinkLianIcon.chevronleft, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'แดชบอร์ด',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            
            const SemesterSelector(),

            const SizedBox(height: 16),

            Expanded(
              child: ListView(
                children: const [
                  _DashboardPlaceholder(title: 'ภาพรวมการส่งงาน'),
                  _DashboardPlaceholder(title: 'ส่งงานตรงเวลา'),
                  _DashboardPlaceholder(title: 'ส่งงานล่าช้า'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DashboardPlaceholder extends StatelessWidget {
  final String title;
  const _DashboardPlaceholder({required this.title});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: SizedBox(
        height: 160,
        child: Center(
          child: Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
        ),
      ),
    );
  }
}
