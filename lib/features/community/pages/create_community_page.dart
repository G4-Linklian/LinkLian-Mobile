// import 'package:LinkLian/features/community/widgets/tag_selection_popup.dart';
// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import '../controllers/create_community_controller.dart';

// class CreateCommunityPage extends StatelessWidget {
//   const CreateCommunityPage({super.key});

//   @override
//   Widget build(BuildContext context) {
//     final controller = Get.find<CreateCommunityController>();

//     return Scaffold(
//       backgroundColor: const Color(0xFFF8F8F8),
//       appBar: AppBar(
//         backgroundColor: Colors.transparent,
//         elevation: 0,
//         leading: IconButton(
//           icon: const Icon(Icons.close, color: Colors.black),
//           onPressed: () => Get.back(),
//         ),
//         title: const Text(
//           "สร้างชุมชน",
//           style: TextStyle(color: Colors.black, fontWeight: FontWeight.w600),
//         ),
//         centerTitle: true,
//       ),
//       body: SingleChildScrollView(
//         padding: const EdgeInsets.all(20),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             const Text(
//               "ชื่อชุมชน",
//               style: TextStyle(fontWeight: FontWeight.w600),
//             ),
//             const SizedBox(height: 8),
//             TextField(
//               controller: controller.nameController,
//               decoration: _inputDecoration("ระบุชื่อชุมชนของคุณ..."),
//             ),

//             const Text(
//               "รายละเอียด",
//               style: TextStyle(fontWeight: FontWeight.w600),
//             ),
//             const SizedBox(height: 8),
//             TextField(
//               controller: controller.descriptionController,
//               maxLines: 3,
//               decoration: _inputDecoration("อธิบายเกี่ยวกับชุมชนของคุณ..."),
//             ),

//             const SizedBox(height: 20),

//             const Text(
//               "กฎของชุมชน",
//               style: TextStyle(fontWeight: FontWeight.w600),
//             ),
//             const SizedBox(height: 12),

//             Obx(
//               () => Container(
//                 padding: const EdgeInsets.all(12),
//                 decoration: BoxDecoration(
//                   color: Colors.white,
//                   borderRadius: BorderRadius.circular(20),
//                   border: Border.all(color: Colors.grey.shade300),
//                 ),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     ...controller.rules.map(
//                       (rule) => Padding(
//                         padding: const EdgeInsets.only(bottom: 8),
//                         child: Row(
//                           children: [
//                             Expanded(child: Text("• $rule")),
//                             GestureDetector(
//                               onTap: () => controller.removeRule(rule),
//                               child: const Icon(Icons.close, size: 16),
//                             ),
//                           ],
//                         ),
//                       ),
//                     ),

//                     TextField(
//                       controller: controller.ruleInputController,
//                       onSubmitted: controller.addRule,
//                       decoration: const InputDecoration(
//                         hintText: "พิมพ์กฎแล้วกด Enter",
//                         border: InputBorder.none,
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ),

//             const SizedBox(height: 20),

//             const Text(
//               "ประเภทชุมชน",
//               style: TextStyle(fontWeight: FontWeight.w600),
//             ),
//             const SizedBox(height: 12),

//             Obx(
//               () => Row(
//                 children: [
//                   _privacyButton(
//                     title: "Public",
//                     icon: Icons.public,
//                     selected: !controller.isPrivate.value,
//                     onTap: () => controller.isPrivate.value = false,
//                   ),
//                   const SizedBox(width: 12),
//                   _privacyButton(
//                     title: "Private",
//                     icon: Icons.lock,
//                     selected: controller.isPrivate.value,
//                     onTap: () => controller.isPrivate.value = true,
//                   ),
//                 ],
//               ),
//             ),

//             const SizedBox(height: 24),

//             const Text("แท็ก", style: TextStyle(fontWeight: FontWeight.w600)),
//             const SizedBox(height: 12),

//             Obx(
//               () => Container(
//                 padding: const EdgeInsets.symmetric(vertical: 8),
//                 height: 50,
//                 decoration: BoxDecoration(
//                   color: Colors.white,
//                   borderRadius: BorderRadius.circular(20),
//                   border: Border.all(color: Colors.grey.shade300),
//                 ),
//                 child: controller.selectedTags.isEmpty
//                     ? const Center(
//                         child: Text(
//                           "ยังไม่มีแท็ก",
//                           style: TextStyle(color: Colors.grey),
//                         ),
//                       )
//                     : ListView.builder(
//                         scrollDirection: Axis.horizontal,
//                         padding: const EdgeInsets.symmetric(horizontal: 12),
//                         itemCount: controller.selectedTags.length,
//                         itemBuilder: (context, index) {
//                           final tag = controller.selectedTags[index];

