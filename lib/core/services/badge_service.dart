import 'package:get/get.dart';

/// Feature identifiers — เพิ่ม feature ใหม่ที่นี่
class BadgeFeature {
  static const String general = 'general'; // bell icon
  static const String chat = 'chat'; // chat icon
}

/// Central badge manager
/// รับ feature + count แล้วอัปเดต badge ที่ถูกต้อง
/// ทุก service เรียกใช้ได้โดยไม่ต้องรู้ว่า UI ทำยังไง
class BadgeService {
  static final BadgeService _instance = BadgeService._internal();
  factory BadgeService() => _instance;
  BadgeService._internal();

  final _counts = <String, RxInt>{};

  RxInt _slot(String feature) =>
      _counts.putIfAbsent(feature, () => 0.obs);

  /// ตั้งค่า badge โดยตรง — ใช้ตอน init หรือโหลดจาก API
  void set(String feature, int count) => _slot(feature).value = count;

  /// เพิ่ม 1 — ใช้ตอน socket event เข้ามา
  void increment(String feature) => _slot(feature).value++;

  /// ลด 1 — ใช้ตอนอ่าน 1 รายการ
  void decrement(String feature) {
    final current = _slot(feature).value;
    if (current > 0) _slot(feature).value = current - 1;
  }

  /// เคลียร์ทั้งหมด — ใช้ตอนเปิดหน้านั้นหรือ logout
  void clear(String feature) => _slot(feature).value = 0;

  /// reactive stream สำหรับ Obx ใน UI
  RxInt observe(String feature) => _slot(feature);

  /// อ่านค่า int ธรรมดา
  int count(String feature) => _slot(feature).value;
}
