import 'dart:async';
import 'dart:ui';
import 'package:LinkLian/config/app_routes.dart';
import 'package:LinkLian/core/constants/colors.dart';
import 'package:LinkLian/features/community/presentation/controllers/community_detail_controller.dart';
import 'package:LinkLian/features/layout/controllers/navigation_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/community_controller.dart';
import '../../data/models/community_model.dart';

class CommuPage extends StatefulWidget {
  const CommuPage({super.key});

  @override
  State<CommuPage> createState() => _CommuPageState();
}

class _CommuPageState extends State<CommuPage> {
  late final CommunityController controller;
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

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
              child: Obx(() {
                final isSearching = controller.searchKeyword.value.isNotEmpty;

                return Row(
                  children: [
                    Expanded(
                      child: Text(
                        isSearching
                            ? 'ผลลัพธ์สำหรับ "${controller.searchKeyword.value}"'
                            : 'ชุมชนของคุณ',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),

                    if (isSearching) ...[
                      const SizedBox(width: 8),
                      _buildJoinToggle(),
                    ],
                  ],
                );
              }),
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
                        Icon(
                          Icons.groups_outlined,
                          size: 70,
                          color: AppColors.primaryPalette[700],
                        ),
                        Text(
                          'ยังไม่มีชุมชน',
                          style: TextStyle(
                            fontSize: 16,
                            color: AppColors.primaryPalette[700],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
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

              if (_debounce?.isActive ?? false) {
                _debounce!.cancel();
              }

              _debounce = Timer(const Duration(milliseconds: 500), () {
                controller.loadCommunities(
                  keyword: value.isEmpty ? null : value,
                );
              });
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
              fillColor: AppColors.buttonPalette[100]!.withValues(alpha: 0.2),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
                borderSide: BorderSide(
                  color: AppColors.buttonPalette[300]!,
                  width: 1.2,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
                borderSide: BorderSide(
                  color: AppColors.buttonPalette[300]!,
                  width: 1.2,
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

  Widget _buildJoinToggle() {
    return Obx(() {
      final selected = controller.joinFilter.value;

      return Container(
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.primaryPalette[300]!, width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildSmallToggleItem(
              title: "เข้าร่วมแล้ว",
              isSelected: selected == JoinFilter.joined,
              onTap: () {
                controller.joinFilter.value = JoinFilter.joined;
                controller.loadCommunities(
                  keyword: controller.searchKeyword.value,
                );
              },
            ),
            _buildSmallToggleItem(
              title: "ยังไม่เข้าร่วม",
              isSelected: selected == JoinFilter.notJoined,
              onTap: () {
                controller.joinFilter.value = JoinFilter.notJoined;
                controller.loadCommunities(
                  keyword: controller.searchKeyword.value,
                );
              },
            ),
          ],
        ),
      );
    });
  }

  Widget _buildSmallToggleItem({
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primaryPalette[300]
              : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Text(
          title,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isSelected
                ? AppColors.primaryPalette[900]
                : AppColors.primaryPalette[500],
          ),
        ),
      ),
    );
  }

  Widget _buildCommunityCard(CommunityModel community) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        final navController = Get.find<NavigationController>();
        navController.showCommunityDetail({
          'communityId': community.communityId,
        });
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        height: 200,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 10,
              spreadRadius: 2,
              offset: const Offset(0, 0),
            ),
          ],
          image: DecorationImage(
            image: NetworkImage(community.imageBanner),
            fit: BoxFit.cover,
            onError: (error, stackTrace) {},
          ),
        ),

        child: Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,

                  stops: const [0.0, 0.55, 1.0],
                  colors: [
                    AppColors.primaryPalette[100]!.withValues(alpha: 0.95),
                    Colors.black.withValues(alpha: 0.12),
                    Colors.transparent,
                  ],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Spacer(),

                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.primaryPalette[100],
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(20),
                        bottomRight: Radius.circular(20),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                community.communityName,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.black,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "สมาชิก ${community.memberCount} คน",
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.black.withValues(alpha: 0.7),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(width: 12),

                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.black.withValues(alpha: 0.1),
                                blurRadius: 3,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Text(
                            community.status == 'inactive'
                                ? "ชุมชนถูกปิด"
                                : community.isPrivate
                                ? "กลุ่มส่วนตัว"
                                : "กลุ่มสาธารณะ",
                            style: TextStyle(
                              color: community.status == 'inactive'
                                  ? Colors.grey
                                  : community.isPrivate
                                  ? AppColors.dangerPalette[500]
                                  : AppColors.successPalette[700],
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            if (community.isOwner == true)
              Positioned(
                top: 1,
                right: 4,
                child: PopupMenuButton<String>(
                  icon: ClipOval(
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: AppColors.primaryPalette[800]!.withValues(alpha: 
                            0.25,
                          ),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.25),
                            width: 0.6,
                          ),
                        ),
                        child: const Icon(
                          Icons.more_horiz,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ),

                  onSelected: (value) async {
                    if (value == 'edit') {
                      final detailController =
                          Get.find<CommunityDetailController>();

                      detailController.initFromOutside(community.communityId);

                      final result = await Get.toNamed(
                        AppRoutes.createCommunity,
                        arguments: {
                          'isEdit': true,
                          'community': detailController.community.value,
                        },
                      );

                      if (result == true) {
                        controller.loadCommunities();
                      }
                    }

                    if (value == 'delete') {
                      final confirm = await Get.dialog<bool>(
                        AlertDialog(
                          title: const Text("ลบชุมชน"),
                          content: const Text("คุณต้องการลบชุมชนนี้หรือไม่"),
                          actions: [
                            TextButton(
                              onPressed: () => Get.back(result: false),
                              child: const Text("ยกเลิก"),
                            ),
                            TextButton(
                              onPressed: () => Get.back(result: true),
                              child: Text(
                                'ลบ',
                                style: TextStyle(
                                  color: AppColors.dangerPalette[500],
                                ),
                              ),
                            ),
                          ],
                        ),
                      );

                      if (confirm == true) {
                        controller.deleteCommunity(community.communityId);
                      }
                    }
                  },

                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: ListTile(
                        leading: Icon(Icons.edit),
                        title: Text('แก้ไขชุมชน'),
                      ),
                    ),

                    PopupMenuItem(
                      value: 'delete',
                      child: ListTile(
                        leading: Icon(
                          Icons.delete,
                          color: AppColors.dangerPalette[500],
                        ),
                        title: Text(
                          'ลบชุมชน',
                          style: TextStyle(color: AppColors.dangerPalette[700]),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
