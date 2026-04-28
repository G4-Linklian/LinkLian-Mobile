// // import 'package:get/get.dart';

// // class ChatBadgeService {
// //   static final RxInt _unreadCount = 0.obs;

// //   RxInt observe() => _unreadCount;

// //   void set(int count) {
// //     _unreadCount.value = count < 0 ? 0 : count;
// //   }

// //   void reset() {
// //     _unreadCount.value = 0;
// //   }
// // }
// import 'package:get/get.dart';
// /// Service สำหรับจัดการ badge ของ chat
// class ChatBadgeService {
//   static final ChatBadgeService _instance = ChatBadgeService._internal();
//   factory ChatBadgeService() => _instance;
//   ChatBadgeService._internal();

//   final RxInt _unreadCount = 0.obs;

//   /// ตั้งค่าจำนวน badge โดยตรง (ใช้ตอนโหลดจาก API)
//   void set(int count) => _unreadCount.value = count;

//   /// เพิ่ม 1 (ใช้ตอนมีข้อความใหม่)
//   void increment() => _unreadCount.value++;

//   /// ลด 1 (ใช้ตอนอ่าน 1 รายการ)
//   void decrement() {
//     if (_unreadCount.value > 0) _unreadCount.value--;
//   }

//   /// เคลียร์ badge (ใช้ตอนอ่านหมดหรือ logout)
//   void clear() => _unreadCount.value = 0;

//   /// สำหรับ Obx ใน UI
//   RxInt observe() => _unreadCount;

//   /// อ่านค่า int ธรรมดา
//   int count() => _unreadCount.value;
// }
