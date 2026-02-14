// import 'package:LinkLian/config/app_routes.dart';
// import 'package:LinkLian/core/constants/colors.dart';
// import 'package:LinkLian/features/layout/controllers/navigation_controller.dart';
// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import '../controllers/community_controller.dart';
// import '../../../data/model/community_model.dart';

// class CommuPage extends StatefulWidget {
//   const CommuPage({super.key});

//   @override
//   State<CommuPage> createState() => _CommuPageState();
// }

// class _CommuPageState extends State<CommuPage> {
//   late final CommunityController controller;

//   @override
//   void initState() {
//     super.initState();
//     controller = Get.find<CommunityController>();

//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       controller.loadCommunities();
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       // backgroundColor: const Color(0xFFF5F5F5),
//       body: SafeArea(
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             _buildSearch(),
//             const SizedBox(height: 16),

//             Padding(
//               padding: const EdgeInsets.symmetric(horizontal: 16),
//               child: Row(
//                 children: const [
//                   Text(
//                     'ชุมชนของคุณ',
//                     style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
//                   ),
//                 ],
//               ),
//             ),

//             const SizedBox(height: 12),

//             Expanded(
//               child: Obx(() {
//                 if (controller.isLoading.value) {
//                   return const Center(
//                     child: Column(
//                       mainAxisAlignment: MainAxisAlignment.center,
//                       children: [
//                         CircularProgressIndicator(),
//                         SizedBox(height: 16),
//                         Text('กำลังโหลด...'),
//                       ],
//                     ),
//                   );
//                 }

//                 if (controller.communities.isEmpty) {
//                   return Center(
//                     child: Column(
//                       mainAxisAlignment: MainAxisAlignment.center,
//                       children: [
//                         const Icon(
//                           Icons.groups_outlined,
//                           size: 64,
//                           color: Colors.grey,
//                         ),
//                         const SizedBox(height: 16),
//                         const Text(
//                           'ยังไม่มีชุมชน',
//                           style: TextStyle(fontSize: 16, color: Colors.grey),
//                         ),
//                         const SizedBox(height: 16),
//                         ElevatedButton.icon(
//                           onPressed: () {
//                             print("🔄 Retry button pressed");
//                             controller.loadCommunities();
//                           },
//                           icon: const Icon(Icons.refresh),
//                           label: const Text('ลองอีกครั้ง'),
//                         ),
//                       ],
//                     ),
//                   );
//                 }

//                 return ListView.builder(
//                   padding: const EdgeInsets.symmetric(horizontal: 16),
//                   itemCount: controller.communities.length,
//                   itemBuilder: (context, index) {
//                     final community = controller.communities[index];
//                     return _buildCommunityCard(community);
//                   },
//                 );
//               }),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildSearch() {
//     return Padding(
//       padding: const EdgeInsets.symmetric(horizontal: 16),
//       child: Obx(
//         () => TextField(
//           controller: controller.searchController,
//           onChanged: (value) {
//             controller.searchKeyword.value = value;
//             controller.loadCommunities(keyword: value);
//           },
//           decoration: InputDecoration(
//             hintText: "ค้นหาชุมชน...",
//             prefixIcon: const Icon(Icons.search),

//             suffixIcon: controller.searchKeyword.value.isNotEmpty
//                 ? IconButton(
//                     icon: const Icon(Icons.close),
//                     onPressed: () {
//                       controller.searchController.clear();
//                       controller.searchKeyword.value = "";
//                       controller.loadCommunities();
//                     },
//                   )
//                 : null,

