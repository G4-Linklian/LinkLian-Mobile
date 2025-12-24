// Coupons page widgets will be placed here
// For example: coupon cards, coupon lists, etc.

import 'package:flutter/material.dart';

class CouponCard extends StatelessWidget {
  final String title;
  final String discount;
  final String description;
  final String expireDate;
  final bool isUsed;
  final VoidCallback? onTap;
  
  const CouponCard({
    super.key,
    required this.title,
    required this.discount,
    required this.description,
    required this.expireDate,
    this.isUsed = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: isUsed ? Colors.grey.shade200 : Colors.white,
        ),
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: isUsed ? Colors.grey : Colors.orange,
            child: Text(
              discount,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          title: Text(
            title,
            style: TextStyle(
              decoration: isUsed ? TextDecoration.lineThrough : null,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(description),
              Text(
                'หมดอายุ: $expireDate',
                style: const TextStyle(fontSize: 12),
              ),
            ],
          ),
          trailing: isUsed 
            ? const Text('ใช้แล้ว', style: TextStyle(color: Colors.grey))
            : const Icon(Icons.arrow_forward_ios),
          onTap: isUsed ? null : onTap,
        ),
      ),
    );
  }
}