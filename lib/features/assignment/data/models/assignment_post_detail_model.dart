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
          attachments:  List<Map<String, dynamic>>.from(subJson['attachments']),
        );
      }
    }

    return AssignmentPostDetailModel(
      post: PostModel.fromJson(json['post']),
      assignment: AssignmentSubmissionInfo.fromJson(json['assignment']),
      submission: parsedSubmission,
    );
  }
}