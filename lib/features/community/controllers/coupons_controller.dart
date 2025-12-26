import 'package:get/get.dart';

class CouponsController extends GetxController {
  // Observable variables
  var isLoading = false.obs;
  var availableCoupons = <Map<String, dynamic>>[].obs;
  var usedCoupons = <Map<String, dynamic>>[].obs;
  
  @override
  void onInit() {
    super.onInit();
    loadCoupons();
    _loadSampleData();
  }
  
  // Load sample data for testing
  void _loadSampleData() {
    availableCoupons.value = [
      {
        'title': 'ส่วนลด 20%',
        'discount': 20,
        'description': 'ส่วนลดสำหรับการซื้อครั้งแรก',
        'expireDate': '31/12/2025',
        'used': false,
      },
      {
        'title': 'ส่วนลด 50 บาท',
        'discount': 50,
        'description': 'ส่วนลดสำหรับสินค้าทุกชิ้น',
        'expireDate': '15/01/2026',
        'used': false,
      },
    ];
  }
  
  
  
  // Load coupons from API
  void loadCoupons() async {
    isLoading.value = true;
    try {
      // API call will be implemented here
      // var coupons = await ApiService.getCoupons();
      // availableCoupons.value = coupons.where((c) => !c['used']).toList();
      // usedCoupons.value = coupons.where((c) => c['used']).toList();
    } catch (e) {
      // Handle error
    } finally {
      isLoading.value = false;
    }
  }
  
  // Use coupon
  void useCoupon(Map<String, dynamic> coupon) async {
    try {
      // API call to use coupon
      // await ApiService.useCoupon(coupon['id']);
      
      availableCoupons.remove(coupon);
      coupon['used'] = true;
      usedCoupons.add(coupon);
    } catch (e) {
      // Handle error
    }
  }
  
  // Get coupon discount
  String getCouponDiscount(Map<String, dynamic> coupon) {
    if (coupon['discount'].toString().contains('%')) {
      return '${coupon['discount']}';
    }
    return coupon['discount'].toString().contains('.') 
        ? '${coupon['discount']}%' 
        : coupon['discount'] > 100 
            ? '${coupon['discount']} บาท'
            : '${coupon['discount']}%';
  }
}