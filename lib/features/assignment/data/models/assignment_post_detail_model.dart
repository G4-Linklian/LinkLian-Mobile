import '../../../shared/models/post_model.dart';
import 'assignment_submission_info.dart';
import 'submission_model.dart';

class AssignmentPostDetailModel {
  final PostModel post;
  final AssignmentSubmissionInfo assignment;
  final SubmissionModel? submission;

  AssignmentPostDetailModel({
    required this.post,
    required this.assignment,
    this.submission,
  });

  factory AssignmentPostDetailModel.fromJson(Map<String, dynamic> json) {
    // Backend currently returns attachments at top-level `data.attachments`
    // while PostModel expects them inside `post.attachments`.
    final rawPost = (json['post'] as Map<String, dynamic>? ?? <String, dynamic>{});
    final postJson = Map<String, dynamic>.from(rawPost);
    if ((postJson['attachments'] == null || (postJson['attachments'] as List?)?.isEmpty == true) &&
        json['attachments'] is List) {
      postJson['attachments'] = json['attachments'];
    }

    // Parse submission with explicit attachments handling
    SubmissionModel? parsedSubmission;
    if (json['submission'] != null) {
      final subJson = json['submission'] as Map<String, dynamic>;
      parsedSubmission = SubmissionModel.fromJson(subJson);

      // Ensure attachments are populated even if .g.dart is outdated
      if (parsedSubmission.attachments.isEmpty &&
          subJson['attachments'] != null &&
          (subJson['attachments'] as List).isNotEmpty) {
        parsedSubmission = SubmissionModel(
          submissionId: parsedSubmission.submissionId,
          assignmentId: parsedSubmission.assignmentId,
          groupId: parsedSubmission.groupId,
          groupName: parsedSubmission.groupName,
          submittedAt: parsedSubmission.submittedAt,
          markedAt: parsedSubmission.markedAt,
          score: parsedSubmission.score,
          feedback: parsedSubmission.feedback,
          attachments: List<Map<String, dynamic>>.from(subJson['attachments']),
          isGroup: parsedSubmission.isGroup,
        );
      }
    }

    return AssignmentPostDetailModel(
      post: PostModel.fromJson(postJson),
      assignment: AssignmentSubmissionInfo.fromJson(json['assignment']),
      submission: parsedSubmission,
    );
  }
}
