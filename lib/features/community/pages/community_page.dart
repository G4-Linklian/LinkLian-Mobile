import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/coupons_controller.dart';
import '../widgets/coupon_widgets.dart';
import '../../../core/constants/sizes.dart';

class CommuPage extends StatelessWidget {
  const CommuPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(CouponsController());
    
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        body: Column(
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: AppSizes.md),
              child: Row(
                children: [
                  Text(
                    'ชุมชน',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            // const TabBar(
            //   tabs: [
            //     Tab(text: 'คูปองที่ใช้ได้'),
            //     Tab(text: 'คูปองที่ใช้แล้ว'),
            //   ],
            // ),
            // Expanded(
            //   child: Obx(() => controller.isLoading.value 
            //     ? const Center(child: CircularProgressIndicator())
            //     : TabBarView(
            //         children: [
            //           // Available coupons
            //           controller.availableCoupons.isEmpty
            //             ? const Center(child: Text('ไม่มีคูปองที่ใช้ได้'))
            //             : ListView.builder(
            //                 padding: const EdgeInsets.all(16),
            //                 itemCount: controller.availableCoupons.length,
            //                 itemBuilder: (context, index) {
            //                   final coupon = controller.availableCoupons[index];
            //                   return CouponCard(
            //                     title: coupon['title'] ?? 'คูปองส่วนลด',
            //                     discount: controller.getCouponDiscount(coupon),
            //                     description: coupon['description'] ?? 'รายละเอียดคูปอง',
            //                     expireDate: coupon['expireDate'] ?? '31/12/2025',
            //                     isUsed: false,
            //                     onTap: () {
            //                       controller.useCoupon(coupon);
            //                     },
            //                   );
            //                 },
            //               ),
            //           // Used coupons
            //           controller.usedCoupons.isEmpty
            //             ? const Center(child: Text('ไม่มีคูปองที่ใช้แล้ว'))
            //             : ListView.builder(
            //                 padding: const EdgeInsets.all(16),
            //                 itemCount: controller.usedCoupons.length,
            //                 itemBuilder: (context, index) {
            //                   final coupon = controller.usedCoupons[index];
            //                   return CouponCard(
            //                     title: coupon['title'] ?? 'คูปองส่วนลด',
            //                     discount: controller.getCouponDiscount(coupon),
            //                     description: coupon['description'] ?? 'รายละเอียดคูปอง',
            //                     expireDate: coupon['expireDate'] ?? '31/12/2025',
            //                     isUsed: true,
            //                   );
            //                 },
            //               ),
            //         ],
            //       ),
            //   ),
            // ),
          ],
        ),
      ),
    );
  }
}