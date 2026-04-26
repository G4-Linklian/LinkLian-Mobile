import 'package:get/get.dart';

class ChatBadgeService {
  static final RxInt _unreadCount = 0.obs;

  RxInt observe() => _unreadCount;

  void set(int count) {
    _unreadCount.value = count < 0 ? 0 : count;
  }

  void reset() {
    _unreadCount.value = 0;
  }
}