//                           return Padding(
//                             padding: const EdgeInsets.only(right: 8),
//                             child: Chip(
//                               label: Text("#$tag"),
//                               deleteIcon: const Icon(Icons.close, size: 16),
//                               onDeleted: () => controller.removeTag(tag),
//                               backgroundColor: const Color(0xFFFFE4B5),
//                             ),
//                           );
//                         },
//                       ),
//               ),
//             ),

//             const SizedBox(height: 12),

//             OutlinedButton.icon(
//               onPressed: () {
//                 showDialog(
//                   context: context,
//                   builder: (_) => TagSelectionPopup(controller: controller),
//                 );
//               },
//               icon: const Icon(Icons.add),
//               label: const Text("เพิ่มแท็ก"),
//             ),

//             const Text(
//               "รูปปกชุมชน",
//               style: TextStyle(fontWeight: FontWeight.w600),
//             ),
//             const SizedBox(height: 12),

//             Obx(
//               () => GestureDetector(
//                 onTap: controller.pickImage,
//                 child: Container(
//                   height: 150,
//                   decoration: BoxDecoration(
//                     borderRadius: BorderRadius.circular(20),
//                     color: Colors.white,
//                     border: Border.all(color: Colors.grey.shade300),
//                   ),
//                   child: controller.selectedImage.value != null
//                       ? ClipRRect(
//                           borderRadius: BorderRadius.circular(20),
//                           child: Image.file(
//                             controller.selectedImage.value!,
//                             width: double.infinity,
//                             fit: BoxFit.cover,
//                           ),
//                         )
//                       : const Center(child: Text("คลิกเพื่ออัปโหลดรูปภาพ")),
//                 ),
//               ),
//             ),

//             const SizedBox(height: 40),

//             GestureDetector(
//               onTap: controller.createCommunity,
//               child: Container(
//                 height: 50,
//                 decoration: BoxDecoration(
//                   borderRadius: BorderRadius.circular(30),
//                   gradient: const LinearGradient(
//                     colors: [Color(0xFFFFB74D), Color(0xFFFF9800)],
//                   ),
//                 ),
//                 child: const Center(
//                   child: Text(
//                     "สร้าง",
//                     style: TextStyle(
//                       color: Colors.white,
//                       fontWeight: FontWeight.w600,
//                     ),
//                   ),
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   InputDecoration _inputDecoration(String hint) {
//     return InputDecoration(
//       hintText: hint,
//       filled: true,
//       fillColor: Colors.white,
//       border: OutlineInputBorder(
//         borderRadius: BorderRadius.circular(20),
//         borderSide: BorderSide.none,
//       ),
//       contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
//     );
//   }

//   Widget _privacyButton({
//     required String title,
//     required IconData icon,
//     required bool selected,
//     required VoidCallback onTap,
//   }) {
//     return Expanded(
//       child: GestureDetector(
//         onTap: onTap,
//         child: Container(
//           padding: const EdgeInsets.symmetric(vertical: 12),
//           decoration: BoxDecoration(
//             color: selected ? const Color(0xFFE3F2FD) : Colors.white,
//             borderRadius: BorderRadius.circular(30),
//             border: Border.all(
//               color: selected ? Colors.blue : Colors.grey.shade300,
//             ),
//           ),
//           child: Row(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               Icon(icon, size: 18, color: selected ? Colors.blue : Colors.grey),
//               const SizedBox(width: 6),
//               Text(
//                 title,
//                 style: TextStyle(
//                   color: selected ? Colors.blue : Colors.grey,
//                   fontWeight: FontWeight.w600,
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }
import 'package:LinkLian/features/community/widgets/tag_selection_popup.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/create_community_controller.dart';

