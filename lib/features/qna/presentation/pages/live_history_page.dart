import 'package:LinkLian/config/app_routes.dart';
import 'package:LinkLian/core/constants/colors.dart';
import 'package:LinkLian/core/constants/linklian-icon.dart';
import 'package:LinkLian/features/shared/repositories/qna_repository.dart';
import 'package:LinkLian/features/qna/data/models/qa_live_model.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:async';

class LiveHistoryPage extends StatefulWidget {
  const LiveHistoryPage({super.key});

  @override
  State<LiveHistoryPage> createState() => _LiveHistoryPageState();
}

class _LiveHistoryPageState extends State<LiveHistoryPage> {
  final QnaRepository _repo = QnaRepository();

  bool _isLoading = true;
  String? _errorText;
  List<QaLive> _historyItems = const [];
  List<QaLive> _filteredItems = const [];

  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocus = FocusNode();
  Timer? _debounce;

  int? get _sectionId {
    final raw = Get.arguments?['sectionId'];
    if (raw is int) return raw;
    if (raw is num) return raw.toInt();
    if (raw is String) return int.tryParse(raw);
    return null;
  }

  @override
  void initState() {
    super.initState();
    _loadHistory();
    _searchController.addListener(() {
      setState(() {});
    });
  }

  Future<void> _loadHistory() async {
    final sectionId = _sectionId;
    if (sectionId == null) {
      setState(() {
        _isLoading = false;
        _errorText = 'ไม่พบข้อมูลห้องเรียนสำหรับดูประวัติ Live';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorText = null;
    });

    try {
      final history = await _repo.getLiveHistory(sectionId: sectionId);

      // Filter out active/ongoing lives - only show closed ones
      QaLive? activeLive;
      try {
        activeLive = await _repo.getActiveLive(sectionId: sectionId);
      } catch (e) {
        // No active live - that's fine, just continue with history
        activeLive = null;
      }
      final activeId = activeLive?.qaLiveId;

      final closedLives = history
          .where((live) => live.qaLiveId != activeId)
          .toList();

      closedLives.sort((a, b) {
        final aTime = a.createdAt;
        final bTime = b.createdAt;
        return bTime.compareTo(aTime);
      });

      if (!mounted) return;
      setState(() {
        _historyItems = closedLives;
        _filteredItems = closedLives;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorText = 'โหลดประวัติ Live ไม่สำเร็จ';
      });
    }
  }

  String? _formatOnlyDate(DateTime? date) {
    if (date == null) return null;
    return '${date.day}/${date.month}/${date.year}';
  }

  void _openHistoryLive(QaLive liveItem, {bool isHistoryMode = true}) {
    final sectionId = _sectionId;
    final qaLiveId = liveItem.qaLiveId;
    
    if (sectionId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ไม่พบข้อมูลห้องเรียน')),
      );
      return;
    }
    
    if (qaLiveId <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ข้อมูลไลฟ์ไม่ถูกต้อง')),
      );
      return;
    }

    final args = {
      'qaLiveId': qaLiveId,
      'sectionId': sectionId,
      'isHistoryMode': isHistoryMode,
    };

    Get.toNamed(AppRoutes.livePage, arguments: args);
  }

  void _onSearchChanged(String keyword) {
    if (_debounce?.isActive ?? false) {
      _debounce!.cancel();
    }

    _debounce = Timer(const Duration(milliseconds: 400), () {
      _filterLives(keyword);
    });
  }

  void _filterLives(String keyword) {
    if (keyword.trim().isEmpty) {
      setState(() {
        _filteredItems = _historyItems;
      });
      return;
    }

    final lowerKeyword = keyword.toLowerCase().trim();
    final filtered = _historyItems.where((item) {
      final title = (item.liveTitle ?? '').toLowerCase();
      return title.contains(lowerKeyword);
    }).toList();

    // เรียงตามเวลาล่าสุด
    filtered.sort((a, b) {
      final aTime = a.createdAt;
      final bTime = b.createdAt;
      return bTime.compareTo(aTime);
    });

    setState(() {
      _filteredItems = filtered;
    });
  }

  void _resetSearch() {
    _searchFocus.unfocus();
    setState(() {
      _searchController.clear();
      _filteredItems = _historyItems;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        shadowColor: Colors.black.withValues(alpha: 0.1),
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: const Text(
          'ประวัติไลฟ์',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
      ),
      body: Column(
        children: [
          const SizedBox(height: 16),
          _buildSearch(),
          const SizedBox(height: 10),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildSearch() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SizedBox(
        height: 45,
        child: TextField(
          controller: _searchController,
          focusNode: _searchFocus,
          onChanged: _onSearchChanged,
          decoration: InputDecoration(
            hintText: "ค้นหาประวัติไลฟ์...",
            hintStyle: const TextStyle(fontSize: 14, color: Color(0xFF9E9E9E)),
            prefixIcon: Icon(
              Icons.search,
              color: AppColors.buttonPalette[600],
              size: 22,
            ),
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    color: AppColors.buttonPalette[600],
                    onPressed: _resetSearch,
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
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorText != null) {
      return Center(child: Text(_errorText!));
    }

    if (_historyItems.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              'ยังไม่มีประวัติไลฟ์',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    if (_filteredItems.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              'ไม่พบผลการค้นหา',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadHistory,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: ListView.separated(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(8),
            itemCount: _filteredItems.length,
            separatorBuilder: (_, _) => Divider(
              height: 1,
              thickness: 1,
              color: const Color(0xFFF0F0F0),
              indent: 16,
              endIndent: 16,
            ),
            itemBuilder: (_, index) {
              final item = _filteredItems[index];
              return _buildLiveCard(
                item: item,
                onTap: () => _openHistoryLive(item, isHistoryMode: true),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildLiveCard({required QaLive item, required VoidCallback onTap}) {
    final title = item.liveTitle?.trim().isNotEmpty == true
        ? item.liveTitle!
        : 'Live #${item.qaLiveId}';
    final liveDate = _formatOnlyDate(item.createdAt);

    return InkWell(
      onTap: onTap,
      child: Container(
        color: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.primaryPalette[100],
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                LinkLianIcon.live,
                color: AppColors.primaryPalette[500],
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                  const SizedBox(height: 6),
                  if (liveDate != null)
                    Text(
                      'วันที่ : $liveDate',
                      style: const TextStyle(
                        color: Color(0xFF6B7280),
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 8),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }
}
