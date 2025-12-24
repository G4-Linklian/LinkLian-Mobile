import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/rooms_controller.dart';
import '../widgets/room_widgets.dart';
import '../../../core/constants/sizes.dart';

class ClassesPage extends StatelessWidget {
  const ClassesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(RoomsController());
    
    return Scaffold(
      body: Obx(() => controller.isLoading.value 
        ? const Center(child: CircularProgressIndicator())
        : Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSizes.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'ห้องเรียนของฉัน',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () {
                        // Add new room
                        controller.addRoom({
                          'name': 'ห้องใหม่ ${controller.roomsList.length + 1}',
                          'type': 'ห้องประชุม',
                          'capacity': 10,
                        });
                      },
                      icon: const Icon(Icons.add),
                      label: const Text('เพิ่มห้อง'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: controller.roomsList.isEmpty
                    ? const Center(
                        child: Text('ไม่มีห้องห้วน'),
                      )
                    : ListView.builder(
                        itemCount: controller.roomsList.length,
                        itemBuilder: (context, index) {
                          final room = controller.roomsList[index];
                          return RoomCard(
                            roomName: room['name'] ?? '',
                            roomType: room['type'] ?? '',
                            capacity: room['capacity'] ?? 0,
                            onTap: () {
                              // Navigate to room details
                            },
                          );
                        },
                      ),
                ),
              ],
            ),
          ),
      ),
    );
  }
}