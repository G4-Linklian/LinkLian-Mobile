// Home page widgets will be placed here
// For example: custom cards, buttons, forms, etc.

import 'package:flutter/material.dart';

class HomeCard extends StatelessWidget {
  final String title;
  final VoidCallback? onTap;
  
  const HomeCard({
    super.key,
    required this.title,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(title),
        onTap: onTap,
      ),
    );
  }
}