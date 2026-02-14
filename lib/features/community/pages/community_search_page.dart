import 'package:LinkLian/data/model/community_post_model.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/sizes.dart';
import '../../../core/constants/linklian-icon.dart';
import '../../../core/services/api_client.dart';
import '../widgets/community_card_post.dart';

class CommunitySearchPage extends StatefulWidget {
  const CommunitySearchPage({super.key});

  @override
  State<CommunitySearchPage> createState() => _CommunitySearchPageState();
}

class _CommunitySearchPageState extends State<CommunitySearchPage> {
  final TextEditingController _searchController = TextEditingController();
  final ApiClient _apiClient = ApiClient();

  int? _communityId;
  String _communityName = '';
  bool _isLoading = false;
  List<CommunityPostModel> _results = [];
  String? _error;
  String _keyword = '';

  @override
  void initState() {
    super.initState();
    final args = Get.arguments as Map<String, dynamic>?;
    _communityId = args?['communityId'] as int?;
    _communityName = args?['communityName'] as String? ?? '';
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _search(String keyword) async {
    if (keyword.trim().isEmpty) {
      setState(() {
        _results = [];
        _error = null;
        _keyword = '';
      });
      return;
    }

    try {
      setState(() {
        _isLoading = true;
        _error = null;
        _keyword = keyword.trim();
      });

      final response = await _apiClient.get<List<dynamic>>(
        '/community/post/search',
        queryParameters: {
          if (_communityId != null) 'community_id': _communityId,
          'keyword': keyword.trim(),
          'limit': 50,
        },
      );

      final list = response.data ?? [];

      setState(() {
        _results = list
            .map((e) =>
                CommunityPostModel.fromJson(e as Map<String, dynamic>))
            .toList();
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('❌ Community search error: $e');
      setState(() {
        _error = 'ไม่สามารถค้นหาได้';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(LinkLianIcon.back,
              color: AppColors.primaryPalette[800]),
          onPressed: () => Get.back(),
        ),
        title: Text(
          'ค้นหาโพสต์',
          style: TextStyle(
            color: AppColors.primaryPalette[800]!,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          _buildSearchField(),
          Expanded(child: _buildResults()),
        ],
      ),
    );
  }

  Widget _buildSearchField() {
    return Padding(
      padding: const EdgeInsets.all(AppSizes.md),
      child: TextField(
        controller: _searchController,
        autofocus: true,
        onChanged: (value) {
          setState(() {});
          Future.delayed(const Duration(milliseconds: 500), () {
            if (_searchController.text == value) {
              _search(value);
            }
          });
        },
        onSubmitted: _search,
        decoration: InputDecoration(
          hintText: _communityName.isNotEmpty
              ? 'ค้นหาใน $_communityName...'
              : 'ค้นหาโพสต์...',
          prefixIcon:
              Icon(Icons.search, color: AppColors.primaryPalette[600]),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.clear,
                      color: AppColors.primaryPalette[400]),
                  onPressed: () {
                    _searchController.clear();
                    setState(() {
                      _results = [];
                      _keyword = '';
                    });
                  },
                )
              : null,
          filled: true,
          fillColor: AppColors.primaryPalette[50],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide:
                BorderSide(color: AppColors.primaryPalette[300]!),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide:
                BorderSide(color: AppColors.primaryPalette[300]!),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(24),
            borderSide: BorderSide(
                color: AppColors.primaryPalette[500]!, width: 2),
          ),
        ),
      ),
    );
  }

  Widget _buildResults() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return _buildEmptyState(
        icon: Icons.error_outline,
        text: _error!,
      );
    }

    if (_searchController.text.isEmpty) {
      return _buildEmptyState(
        icon: Icons.search,
        text: 'พิมพ์คำค้นหาเพื่อเริ่มต้น',
      );
    }

    if (_results.isEmpty) {
      return _buildEmptyState(
        icon: Icons.search_off,
        text: 'ไม่พบโพสต์ที่ตรงกัน',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.md),
      itemCount: _results.length,
      itemBuilder: (context, index) {
        final post = _results[index];

        return CardPostCommunity(
          post: post,
          highlightKeyword: _keyword,
        );
      },
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String text,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 64,
            color: AppColors.primaryPalette[300],
          ),
          const SizedBox(height: 16),
          Text(
            text,
            style: TextStyle(
              fontSize: 16,
              color: AppColors.primaryPalette[400],
            ),
          ),
        ],
      ),
    );
  }
}
