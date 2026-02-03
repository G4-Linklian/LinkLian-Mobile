// filepath: /Users/thunyatorn/LinkLian-Mobile/lib/features/classes/widgets/class_info_popup.dart
import 'package:flutter/material.dart';
import '../../../core/constants/colors.dart';
import '../../../core/services/api_client.dart';

/// Class Info Popup showing location, schedule, members, and teacher
class ClassInfoPopup extends StatefulWidget {
  final int sectionId;

  const ClassInfoPopup({super.key, required this.sectionId});

  @override
  State<ClassInfoPopup> createState() => _ClassInfoPopupState();
}

class _ClassInfoPopupState extends State<ClassInfoPopup> {
  final ApiClient _apiClient = ApiClient();
  final ScrollController _membersScrollController = ScrollController();
  
  bool _isLoading = true;
  String? _error;
  
  // Data
  List<Map<String, dynamic>> _schedules = [];
  List<Map<String, dynamic>> _members = [];
  List<Map<String, dynamic>> _educators = [];
  String _roomLocation = '';

  @override
  void initState() {
    super.initState();
    _fetchClassInfo();
  }

  Future<void> _fetchClassInfo() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      // Fetch class info from API
      final response = await _apiClient.get<Map<String, dynamic>>(
        '/social-feed/class-info/${widget.sectionId}',
      );

      final data = response.data;
      if (data != null) {
        setState(() {
          _schedules = List<Map<String, dynamic>>.from(data['schedules'] ?? []);
          _members = List<Map<String, dynamic>>.from(data['members'] ?? []);
          _educators = List<Map<String, dynamic>>.from(data['educators'] ?? []);
          _roomLocation = data['room_location'] ?? '';
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('❌ Error fetching class info: $e');
      setState(() {
        _error = 'ไม่สามารถโหลดข้อมูลได้';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: BoxDecoration(
        color: AppColors.primaryPalette[100],
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 16),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.primaryPalette[400],
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Content
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(child: Text(_error!, style: TextStyle(color: AppColors.dangerPalette[500])))
                    : SingleChildScrollView(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Section: สถานที่
                            _buildSectionTitle('สถานที่'),
                            const SizedBox(height: 8),
                            Text(
                              _roomLocation.isNotEmpty ? _roomLocation : 'ไม่ระบุ',
                              style: TextStyle(
                                fontSize: 14,
                                color: AppColors.primaryPalette[800],
                              ),
                            ),

                            const SizedBox(height: 20),

                            // Section: ตารางเรียน
                            _buildSectionTitle('ตารางเรียน'),
                            const SizedBox(height: 8),
                            if (_schedules.isEmpty)
                              Text(
                                'ไม่มีตารางเรียน',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: AppColors.primaryPalette[600],
                                ),
                              )
                            else
                              ..._schedules.map((schedule) => _buildScheduleItem(schedule)),

                            const SizedBox(height: 20),

                            // Section: สมาชิก
                            _buildSectionTitle('สมาชิก'),
                            const SizedBox(height: 8),
                            if (_members.isEmpty)
                              Text(
                                'ไม่มีสมาชิก',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: AppColors.primaryPalette[600],
                                ),
                              )
                            else
                              Container(
                                constraints: const BoxConstraints(maxHeight: 200),
                                decoration: BoxDecoration(
                                  border: Border.all(color: AppColors.primaryPalette[200]!),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Scrollbar(
                                  controller: _membersScrollController,
                                  thumbVisibility: true,
                                  child: ListView.builder(
                                    controller: _membersScrollController,
                                    shrinkWrap: true,
                                    itemCount: _members.length,
                                    itemBuilder: (context, index) {
                                      final member = _members[index];
                                      return _buildMemberItem(index + 1, member);
                                    },
                                  ),
                                ),
                              ),

                            const SizedBox(height: 20),

                            // Section: ผู้สอน
                            _buildSectionTitle('ผู้สอน'),
                            const SizedBox(height: 8),
                            if (_educators.isEmpty)
                              Text(
                                'ไม่มีข้อมูลผู้สอน',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: AppColors.primaryPalette[600],
                                ),
                              )
                            else
                              ..._educators.map((educator) => _buildEducatorItem(educator)),

                            const SizedBox(height: 20),
                          ],
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: AppColors.primaryPalette[900],
      ),
    );
  }

  Widget _buildScheduleItem(Map<String, dynamic> schedule) {
    final dayOfWeek = _getDayName(schedule['day_of_week']);
    final startTime = schedule['start_time'] ?? '';
    final endTime = schedule['end_time'] ?? '';
    final room = schedule['room'] as Map<String, dynamic>?;
    final roomNumber = room?['room_number'] ?? '';

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(Icons.schedule, size: 16, color: AppColors.primaryPalette[600]),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '$dayOfWeek $startTime - $endTime ${roomNumber.isNotEmpty ? '(ห้อง $roomNumber)' : ''}',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.primaryPalette[800],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMemberItem(int index, Map<String, dynamic> member) {
    final studentCode = member['student_code']?.toString() ?? '';
    final displayName = member['display_name'] ?? 'ไม่ระบุชื่อ';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Row(
        children: [
          Text(
            '$index.',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.primaryPalette[700],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayName,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.primaryPalette[800],
                  ),
                ),
                if (studentCode.isNotEmpty)
                  Text(
                    'รหัส: $studentCode',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.primaryPalette[600],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEducatorItem(Map<String, dynamic> educator) {
    final displayName = educator['display_name'] ?? 'ไม่ระบุชื่อ';
    final profilePic = educator['profile_pic'] as String?;
    final isMainTeacher = educator['is_main_teacher'] as bool? ?? false;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          // Avatar
          CircleAvatar(
            radius: 16,
            backgroundColor: AppColors.primaryPalette[200],
            backgroundImage: profilePic != null && profilePic.isNotEmpty
                ? NetworkImage(profilePic)
                : null,
            child: profilePic == null || profilePic.isEmpty
                ? Text(
                    displayName.isNotEmpty ? displayName[0].toUpperCase() : '?',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryPalette[700],
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              displayName,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.primaryPalette[800],
              ),
            ),
          ),
          if (isMainTeacher)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primaryPalette[200],
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                'ครูผู้สอนหลัก',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryPalette[700],
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _getDayName(dynamic dayOfWeek) {
    final day = int.tryParse(dayOfWeek?.toString() ?? '') ?? 0;
    switch (day) {
      case 1: return 'วันจันทร์';
      case 2: return 'วันอังคาร';
      case 3: return 'วันพุธ';
      case 4: return 'วันพฤหัสบดี';
      case 5: return 'วันศุกร์';
      case 6: return 'วันเสาร์';
      case 7: return 'วันอาทิตย์';
      default: return 'ไม่ระบุ';
    }
  }
}
