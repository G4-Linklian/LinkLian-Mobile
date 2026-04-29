import 'community_comment_model.dart';

class CommunityCommentPageResult {
  final List<CommunityCommentModel> comments;
  final int? nextCursor;
  final bool hasMore;

  CommunityCommentPageResult({
    required this.comments,
    required this.nextCursor,
    required this.hasMore,
  });
}