import 'package:get/get.dart';

class ProfileController extends GetxController {
  // Observable variables
  var isLoading = false.obs;
  var userName = ''.obs;
  var userEmail = ''.obs;
  var userPhone = ''.obs;
  var userImage = ''.obs;
  
  @override
  void onInit() {
    super.onInit();
    loadUserProfile();
    _loadSampleData();
  }
  
  // Load sample data for testing
  void _loadSampleData() {
    userName.value = 'นาย สมชาย ใจดี';
    userEmail.value = 'somchai@example.com';
    userPhone.value = '081-234-5678';
  }
  
  
  
  // Load user profile from API
  void loadUserProfile() async {
    isLoading.value = true;
    try {
      // API call will be implemented here
      // var userProfile = await ApiService.getUserProfile();
      // userName.value = userProfile['name'] ?? '';
      // userEmail.value = userProfile['email'] ?? '';
      // userPhone.value = userProfile['phone'] ?? '';
      // userImage.value = userProfile['image'] ?? '';
    } catch (e) {
      // Handle error
    } finally {
      isLoading.value = false;
    }
  }
  
  // Update profile
  void updateProfile({
    String? name,
    String? email,
    String? phone,
    String? image,
  }) async {
    isLoading.value = true;
    try {
      // API call to update profile
      // await ApiService.updateUserProfile({
      //   'name': name ?? userName.value,
      //   'email': email ?? userEmail.value,
      //   'phone': phone ?? userPhone.value,
      //   'image': image ?? userImage.value,
      // });
      
      if (name != null) userName.value = name;
      if (email != null) userEmail.value = email;
      if (phone != null) userPhone.value = phone;
      if (image != null) userImage.value = image;
      
    } catch (e) {
      // Handle error
    } finally {
      isLoading.value = false;
    }
  }
  
  // Logout user
  void logout() async {
    try {
      // API call to logout
      // await ApiService.logout();
      
      // Clear user data
      userName.value = '';
      userEmail.value = '';
      userPhone.value = '';
      userImage.value = '';
      
      // Navigate to login page
      // Get.offAllNamed('/login');
    } catch (e) {
      // Handle error
    }
  }
}