//             filled: true,
//             fillColor: AppColors.buttonPalette[100],
//             focusedBorder: OutlineInputBorder(
//               borderRadius: BorderRadius.circular(60),
//               borderSide: BorderSide(color: AppColors.buttonPalette[800]!),
//             ),
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildCommunityCard(CommunityModel community) {
//     return InkWell(
//       borderRadius: BorderRadius.circular(20),
//       onTap: () {
//         final navController = Get.find<NavigationController>();

//         navController.showCommunityDetail({
//           'communityId': community.communityId,
//         });
//       },
//       child: Container(
//         margin: const EdgeInsets.only(bottom: 16),
//         decoration: BoxDecoration(
//           color: const Color(0xFFEEDBC9),
//           borderRadius: BorderRadius.circular(20),
//         ),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             ClipRRect(
//               borderRadius: const BorderRadius.vertical(
//                 top: Radius.circular(20),
//               ),
//               child: Image.network(
//                 community.imageBanner,
//                 height: 120,
//                 width: double.infinity,
//                 fit: BoxFit.cover,
//                 errorBuilder: (context, error, stackTrace) {
//                   return Container(
//                     height: 120,
//                     color: Colors.grey[300],
//                     alignment: Alignment.center,
//                     child: const Icon(
//                       Icons.image,
//                       size: 40,
//                       color: Colors.grey,
//                     ),
//                   );
//                 },
//               ),
//             ),
//             Padding(
//               padding: const EdgeInsets.all(16),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Row(
//                     children: [
//                       Expanded(
//                         child: Text(
//                           community.communityName,
//                           style: const TextStyle(
//                             fontSize: 18,
//                             fontWeight: FontWeight.bold,
//                           ),
//                         ),
//                       ),
//                       Container(
//                         padding: const EdgeInsets.symmetric(
//                           horizontal: 8,
//                           vertical: 4,
//                         ),
//                         decoration: BoxDecoration(
//                           color: community.isPrivate
//                               ? Colors.red
//                               : Colors.green,
//                           borderRadius: BorderRadius.circular(12),
//                         ),
//                         child: Text(
//                           community.isPrivate ? "Private" : "Public",
//                           style: const TextStyle(
//                             color: Colors.white,
//                             fontSize: 12,
//                           ),
//                         ),
//                       ),
//                     ],
//                   ),
//                   const SizedBox(height: 6),
//                   if (community.description != null &&
//                       community.description!.isNotEmpty)
//                     Text(
//                       community.description!,
//                       style: const TextStyle(
//                         fontSize: 13,
//                         color: Colors.black54,
//                       ),
//                     ),
//                   const SizedBox(height: 8),
//                   Text(
//                     "สมาชิก ${community.memberCount} คน",
//                     style: const TextStyle(fontSize: 13, color: Colors.black54),
//                   ),
//                   const SizedBox(height: 8),
//                   if (community.tags.isNotEmpty)
//                     Wrap(
//                       spacing: 6,
//                       runSpacing: 6,
//                       children: community.tags
//                           .map(
//                             (tag) => Chip(
//                               label: Text(
//                                 "#$tag",
//                                 style: const TextStyle(fontSize: 12),
//                               ),
//                               backgroundColor: Colors.white,
//                             ),
//                           )
//                           .toList(),
//                     ),
//                 ],
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
// // import 'package:LinkLian/config/app_routes.dart';
// // import 'package:LinkLian/core/constants/colors.dart';
// // import 'package:LinkLian/features/layout/controllers/navigation_controller.dart';
// // import 'package:flutter/material.dart';
// // import 'package:get/get.dart';
// // import '../controllers/community_controller.dart';
// // import '../../../data/model/community_model.dart';

// // class CommuPage extends StatefulWidget {
// //   const CommuPage({super.key});

// //   @override
// //   State<CommuPage> createState() => _CommuPageState();
// // }

// // class _CommuPageState extends State<CommuPage> {
// //   late final CommunityController controller;

// //   @override
// //   void initState() {
// //     super.initState();
// //     controller = Get.find<CommunityController>();

// //     WidgetsBinding.instance.addPostFrameCallback((_) {
// //       controller.loadCommunities();
// //     });
// //   }

// //   @override
// //   Widget build(BuildContext context) {
// //     return Scaffold(
// //       backgroundColor: const Color(0xFFF5F5F5),
// //       body: SafeArea(
// //         child: Column(
// //           crossAxisAlignment: CrossAxisAlignment.start,
// //           children: [
// //             const SizedBox(height: 8),
// //             _buildSearch(),
// //             const SizedBox(height: 16),

// //             Padding(
// //               padding: const EdgeInsets.symmetric(horizontal: 16),
// //               child: Row(
// //                 children: const [
// //                   Text(
// //                     'ชุมชนของคุณ',
// //                     style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
// //                   ),
// //                 ],
// //               ),
// //             ),

// //             const SizedBox(height: 12),

// //             Expanded(
// //               child: Obx(() {
// //                 if (controller.isLoading.value) {
// //                   return const Center(
// //                     child: Column(
// //                       mainAxisAlignment: MainAxisAlignment.center,
// //                       children: [
// //                         CircularProgressIndicator(),
// //                         SizedBox(height: 16),
// //                         Text('กำลังโหลด...'),
// //                       ],
// //                     ),
// //                   );
// //                 }

// //                 if (controller.communities.isEmpty) {
// //                   return Center(
// //                     child: Column(
// //                       mainAxisAlignment: MainAxisAlignment.center,
// //                       children: [
// //                         const Icon(
// //                           Icons.groups_outlined,
// //                           size: 64,
// //                           color: Colors.grey,
// //                         ),
// //                         const SizedBox(height: 16),
// //                         const Text(
// //                           'ยังไม่มีชุมชน',
// //                           style: TextStyle(fontSize: 16, color: Colors.grey),
// //                         ),
// //                         const SizedBox(height: 16),
// //                         ElevatedButton.icon(
// //                           onPressed: () {
// //                             print("🔄 Retry button pressed");
// //                             controller.loadCommunities();
// //                           },
// //                           icon: const Icon(Icons.refresh),
// //                           label: const Text('ลองอีกครั้ง'),
// //                         ),
// //                       ],
// //                     ),
// //                   );
// //                 }

// //                 return ListView.builder(
// //                   padding: const EdgeInsets.symmetric(horizontal: 16),
// //                   itemCount: controller.communities.length,
// //                   itemBuilder: (context, index) {
// //                     final community = controller.communities[index];
// //                     return _buildCommunityCard(community);
// //                   },
// //                 );
// //               }),
// //             ),
// //           ],
// //         ),
// //       ),
// //     );
// //   }

// //   Widget _buildSearch() {
// //     return Padding(
// //       padding: const EdgeInsets.symmetric(horizontal: 16),
// //       child: Obx(
// //         () => Container(
// //           height: 45, // ขนาดเล็กลง
// //           decoration: BoxDecoration(
// //             color: const Color(0xFFE8F4F8), // สีฟ้าอ่อนแบบในรูป
// //             borderRadius: BorderRadius.circular(25),
// //             border: Border.all(
// //               color: const Color(0xFFB8D8E8), // ขอบสีฟ้าอ่อน
// //               width: 1,
// //             ),
// //           ),
// //           child: TextField(
// //             controller: controller.searchController,
// //             onChanged: (value) {
// //               controller.searchKeyword.value = value;
// //               controller.loadCommunities(keyword: value);
// //             },
// //             decoration: InputDecoration(
// //               hintText: "ค้นหาชุมชน...",
// //               hintStyle: const TextStyle(
// //                 fontSize: 14,
// //                 color: Color(0xFF9E9E9E),
// //               ),
// //               prefixIcon: const Icon(
// //                 Icons.search,
// //                 color: Color(0xFF757575),
// //                 size: 22,
// //               ),
// //               suffixIcon: controller.searchKeyword.value.isNotEmpty
// //                   ? IconButton(
// //                       icon: const Icon(Icons.close, size: 20),
// //                       color: const Color(0xFF757575),
// //                       onPressed: () {
// //                         controller.searchController.clear();
// //                         controller.searchKeyword.value = "";
// //                         controller.loadCommunities();
// //                       },
// //                     )
// //                   : null,
// //               border: InputBorder.none,
// //               contentPadding: const EdgeInsets.symmetric(
// //                 horizontal: 16,
// //                 vertical: 12,
// //               ),
// //             ),
// //           ),
// //         ),
// //       ),
// //     );
// //   }

// //   Widget _buildCommunityCard(CommunityModel community) {
// //     return InkWell(
// //       borderRadius: BorderRadius.circular(16),
// //       onTap: () {
// //         final navController = Get.find<NavigationController>();
// //         navController.showCommunityDetail({
// //           'communityId': community.communityId,
// //         });
// //       },
// //       child: Container(
// //         margin: const EdgeInsets.only(bottom: 16),
// //         height: 180,
// //         decoration: BoxDecoration(
// //           borderRadius: BorderRadius.circular(16),
// //           boxShadow: [
// //             BoxShadow(
// //               color: Colors.black.withOpacity(0.1),
// //               blurRadius: 8,
// //               offset: const Offset(0, 2),
// //             ),
// //           ],
// //         ),
// //         child: Stack(
// //           children: [
// //             // รูปพื้นหลังแบบจางๆ
// //             ClipRRect(
// //               borderRadius: BorderRadius.circular(16),
// //               child: Stack(
// //                 children: [
// //                   // รูปภาพ
// //                   Image.network(
// //                     community.imageBanner,
// //                     width: double.infinity,
// //                     height: double.infinity,
// //                     fit: BoxFit.cover,
// //                     errorBuilder: (context, error, stackTrace) {
// //                       return Container(
// //                         color: const Color(0xFFFFF8F0),
// //                         child: Center(
// //                           child: Icon(
// //                             Icons.image_outlined,
// //                             size: 50,
// //                             color: Colors.orange[200],
// //                           ),
// //                         ),
// //                       );
// //                     },
// //                   ),
// //                   // Overlay สีครีมจางๆ
// //                   Container(
// //                     decoration: BoxDecoration(
// //                       gradient: LinearGradient(
// //                         begin: Alignment.topCenter,
// //                         end: Alignment.bottomCenter,
// //                         colors: [
// //                           const Color(0xFFFFF8F0).withOpacity(0.5),
// //                           const Color(0xFFFFF8F0).withOpacity(0.),
// //                         ],
// //                       ),
// //                     ),
// //                   ),
// //                 ],
// //               ),
// //             ),

// //             // เนื้อหา
// //             Column(
// //               crossAxisAlignment: CrossAxisAlignment.start,
// //               children: [
// //                 // ส่วนบน - ข้อมูลชุมชน
// //                 Expanded(
// //                   child: Padding(
// //                     padding: const EdgeInsets.all(16),
// //                     child: Column(
// //                       crossAxisAlignment: CrossAxisAlignment.start,
// //                       children: [
// //                         // ชื่อชุมชนและปุ่ม Private/Public
// //                         Row(
// //                           children: [
// //                             Expanded(
// //                               child: Text(
// //                                 community.communityName,
// //                                 style: const TextStyle(
// //                                   fontSize: 18,
// //                                   fontWeight: FontWeight.bold,
// //                                   color: Colors.black87,
// //                                 ),
// //                                 maxLines: 2,
// //                                 overflow: TextOverflow.ellipsis,
// //                               ),
// //                             ),
// //                             const SizedBox(width: 8),
// //                             Container(
// //                               padding: const EdgeInsets.symmetric(
// //                                 horizontal: 10,
// //                                 vertical: 4,
// //                               ),
// //                               decoration: BoxDecoration(
// //                                 color: community.isPrivate
// //                                     ? const Color(0xFFFFEBEE)
// //                                     : const Color(0xFFE8F5E9),
// //                                 borderRadius: BorderRadius.circular(12),
// //                                 border: Border.all(
// //                                   color: community.isPrivate
// //                                       ? const Color(0xFFEF5350)
// //                                       : const Color(0xFF66BB6A),
// //                                   width: 1,
// //                                 ),
// //                               ),
// //                               child: Text(
// //                                 community.isPrivate ? "Private" : "Public",
// //                                 style: TextStyle(
// //                                   color: community.isPrivate
// //                                       ? const Color(0xFFEF5350)
// //                                       : const Color(0xFF66BB6A),
// //                                   fontSize: 11,
// //                                   fontWeight: FontWeight.w600,
// //                                 ),
// //                               ),
// //                             ),
// //                           ],
// //                         ),

// //                         const SizedBox(height: 8),

// //                         // จำนวนสมาชิก
// //                         Row(
// //                           children: [
// //                             const Icon(
// //                               Icons.people_outline,
// //                               size: 16,
// //                               color: Color(0xFF757575),
// //                             ),
// //                             const SizedBox(width: 4),
// //                             Text(
// //                               "สมาชิก ${community.memberCount} คน",
// //                               style: const TextStyle(
// //                                 fontSize: 13,
// //                                 color: Color(0xFF757575),
// //                               ),
// //                             ),
// //                           ],
// //                         ),
// //                       ],
// //                     ),
// //                   ),
// //                 ),

// //                 // แถบสีส้มด้านล่าง สำหรับ Tags
// //                 if (community.tags.isNotEmpty)
// //                   Container(
// //                     width: double.infinity,
// //                     padding: const EdgeInsets.symmetric(
// //                       horizontal: 16,
// //                       vertical: 12,
// //                     ),
// //                     decoration: BoxDecoration(
// //                       color: const Color(0xFFFFCC80), // สีส้มอ่อน
// //                       borderRadius: const BorderRadius.only(
// //                         bottomLeft: Radius.circular(16),
// //                         bottomRight: Radius.circular(16),
// //                       ),
// //                     ),
// //                     child: Wrap(
// //                       spacing: 8,
// //                       runSpacing: 6,
// //                       children: community.tags
// //                           .map(
// //                             (tag) => Container(
// //                               padding: const EdgeInsets.symmetric(
// //                                 horizontal: 8,
// //                                 vertical: 3,
// //                               ),
// //                               decoration: BoxDecoration(
// //                                 color: Colors.white.withOpacity(0.7),
// //                                 borderRadius: BorderRadius.circular(10),
// //                               ),
// //                               child: Text(
// //                                 "#$tag",
// //                                 style: const TextStyle(
// //                                   fontSize: 11,
// //                                   color: Color(0xFFE65100),
// //                                   fontWeight: FontWeight.w600,
// //                                 ),
// //                               ),
// //                             ),
// //                           )
// //                           .toList(),
// //                     ),
// //                   ),
// //               ],
// //             ),
// //           ],
// //         ),
// //       ),
// //     );
// //   }
// // }
import 'package:LinkLian/config/app_routes.dart';
import 'package:LinkLian/core/constants/colors.dart';
import 'package:LinkLian/features/layout/controllers/navigation_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/community_controller.dart';
import '../../../data/model/community_model.dart';

class CommuPage extends StatefulWidget {
  const CommuPage({super.key});

  @override
  State<CommuPage> createState() => _CommuPageState();
}

class _CommuPageState extends State<CommuPage> {
  late final CommunityController controller;

  @override
  void initState() {
    super.initState();
    controller = Get.find<CommunityController>();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (controller.communities.isEmpty) {
        controller.loadCommunities(
          keyword: controller.searchKeyword.value.isEmpty
              ? null
              : controller.searchKeyword.value,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 255, 255, 255),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            _buildSearch(),
            const SizedBox(height: 16),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Obx(
                () => Row(
                  children: [
                    Expanded(
                      child: Text(
                        controller.searchKeyword.value.isEmpty
                            ? 'ชุมชนของคุณ'
                            : 'ผลลัพธ์สำหรับ "${controller.searchKeyword.value}"',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),

            Expanded(
              child: Obx(() {
                if (controller.isLoading.value) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('กำลังโหลด...'),
                      ],
                    ),
                  );
                }

                if (controller.communities.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.groups_outlined,
                          size: 64,
                          color: Colors.grey,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'ยังไม่มีชุมชน',
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: () {
                            print("🔄 Retry button pressed");
                            controller.loadCommunities();
                          },
                          icon: const Icon(Icons.refresh),
                          label: const Text('ลองอีกครั้ง'),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: controller.communities.length,
                  itemBuilder: (context, index) {
                    final community = controller.communities[index];
                    return _buildCommunityCard(community);
                  },
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearch() {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16),
    child: Obx(
      () => SizedBox(
        height: 45,
        child: TextField(
          controller: controller.searchController,
          onChanged: (value) {
            controller.searchKeyword.value = value;
            controller.loadCommunities(keyword: value);
          },
          decoration: InputDecoration(
            hintText: "ค้นหาชุมชน...",
            hintStyle: const TextStyle(
              fontSize: 14,
              color: Color(0xFF9E9E9E),
            ),

            prefixIcon: Icon(
              Icons.search,
              color: AppColors.buttonPalette[600]!,
              size: 22,
            ),

            suffixIcon: controller.searchKeyword.value.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    color: AppColors.buttonPalette[600],
                    onPressed: () {
                      controller.searchController.clear();
                      controller.searchKeyword.value = "";
                      controller.loadCommunities();
                    },
                  )
                : null,

            filled: true,
            fillColor: AppColors.buttonPalette[100],

            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
              borderSide: BorderSide(
                color: AppColors.buttonPalette[500]!,
                width: 1.5, 
              ),
            ),

            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
              borderSide: BorderSide(
                color: AppColors.buttonPalette[500]!,
                width: 1.7, 
              ),
            ),

            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
          ),
        ),
      ),
    ),
  );
}


  Widget _buildCommunityCard(CommunityModel community) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () {
        final navController = Get.find<NavigationController>();
        navController.showCommunityDetail({
          'communityId': community.communityId,
        });
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        height: 230,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            // ส่วนบน (50%) - รูปพื้นหลัง
            Expanded(
              flex: 1,
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(14),
                  topRight: Radius.circular(14),
                ),
                child: Image.network(
                  community.imageBanner,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: const Color(0xFFE0E0E0),
                      child: Center(
                        child: Icon(
                          Icons.image_outlined,
                          size: 50,
                          color: Colors.grey[400],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),

            // ส่วนล่าง (50%) - ข้อมูล
            Expanded(
              flex: 1,
              child: Container(
                decoration: const BoxDecoration(
                  color: Color(0xFFFFCF9A), // สีครีมส้มใหม่
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(14),
                    bottomRight: Radius.circular(14),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 1. ชื่อชุมชนและปุ่ม Private/Public
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    community.communityName,
                                    style: const TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF212121),
                                      height: 1.2,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: community.isPrivate
                                        ? const Color(0xFFEF5350)
                                        : const Color(0xFF66BB6A),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    community.isPrivate ? "Private" : "Public",
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 4),

                            Row(
                              children: [
                                const SizedBox(width: 4),
                                Text(
                                  "สมาชิก ${community.memberCount} คน",
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: Color.fromARGB(255, 0, 0, 0),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),

                            const Spacer(),
                          ],
                        ),
                      ),
                    ),

                    if (community.tags.isNotEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        child: Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: community.tags
                              .map(
                                (tag) => Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 9,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    "#$tag",
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: Color(0xFF616161),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
