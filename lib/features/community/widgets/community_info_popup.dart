import 'package:LinkLian/features/community/controllers/community_detail_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_instance/src/extension_instance.dart';
import 'package:get/get_navigation/src/extension_navigation.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/colors.dart';
import '../../../core/services/api_client.dart';

class CommunityInfoPopup extends StatefulWidget {
  final int communityId;

  const CommunityInfoPopup({super.key, required this.communityId});

  @override
  State<CommunityInfoPopup> createState() => _CommunityInfoPopupState();
}

class _CommunityInfoPopupState extends State<CommunityInfoPopup> {
  final ApiClient _apiClient = ApiClient();
  late final CommunityDetailController _detailController;

  bool _isLoading = true;
  String? _error;
  Map<String, dynamic>? _community;

  @override
  void initState() {
    super.initState();
    _detailController = Get.find<CommunityDetailController>();
    _fetchCommunityInfo();
  }

  Future<void> _fetchCommunityInfo() async {
    try {
      final response = await _apiClient.get<Map<String, dynamic>>(
        '/community/detail/${widget.communityId}',
      );
      final root = response.data ?? {};

      if (root['success'] != true) {
        throw Exception(root['message']);
      }

      setState(() {
        _community = root['data'];
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = "ไม่สามารถโหลดข้อมูลได้";
        _isLoading = false;
      });
    }
  }

  @override
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {

        return DraggableScrollableSheet(
          initialChildSize: 0.5,
          minChildSize: 0.5,
          maxChildSize: 1.0,
          expand: false,
          builder: (context, scrollController) {
            return Container(
              decoration: BoxDecoration(
                color: AppColors.primaryPalette[100],
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 12),

                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.primaryPalette[400],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),

                  Expanded(
                    child: _isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : _error != null
                        ? Center(child: Text(_error!))
                        : SingleChildScrollView(
                            controller: scrollController,
                            padding: const EdgeInsets.all(24),
                            child: _buildContent(),
                          ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildContent() {
    final data = _community ?? {};

    final name = data['community_name'] ?? '';
    final description = data['description'] ?? '';
    final rules = List<String>.from(data['rule'] ?? []);
    final isPrivate = data['is_private'] ?? false;

    final createdRaw = data['created_at'];
    String createdFormatted = '';
    if (createdRaw != null) {
      final date = DateTime.parse(createdRaw);
      createdFormatted = DateFormat('d MMMM yyyy', 'th_TH').format(date);
    }

    final firstName = data['first_name'] ?? '';
    final lastName = data['last_name'] ?? '';
    final creatorName = "$firstName $lastName".trim();
    final creatorPic = data['profile_pic'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          name,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: AppColors.primaryPalette[900],
          ),
        ),

        if (description.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text(description, style: const TextStyle(fontSize: 16, height: 1.5)),
        ],

        const SizedBox(height: 20),

        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () {
                Get.toNamed(
                  '/community-members',
                  arguments: {'communityId': widget.communityId},
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primaryPalette[50],
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.primaryPalette[300]!),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.group, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      "${data['member_count'] ?? 0} สมาชิก",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primaryPalette[700],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 8),

            if (isPrivate) ...[
              Row(
                children: [
                  const SizedBox(width: 20, child: Icon(Icons.lock, size: 20)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      "เฉพาะสมาชิกชุมชนเท่านั้นที่มีสิทธิ์โพสต์",
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: AppColors.primaryPalette[700],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],

            Row(
              children: [
                const SizedBox(
                  width: 20,
                  child: Icon(Icons.calendar_today, size: 20),
                ),
                const SizedBox(width: 12),
                Text(
                  "สร้างเมื่อ $createdFormatted",
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: AppColors.primaryPalette[700],
                  ),
                ),
              ],
            ),

            _divider(),
          ],
        ),

        if (rules.isNotEmpty) ...[
          Text(
            "กฎของชุมชน",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: AppColors.primaryPalette[900],
            ),
          ),
          const SizedBox(height: 16),

          ...rules.asMap().entries.map(
            (entry) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "${entry.key + 1}. ",
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      entry.value,
                      style: const TextStyle(fontSize: 16, height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
          ),

          _divider(),
        ],

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              "ผู้ดูแล",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AppColors.primaryPalette[900],
              ),
            ),

            if (data['is_private'] == true && data['is_owner'] == true)
              ElevatedButton(
                onPressed: () {
                  Get.toNamed(
                    '/community-pending',
                    arguments: {'communityId': widget.communityId},
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryPalette[200],
                  foregroundColor: AppColors.primaryPalette[600],
                  side: BorderSide(color: AppColors.primaryPalette[400]!),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 6,
                  ),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: const Text(
                  "คำขอเข้าร่วม",
                  style: TextStyle(fontSize: 13),
                ),
              ),
          ],
        ),
        const SizedBox(height: 24),
        if (creatorName.isEmpty || (firstName.isEmpty && lastName.isEmpty))
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Row(
              children: [
                Text(
                  "ไม่มีผู้ดูแล",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: AppColors.primaryPalette[700],
                  ),
                ),
              ],
            ),
          )
        else
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: AppColors.primaryPalette[200],
                backgroundImage:
                    creatorPic != null && creatorPic.toString().isNotEmpty
                    ? NetworkImage(creatorPic)
                    : null,
                child: creatorPic == null || creatorPic.toString().isEmpty
                    ? Text(
                        creatorName.isNotEmpty
                            ? creatorName[0].toUpperCase()
                            : '?',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 14),
              Text(
                creatorName,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),

        const SizedBox(height: 40),

        const SizedBox(height: 40),
        if (_detailController.community.value?.isMember == true) ...[
          SizedBox(
            width: double.infinity,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.25),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),

              child: ElevatedButton(
                onPressed: () {
                  Get.back();
                  _detailController.confirmLeaveCommunity(
                    _detailController.community.value!.communityName,
                  );
                },
                style: ElevatedButton.styleFrom(
                  elevation: 0,
                  backgroundColor: AppColors.dangerPalette[500],
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Center(
                  child: Text(
                    "ออกจากกลุ่ม",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _divider() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Divider(thickness: 1, color: AppColors.primaryPalette[300]),
    );
  }
}
