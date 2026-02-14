import 'package:flutter/material.dart';
import 'package:get/get_core/src/get_main.dart';
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

  bool _isLoading = true;
  String? _error;
  Map<String, dynamic>? _community;

  @override
  void initState() {
    super.initState();
    _fetchCommunityInfo();
  }

  Future<void> _fetchCommunityInfo() async {
    try {
      final response = await _apiClient.get<Map<String, dynamic>>(
        '/community/detail/${widget.communityId}',
      );

      setState(() {
        _community = response.data;
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
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: BoxDecoration(
        color: AppColors.primaryPalette[100],
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.only(top: 16),
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
                ? Center(
                    child: Text(
                      _error!,
                      style: TextStyle(color: AppColors.dangerPalette[500]),
                    ),
                  )
                : _buildContent(),
          ),
        ],
      ),
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

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
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

          const SizedBox(height: 16),
          Text(description, style: const TextStyle(fontSize: 16, height: 1.5)),

          const SizedBox(height: 16),

          GestureDetector(
            onTap: () {
              Get.toNamed(
                '/community-members',
                arguments: {'communityId': widget.communityId},
              );
            },
            child: Row(
              children: [
                const Icon(Icons.group, size: 18),
                const SizedBox(width: 8),
                Text(
                  "สมาชิก ${data['member_count'] ?? 0} คน",
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          if (isPrivate)
            Row(
              children: [
                const Icon(Icons.lock, size: 18),
                const SizedBox(width: 10),
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

          const SizedBox(height: 16),

          Row(
            children: [
              const Icon(Icons.calendar_today, size: 18),
              const SizedBox(width: 10),
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
            children: [
              Text(
                "ผู้ดูแล",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primaryPalette[900],
                ),
              ),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  if (data['is_private'] == true && data['is_owner'] == true)
                    ElevatedButton(
                      onPressed: () {
                        Get.toNamed(
                          '/community-pending',
                          arguments: {'communityId': widget.communityId},
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            AppColors.primaryPalette[400], 
                        foregroundColor: Colors.white,
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
                      child: Text(
                        "คำขอเข้าร่วม",
                        style: TextStyle(fontSize: 13, color: Colors.white),
                      ),
                    ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 16),

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
        ],
      ),
    );
  }

  Widget _divider() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Divider(thickness: 1, color: AppColors.primaryPalette[300]),
    );
  }
}
