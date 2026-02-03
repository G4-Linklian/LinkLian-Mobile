import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/sizes.dart';
import '../../../core/constants/linklian-icon.dart';
import '../../../core/services/api_client.dart';
import '../../../data/model/post_model.dart';
import '../widgets/card_post.dart';

class SearchPostPage extends StatefulWidget {
  const SearchPostPage({super.key});

  @override
  State<SearchPostPage> createState() => _SearchPostPageState();
}

class _SearchPostPageState extends State<SearchPostPage> {
  final TextEditingController _searchController = TextEditingController();
  final ApiClient _apiClient = ApiClient();
  
  int? _sectionId;
  String _subjectName = '';
  bool _isLoading = false;
  List<PostModel> _results = [];
  String? _error;
  String _keyword = '';

  @override
  void initState() {
    super.initState();
    final args = Get.arguments as Map<String, dynamic>?;
    _sectionId = args?['sectionId'] as int?;
    _subjectName = args?['subjectName'] as String? ?? '';
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
        '/social-feed/post/search',
        queryParameters: {
          if (_sectionId != null) 'section_id': _sectionId,
          'keyword': keyword.trim(),
          'limit': 50,
        },
      );

      final list = response.data ?? [];
      setState(() {
        _results = list
            .map((e) => PostModel.fromJson(e as Map<String, dynamic>))
            .toList();
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('❌ Search error: $e');
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
          icon: Icon(LinkLianIcon.back, color: AppColors.primaryPalette[800]),
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
          // Search Input
          Padding(
            padding: const EdgeInsets.all(AppSizes.md),
            child: TextField(
              controller: _searchController,
              autofocus: true,
              onChanged: (value) {
                setState(() {}); // rebuild to update suffix
                // Debounce search
                Future.delayed(const Duration(milliseconds: 500), () {
                  if (_searchController.text == value) {
                    _search(value);
                  }
                });
              },
              onSubmitted: _search,
              decoration: InputDecoration(
                hintText: _subjectName.isNotEmpty 
                    ? 'ค้นหาใน $_subjectName...' 
                    : 'ค้นหาโพสต์...',
                prefixIcon: Icon(Icons.search, color: AppColors.primaryPalette[600]),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.clear, color: AppColors.primaryPalette[400]),
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
                  borderSide: BorderSide(color: AppColors.primaryPalette[300]!),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: AppColors.primaryPalette[300]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide(color: AppColors.primaryPalette[500]!, width: 2),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              ),
            ),
          ),

          // Results
          Expanded(
            child: _buildResults(),
          ),
        ],
      ),
    );
  }

  Widget _buildResults() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Text(
          _error!,
          style: TextStyle(color: AppColors.dangerPalette[500]),
        ),
      );
    }

    if (_searchController.text.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search, size: 64, color: AppColors.primaryPalette[300]),
            const SizedBox(height: 16),
            Text(
              'พิมพ์คำค้นหาเพื่อเริ่มต้น',
              style: TextStyle(
                fontSize: 16,
                color: AppColors.primaryPalette[400],
              ),
            ),
          ],
        ),
      );
    }

    if (_results.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: AppColors.primaryPalette[200]),
            const SizedBox(height: 16),
            Text(
              'ไม่พบโพสต์ที่ตรงกัน',
              style: TextStyle(
                fontSize: 16,
                color: AppColors.primaryPalette[400],
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.md),
      itemCount: _results.length,
      itemBuilder: (context, index) {
        final post = _results[index];
        return CardPost(
          post: post,
          highlightKeyword: _keyword,
        );
      },
    );
  }
}