class CreateCommunityPage extends StatelessWidget {
  const CreateCommunityPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<CreateCommunityController>();

    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F8),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: const SizedBox(),
        title: const Text(
          "สร้างชุมชน",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close, color: Colors.red, size: 20),
            ),
            onPressed: () => Get.back(),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ชื่อชุมชน พร้อม Public/Private ที่มุมขวา
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "ชื่อชุมชน",
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                // ปุ่ม Public/Private แบบกะทัดรัด
                Obx(
                  () => Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _compactPrivacyButton(
                          title: "Public",
                          icon: Icons.public,
                          selected: !controller.isPrivate.value,
                          onTap: () => controller.isPrivate.value = false,
                        ),
                        const SizedBox(width: 4),
                        _compactPrivacyButton(
                          title: "Private",
                          icon: Icons.lock,
                          selected: controller.isPrivate.value,
                          onTap: () => controller.isPrivate.value = true,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextField(
              controller: controller.nameController,
              decoration: _inputDecoration("ระบุชื่อชุมชนของคุณ..."),
            ),

            const SizedBox(height: 20),

            const Text(
              "รายละเอียด",
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: controller.descriptionController,
              maxLines: 3,
              decoration: _inputDecoration("อธิบายเกี่ยวกับชุมชนของคุณ..."),
            ),

            const SizedBox(height: 20),

            // แท็ก
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "แท็ก",
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                OutlinedButton.icon(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (_) => TagSelectionPopup(controller: controller),
                    );
                  },
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text("เพิ่ม"),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    minimumSize: const Size(0, 32),
                    side: BorderSide(color: Colors.green.shade300),
                    foregroundColor: Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            Obx(
              () => controller.selectedTags.isEmpty
                  ? const SizedBox()
                  : Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      height: 50,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        itemCount: controller.selectedTags.length,
                        itemBuilder: (context, index) {
                          final tag = controller.selectedTags[index];

                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: Chip(
                              label: Text("#$tag"),
                              deleteIcon: const Icon(Icons.close, size: 16),
                              onDeleted: () => controller.removeTag(tag),
                              backgroundColor: const Color(0xFFFFE4B5),
                            ),
                          );
                        },
                      ),
                    ),
            ),

            const SizedBox(height: 20),

            const Text(
              "กฎของชุมชน",
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),

            Obx(
              () => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // แสดงกฎที่เพิ่มแล้ว
                  ...controller.rules.map(
                    (rule) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE3F2FD),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                rule,
                                style: const TextStyle(fontSize: 14),
                              ),
                            ),
                            GestureDetector(
                              onTap: () {
                                // นำข้อความกลับมาให้แก้ไข
                                controller.ruleInputController.text = rule;
                                controller.removeRule(rule);
                              },
                              child: Icon(
                                Icons.edit,
                                size: 16,
                                color: Colors.blue.shade700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // ช่องกรอกกฎใหม่
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      // border: Border.all(color: Colors.green.shade300),
                    ),
                    child: TextField(
                      controller: controller.ruleInputController,
                      onSubmitted: (value) {
                        if (value.trim().isNotEmpty) {
                          controller.addRule(value);
                        }
                      },
                      decoration: const InputDecoration(
                        hintText: "ต้องการเพิ่มกฏ แล้วกด Enter",
                        hintStyle: TextStyle(color: Colors.grey, fontSize: 14),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 8,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            const Text(
              "รูปปกชุมชน",
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),

            Obx(
              () => GestureDetector(
                onTap: controller.pickImage,
                child: Container(
                  height: 150,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    color: Colors.white,
                    // border: Border.all(color: Colors.green.shade300, width: 2),
                  ),
                  child: controller.selectedImage.value != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: Image.file(
                            controller.selectedImage.value!,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        )
                      : Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.upload_outlined,
                                size: 40,
                                color: Colors.grey.shade500,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                "คลิกเพื่ออัปโหลดรูปภาพ",
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                ),
              ),
            ),

            const SizedBox(height: 40),

            // ปุ่มสร้าง
            Row(
              children: [
                const Spacer(),
                GestureDetector(
                  onTap: controller.createCommunity,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(30),
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFFB74D), Color(0xFFFF9800)],
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Text(
                          "สร้าง",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(width: 8),
                        Icon(
                          Icons.edit,
                          color: Colors.white,
                          size: 18,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
    );
  }

  Widget _compactPrivacyButton({
    required String title,
    required IconData icon,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: selected ? Colors.black : Colors.grey,
            ),
            const SizedBox(width: 4),
            Text(
              title,
              style: TextStyle(
                color: selected ? Colors.black : Colors.grey,
                fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}