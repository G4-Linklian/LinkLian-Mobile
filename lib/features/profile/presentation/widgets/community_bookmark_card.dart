import 'package:LinkLian/features/community/presentation/widgets/community_card_post.dart';
import 'package:flutter/material.dart';
import '../../../community/data/repositories/community_bookmark_repository.dart';
import '../../../community/data/models/community_post_model.dart';

class BookmarkCommunityPage extends StatefulWidget {
  const BookmarkCommunityPage({super.key});

  @override
  State<BookmarkCommunityPage> createState() => _BookmarkCommunityPageState();
}

class _BookmarkCommunityPageState extends State<BookmarkCommunityPage> {
  final _repo = CommunityBookmarkRepository();

  List<CommunityPostModel> _posts = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadBookmarks();
  }

  Future<void> _loadBookmarks() async {
    try {
      final result = await _repo.getMyBookmarks();

      setState(() {
        _posts = result;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_posts.isEmpty) {
      return const Scaffold(body: Center(child: Text("ยังไม่มีบุ๊กมาร์ก")));
    }

    return Scaffold(
      appBar: AppBar(title: const Text("บุ๊กมาร์ก")),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _posts.length,
        itemBuilder: (context, index) {
          return CardPostCommunity(post: _posts[index],showMoreButton: false,);
        },
      ),
    );
  }
}
