import 'package:get/get.dart';

class RoomsController extends GetxController {
  // Observable variables
  var isLoading = false.obs;
  var roomsList = <Map<String, dynamic>>[].obs;
  
  @override
  void onInit() {
    super.onInit();
    loadRooms();
  }
  
  
  
  // Load rooms from API
  void loadRooms() async {
    isLoading.value = true;
    try {
      // API call will be implemented here
      // roomsList.value = await ApiService.getRooms();
    } catch (e) {
      // Handle error
    } finally {
      isLoading.value = false;
    }
  }
  
  // Add room
  void addRoom(Map<String, dynamic> room) {
    roomsList.add(room);
  }
  
  // Remove room
  void removeRoom(int index) {
    roomsList.removeAt(index);
  }
}