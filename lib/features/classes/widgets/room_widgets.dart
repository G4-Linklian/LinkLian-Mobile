// Rooms page widgets will be placed here
// For example: room cards, room list items, etc.

import 'package:flutter/material.dart';

class RoomCard extends StatelessWidget {
  final String roomName;
  final String roomType;
  final int capacity;
  final VoidCallback? onTap;
  
  const RoomCard({
    super.key,
    required this.roomName,
    required this.roomType,
    required this.capacity,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(roomName),
        subtitle: Text('$roomType - จุได้ $capacity คน'),
        trailing: const Icon(Icons.arrow_forward_ios),
        onTap: onTap,
      ),
    );
  }
}

class RoomListTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget? leading;
  final VoidCallback? onTap;
  
  const RoomListTile({
    super.key,
    required this.title,
    required this.subtitle,
    this.leading,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: leading,
      title: Text(title),
      subtitle: Text(subtitle),
      onTap: onTap,
    );
  }
}