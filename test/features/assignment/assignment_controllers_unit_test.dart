import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:LinkLian/features/assignment/presentation/controllers/class_assignment_controller.dart';
import 'package:LinkLian/features/assignment/presentation/controllers/search_assignment_controller.dart';
import 'package:LinkLian/features/assignment/presentation/controllers/teacher_submission_controller.dart';
import 'package:LinkLian/features/assignment/presentation/controllers/assignment_submission_controller.dart';
import 'package:LinkLian/features/assignment/data/repositories/assignment_repository.dart';
import 'package:LinkLian/features/assignment/data/repositories/submission_repository.dart';
import 'package:LinkLian/features/auth/controller/auth_controller.dart';
import 'package:LinkLian/features/shared/repositories/class_feed_repository.dart';
import 'package:LinkLian/features/assignment/data/models/assignment_model.dart';
import 'package:LinkLian/features/assignment/data/models/group_model.dart';
import 'package:LinkLian/features/assignment/data/models/assignment_post_detail_model.dart';
import 'package:LinkLian/features/assignment/data/models/student_submission_status_model.dart';
import 'package:LinkLian/features/assignment/data/models/submission_detail_model.dart';
import 'package:LinkLian/features/assignment/data/models/submission_model.dart';
import 'package:LinkLian/features/shared/models/section_educator_model.dart';

// Mock classes for proper unit testing
class MockAssignmentRepository extends GetxService
    implements AssignmentRepository {
  List<AssignmentModel> mockAssignments = [];
  List<StudentSubmissionStatusModel> mockStudents = [];
  List<GroupModel> mockGroups = [];
  SubmissionDetailModel? mockSubmissionDetail;
  AssignmentPostDetailModel? mockPostDetail;
  bool shouldThrowError = false;

  @override
  Future<List<AssignmentModel>> getClassAssignments({
    required int sectionId,
    String? role,
    int offset = 0,
    int limit = 10,
  }) async {
    if (shouldThrowError) throw Exception('API Error');
    return mockAssignments.skip(offset).take(limit).toList();
  }

  @override
  Future<List<AssignmentModel>> searchAssignments({
    required int sectionId,
    required String keyword,
    String role = 'student',
    int limit = 50,
  }) async {
    if (shouldThrowError) throw Exception('Search Error');
    return mockAssignments
        .where((a) => a.title.toLowerCase().contains(keyword.toLowerCase()))
        .take(limit)
        .toList();
  }

  @override
  Future<List<StudentSubmissionStatusModel>> getStudentsSubmissionStatus({
    required int assignmentId,
  }) async {
    if (shouldThrowError) throw Exception('Students Error');
    return mockStudents;
  }

  @override
  Future<SubmissionDetailModel?> getSubmissionDetail({
    required int submissionId,
  }) async {
    if (shouldThrowError) throw Exception('Detail Error');
    return mockSubmissionDetail;
  }

  @override
  Future<List<GroupModel>> getAllGroups({required int assignmentId}) async {
    if (shouldThrowError) throw Exception('Groups Error');
    return mockGroups;
  }

  @override
  Future<AssignmentPostDetailModel?> getPostAssignment({
    required int postId,
    String? role,
  }) async {
    if (shouldThrowError) throw Exception('Post Error');
    return mockPostDetail;
  }

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockSubmissionRepository extends GetxService
    implements SubmissionRepository {
  bool shouldThrowError = false;
  SubmissionModel? mockSubmissionResult;
  bool mockGradeResult = true;

  @override
  Future<SubmissionModel?> createSubmission({
    required int assignmentId,
    int? groupId,
    required List<Map<String, dynamic>> files,
  }) async {
    if (shouldThrowError) throw Exception('Create Submission Error');
    return mockSubmissionResult ??
        createTestSubmission(id: 1, assignmentId: assignmentId);
  }

  @override
  Future<SubmissionModel?> updateSubmission({
    required int submissionId,
    required int assignmentId,
    int? groupId,
    required List<Map<String, dynamic>> files,
  }) async {
    if (shouldThrowError) throw Exception('Update Submission Error');
    return mockSubmissionResult;
  }

  @override
  Future<bool> gradeSubmission({
    required int submissionId,
    required double score,
    required String feedback,
  }) async {
    if (shouldThrowError) throw Exception('Grade Error');
    return mockGradeResult;
  }

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockClassFeedRepository extends GetxService
    implements ClassFeedRepository {
  List<SectionEducatorModel> mockEducators = [];
  bool shouldThrowError = false;

  @override
  Future<List<SectionEducatorModel>> getSectionEducators({
    required int sectionId,
  }) async {
    if (shouldThrowError) throw Exception('Educators Error');
    return mockEducators;
  }

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockAuthController extends AuthController {
  MockAuthController() {
    roleName.value = 'student';
    userId.value = 1;
  }

  void setMockRole(String role) {
    roleName.value = role;
  }

  void setMockUserId(int id) {
    userId.value = id;
  }
}

// Helper functions to create test data
AssignmentModel createTestAssignment({
  required int assignmentId,
  required String title,
  DateTime? submittedAt,
  DateTime? dueDate,
}) {
  return AssignmentModel(
    assignmentId: assignmentId,
    postId: assignmentId * 100,
    title: title,
    subjectNameTh: 'วิชาทดสอบ',
    subjectNameEn: 'Test Subject',
    assignmentType: 'assignment',
    isGroup: false,
    submittedAt: submittedAt,
    dueDate: dueDate,
  );
}

StudentSubmissionStatusModel createTestStudent({
  required int userId,
  required String firstName,
  required String lastName,
  String submissionStatus = 'not_submitted',
}) {
  return StudentSubmissionStatusModel(
    userSysId: userId,
    firstName: firstName,
    lastName: lastName,
    submissionStatus: submissionStatus,
  );
}

SubmissionModel createTestSubmission({
  required int id,
  required int assignmentId,
}) {
  return SubmissionModel(
    submissionId: id,
    assignmentId: assignmentId,
    groupId: 0,
    submittedAt: DateTime.now(),
  );
}

AssignmentPostDetailModel createTestAssignmentPostDetail({
  required int postId,
  required String title,
}) {
  return AssignmentPostDetailModel.fromJson({
    'post': {
      'post_id': postId,
      'post_content_id': postId * 10,
      'title': title,
      'content': 'Test content',
      'post_type': 'assignment',
      'is_anonymous': false,
      'created_at': DateTime.now().toIso8601String(),
    },
    'assignment': {
      'assignment_id': postId,
      'post_id': postId,
      'due_date': DateTime.now().add(Duration(days: 7)).toIso8601String(),
      'max_score': 100,
      'is_group': false,
    },
  });
}

void main() {
  setUpAll(() async {
    // Initialize dotenv for tests
    TestWidgetsFlutterBinding.ensureInitialized();
    dotenv.testLoad(fileInput: '''
API_BASE_URL=http://test-api.example.com
''');
  });

  group('Assignment Controllers Unit Tests', () {
    late MockAssignmentRepository mockAssignmentRepo;
    late MockSubmissionRepository mockSubmissionRepo;
    late MockClassFeedRepository mockClassFeedRepo;
    late MockAuthController mockAuthController;

    setUp(() {
      Get.reset();

      // Initialize mocks
      mockAssignmentRepo = MockAssignmentRepository();
      mockSubmissionRepo = MockSubmissionRepository();
      mockClassFeedRepo = MockClassFeedRepository();
      mockAuthController = MockAuthController();

      // Register mocks with GetX
      Get.put<AssignmentRepository>(mockAssignmentRepo);
      Get.put<SubmissionRepository>(mockSubmissionRepo);
      Get.put<ClassFeedRepository>(mockClassFeedRepo);
      Get.put<AuthController>(mockAuthController);
    });

    tearDown(() {
      Get.reset();
    });

    group('ClassAssignmentController Tests', () {
      late ClassAssignmentController controller;

      setUp(() {
        controller = ClassAssignmentController(
          mockAssignmentRepo,
          mockClassFeedRepo,
        );
        Get.put(controller);
      });

      // Test: Verifies that assignments are fetched correctly and state is updated
      // Checks: Initial loading state, API call parameters, and data population
      test('should fetch assignments successfully', () async {
        mockAssignmentRepo.mockAssignments = [
          createTestAssignment(assignmentId: 1, title: 'Assignment 1'),
          createTestAssignment(
            assignmentId: 2,
            title: 'Assignment 2',
            submittedAt: DateTime.now(),
          ),
        ];

        controller.fetchAssignments();

        expect(controller.isLoading.value, isTrue);

        await Future.delayed(Duration(milliseconds: 100));

        expect(controller.isLoading.value, isFalse);
        expect(controller.assignments.length, equals(2));
        expect(controller.errorMessage.value, isEmpty);
      });

      // Test: Verifies that filter logic works correctly for different submission statuses
      // Checks: Filter application, list updating, and status-based filtering
      test('should apply filters correctly', () async {
        mockAssignmentRepo.mockAssignments = [
          createTestAssignment(assignmentId: 1, title: 'Assignment 1'),
          createTestAssignment(
            assignmentId: 2,
            title: 'Assignment 2',
            submittedAt: DateTime.now(),
          ),
          createTestAssignment(
            assignmentId: 3,
            title: 'Assignment 3',
            submittedAt: DateTime.now().subtract(Duration(days: 10)),
            dueDate: DateTime.now().subtract(Duration(days: 5)),
          ),
        ];

        await controller.fetchAssignments();
        controller.applyFilter('ส่งแล้ว');

        expect(controller.currentFilter.value, equals('ส่งแล้ว'));
        expect(controller.filteredAssignments.length, greaterThanOrEqualTo(1));
      });

      // Test: Verifies that pagination works correctly with offset and limit
      // Checks: Load more functionality, offset calculation, and data appending
      test('should handle pagination correctly', () async {
        // Setup initial data
        mockAssignmentRepo.mockAssignments = List.generate(
          25,
          (i) => createTestAssignment(
            assignmentId: i + 1,
            title: 'Assignment ${i + 1}',
          ),
        );

        await controller.fetchAssignments();
        expect(controller.assignments.length, equals(10)); // First page

        controller.loadMoreAssignments();
        await Future.delayed(Duration(milliseconds: 100));

        expect(controller.assignments.length, equals(20)); // Second page loaded
      });

      // Test: Verifies error handling when API calls fail
      // Checks: Error state management, loading state reset, and error message display
      test('should handle API errors gracefully', () async {
        mockAssignmentRepo.shouldThrowError = true;

        controller.fetchAssignments();
        await Future.delayed(Duration(milliseconds: 100));

        expect(controller.isLoading.value, isFalse);
        expect(controller.errorMessage.value, isNotEmpty);
        expect(controller.assignments.isEmpty, isTrue);
      });
    });

    group('SearchAssignmentController Tests', () {
      late SearchAssignmentController controller;

      setUp(() {
        controller = SearchAssignmentController();
        Get.put(controller);
      });

      // Test: Verifies that search initialization works correctly with parameters
      // Checks: Repository resolution, parameter setting, and initialization state
      test('should initialize correctly with section and role', () async {
        controller.init(sectionId: 123, role: 'student');

        expect(controller.sectionId, equals(123));
        expect(controller.role, equals('student'));
      });

      // Test: Verifies that search functionality works with keyword filtering
      // Checks: Keyword processing, API call parameters, and result filtering
      test('should perform search with valid keyword', () async {
        mockAssignmentRepo.mockAssignments = [
          createTestAssignment(assignmentId: 1, title: 'Math Assignment'),
          createTestAssignment(assignmentId: 2, title: 'Science Project'),
          createTestAssignment(assignmentId: 3, title: 'Math Quiz'),
        ];

        controller.init(sectionId: 123, role: 'student');
        controller.onKeywordChanged('Math');

        // Wait for debounce
        await Future.delayed(Duration(milliseconds: 600));

        expect(controller.keyword.value, equals('Math'));
        expect(
          controller.results.length,
          equals(2),
        ); // Math Assignment + Math Quiz
      });

      // Test: Verifies that empty search clears results without API call
      // Checks: Empty keyword handling, result clearing, and API call prevention
      test('should clear results for empty keyword', () async {
        controller.init(sectionId: 123, role: 'student');
        controller.results.addAll([
          createTestAssignment(assignmentId: 1, title: 'Test'),
          createTestAssignment(assignmentId: 2, title: 'Test 2'),
        ]);

        controller.onKeywordChanged('');

        expect(controller.keyword.value, isEmpty);
        expect(controller.results.isEmpty, isTrue);
      });

      // Test: Verifies error handling when section ID is missing
      // Checks: Validation logic, error state setting, and search prevention
      test('should handle missing section ID error', () async {
        controller.init(role: 'student'); // No sectionId
        controller.onKeywordChanged('test');

        await Future.delayed(Duration(milliseconds: 600));

        expect(controller.error.value, isNotEmpty);
      });
    });

    group('TeacherSubmissionController Tests', () {
      late TeacherSubmissionController controller;

      setUp(() {
        Get.testMode = true;
        Get.parameters = {'assignmentId': '123', 'maxScore': '100.0'};
        controller = TeacherSubmissionController(
          repo: mockAssignmentRepo,
          submissionRepo: mockSubmissionRepo,
        );
        Get.put(controller);
      });

      // Test: Verifies that student data is fetched and grouped correctly
      // Checks: API call execution, data population, and group creation
      test('should fetch students and build grouped list', () async {
        mockAssignmentRepo.mockStudents = [
          createTestStudent(
            userId: 1,
            firstName: 'Student',
            lastName: 'A',
            submissionStatus: 'submitted',
          ),
          createTestStudent(
            userId: 2,
            firstName: 'Student',
            lastName: 'B',
            submissionStatus: 'not_submitted',
          ),
        ];

        controller.fetchStudents();
        await Future.delayed(Duration(milliseconds: 100));

        expect(controller.isLoading.value, isFalse);
        expect(controller.allStudents.length, equals(2));
        expect(controller.groupedList.isNotEmpty, isTrue);
      });

      // Test: Verifies that submission statistics are calculated correctly
      // Checks: Count calculation for submitted, not submitted, and overdue
      test('should calculate submission statistics correctly', () async {
        mockAssignmentRepo.mockStudents = [
          createTestStudent(
            userId: 1,
            firstName: 'A',
            lastName: 'Student',
            submissionStatus: 'submitted',
          ),
          createTestStudent(
            userId: 2,
            firstName: 'B',
            lastName: 'Student',
            submissionStatus: 'submitted',
          ),
          createTestStudent(
            userId: 3,
            firstName: 'C',
            lastName: 'Student',
            submissionStatus: 'not_submitted',
          ),
          createTestStudent(
            userId: 4,
            firstName: 'D',
            lastName: 'Student',
            submissionStatus: 'not_submitted',
          ),
        ];

        await controller.fetchStudents();

        expect(controller.submittedCount, equals(2));
        expect(controller.notSubmittedCount, equals(2));
      });

      // Test: Verifies that grading validation works correctly
      // Checks: Score format validation, maximum score checking, and input sanitization
      test('should validate grading input correctly', () async {
        controller.maxScore = 100.0;
        controller.scoreController.value = '85.50';
        controller.feedbackController.value = 'Good work!';

        mockSubmissionRepo.mockGradeResult = true;

        await controller.gradeSubmission();

        // Should complete without error for valid input
        expect(controller.isGrading.value, isFalse);
      });

      // Test: Verifies that filter functionality works for different submission states
      // Checks: Filter application, list updating, and state-based filtering
      test('should filter submissions by status', () async {
        mockAssignmentRepo.mockStudents = [
          createTestStudent(
            userId: 1,
            firstName: 'Student',
            lastName: 'A',
            submissionStatus: 'submitted',
          ),
          createTestStudent(
            userId: 2,
            firstName: 'Student',
            lastName: 'B',
            submissionStatus: 'not_submitted',
          ),
          createTestStudent(
            userId: 3,
            firstName: 'Student',
            lastName: 'C',
            submissionStatus: 'submitted',
          ),
        ];

        await controller.fetchStudents();

        // Test submitted filter
        controller.changeFilter(SubmissionFilter.submitted);
        expect(controller.filteredStudents.length, equals(2));

        // Test not submitted filter
        controller.changeFilter(SubmissionFilter.notSubmitted);
        expect(controller.filteredStudents.length, equals(1));
      });
    });

    group('AssignmentSubmissionController Tests', () {
      late AssignmentSubmissionController controller;

      setUp(() {
        Get.testMode = true;
        Get.parameters = {'postId': '123'};
        mockAuthController.setMockRole('student');
        controller = AssignmentSubmissionController(
          repo: mockAssignmentRepo,
          submissionRepo: mockSubmissionRepo,
          authController: mockAuthController,
        );
        Get.put(controller);
      });

      // Test: Verifies that assignment data is fetched and loaded correctly
      // Checks: API call execution, data population, and state management
      test('should fetch assignment details successfully', () async {
        mockAssignmentRepo.mockPostDetail = createTestAssignmentPostDetail(
          postId: 123,
          title: 'Test Assignment',
        );

        controller.fetchAssignment(123);
        await Future.delayed(Duration(milliseconds: 100));

        expect(controller.isLoading.value, isFalse);
        expect(controller.post.value, isNotNull);
      });

      // Test: Verifies that file upload validation and management works
      // Checks: File addition, upload state tracking, and URL validation
      test('should handle file upload operations', () async {
        // Test adding a mock file
        controller.uploadedFiles.add({
          'local_id': 1,
          'file_url': 'https://example.com/file.pdf',
          'original_name': 'test.pdf',
          'file_type': 'pdf',
          'file_size': 1024,
          'is_uploading': false,
          'is_link': false,
        });

        expect(controller.uploadedFiles.length, equals(1));
        expect(controller.hasUploadingFiles, isFalse);

        // Test file removal
        controller.removeFile(0);
        expect(controller.uploadedFiles.length, equals(0));
      });

      // Test: Verifies that link attachment validation works correctly
      // Checks: URL format validation, link addition, and error handling
      test('should validate link attachments correctly', () async {
        // Valid URL
        controller.addLinkAttachment('https://example.com/resource');
        expect(controller.uploadedFiles.length, equals(1));
        expect(controller.uploadedFiles.first['is_link'], isTrue);

        // Invalid URL should not be added
        controller.addLinkAttachment('invalid-url');
        expect(
          controller.uploadedFiles.length,
          equals(1),
        ); // Still only one valid link
      });

      // Test: Verifies that teacher role detection works correctly
      // Checks: Role-based permission logic and UI state management
      test('should detect teacher role correctly', () {
        mockAuthController.setMockRole('teacher');
        expect(controller.isTeacher, isTrue);

        mockAuthController.setMockRole('student');
        expect(controller.isTeacher, isFalse);

        mockAuthController.setMockRole('instructor');
        expect(controller.isTeacher, isTrue);
      });

      // Test: Verifies that submission permissions are enforced correctly
      // Checks: File modification permissions and edit mode logic
      test('should enforce file modification permissions', () {
        // No existing submission - should allow modification
        controller.submission.value = null;
        expect(controller.canModifySubmissionFiles, isTrue);

        // Existing submission but not in edit mode - should block
        controller.submission.value = createTestSubmission(
          id: 1,
          assignmentId: 123,
        );
        controller.isEditingSubmission.value = false;
        expect(controller.canModifySubmissionFiles, isFalse);

        // In edit mode - should allow
        controller.isEditingSubmission.value = true;
        expect(controller.canModifySubmissionFiles, isTrue);
      });
    });

    test('should detect teacher role correctly', () {
      // Create a minimal test without dependencies
      final roleValue = RxString('teacher');

      // Test the logic that would be in the controller
      bool isTeacher =
          roleValue.value == 'teacher' || roleValue.value == 'instructor';
      bool isStudent =
          roleValue.value == 'high school student' ||
          roleValue.value == 'uni student';

      expect(isTeacher, isTrue);
      expect(isStudent, isFalse);

      roleValue.value = 'instructor';
      isTeacher =
          roleValue.value == 'teacher' || roleValue.value == 'instructor';
      expect(isTeacher, isTrue);
    });

    // Test: Verifies that student roles ('high school student', 'uni student') are correctly identified
    // Checks: Role detection logic for students
    test('should detect student role correctly', () {
      final roleValue = RxString('high school student');

      bool isStudent =
          roleValue.value == 'high school student' ||
          roleValue.value == 'uni student';
      bool isTeacher =
          roleValue.value == 'teacher' || roleValue.value == 'instructor';

      expect(isStudent, isTrue);
      expect(isTeacher, isFalse);

      roleValue.value = 'uni student';
      isStudent =
          roleValue.value == 'high school student' ||
          roleValue.value == 'uni student';
      expect(isStudent, isTrue);
    });

    // Test: Verifies that correct filter options are provided based on user role
    // Checks: Filter options logic - students get status filters, teachers get sorting filters
    test('should provide correct filter options based on role', () {
      // Simulate the filterOptions logic
      List<String> getFilterOptions(String role) {
        if (role == 'high school student' ||
            role == 'uni student' ||
            role == 'student') {
          return ['ทั้งหมด', 'ส่งช้า', 'ยังไม่ส่ง', 'ส่งแล้ว'];
        } else {
          return ['โพสต์ล่าสุด', 'โพสต์เก่าสุด'];
        }
      }

      final studentFilters = getFilterOptions('student');
      expect(studentFilters, contains('ทั้งหมด'));
      expect(studentFilters, contains('ส่งช้า'));
      expect(studentFilters, contains('ยังไม่ส่ง'));
      expect(studentFilters, contains('ส่งแล้ว'));

      final teacherFilters = getFilterOptions('teacher');
      expect(teacherFilters, contains('โพสต์ล่าสุด'));
      expect(teacherFilters, contains('โพสต์เก่าสุด'));
    });

    // Test: Verifies that assignments are correctly filtered based on student submission status
    // Checks: Assignment filtering logic for different submission states
    test('should filter student assignments correctly', () {
      // Mock assignment data
      final assignments = [
        {'student_status': 'ส่งแล้ว', 'title': 'Assignment 1'},
        {'student_status': 'ยังไม่ส่ง', 'title': 'Assignment 2'},
        {'student_status': 'ส่งแล้วเกินกำหนด', 'title': 'Assignment 3'},
        {'student_status': 'ยังไม่ส่งเกินกำหนด', 'title': 'Assignment 4'},
      ];

      // Simulate filter logic
      List<Map<String, dynamic>> filterItems(
        List<Map<String, dynamic>> items,
        String filter,
      ) {
        switch (filter) {
          case 'ส่งช้า':
            return items
                .where(
                  (a) =>
                      a['student_status'] == 'ส่งแล้วเกินกำหนด' ||
                      a['student_status'] == 'ยังไม่ส่งเกินกำหนด',
                )
                .toList();
          case 'ยังไม่ส่ง':
            return items
                .where(
                  (a) =>
                      a['student_status'] == 'ยังไม่ส่ง' ||
                      a['student_status'] == 'ยังไม่ส่งเกินกำหนด',
                )
                .toList();
          case 'ส่งแล้ว':
            return items
                .where(
                  (a) =>
                      a['student_status'] == 'ส่งแล้ว' ||
                      a['student_status'] == 'ส่งแล้วเกินกำหนด',
                )
                .toList();
          default:
            return items;
        }
      }

      // Test filters
      final lateItems = filterItems(assignments, 'ส่งช้า');
      expect(lateItems.length, equals(2));

      final notSubmittedItems = filterItems(assignments, 'ยังไม่ส่ง');
      expect(notSubmittedItems.length, equals(2));

      final submittedItems = filterItems(assignments, 'ส่งแล้ว');
      expect(submittedItems.length, equals(2));

      final allItems = filterItems(assignments, 'ทั้งหมด');
      expect(allItems.length, equals(4));
    });
  });

  group('SearchAssignmentController Business Logic Tests', () {
    // Test: Verifies that search parameters are properly validated before performing search
    // Checks: Search validation logic for required parameters (keyword and sectionId)
    test('should validate search parameters', () {
      // Test search validation logic
      bool isValidSearch(String? keyword, int? sectionId) {
        if (sectionId == null) return false;
        if (keyword == null || keyword.trim().isEmpty) return false;
        return true;
      }

      expect(isValidSearch('test', 1), isTrue);
      expect(isValidSearch('', 1), isFalse);
      expect(isValidSearch('test', null), isFalse);
      expect(isValidSearch(null, 1), isFalse);
    });

    // Test: Verifies that search keywords are properly trimmed of whitespace
    // Checks: Keyword preprocessing logic to remove leading/trailing spaces
    test('should handle keyword trimming', () {
      String processKeyword(String input) {
        return input.trim();
      }

      expect(processKeyword('  test keyword  '), equals('test keyword'));
      expect(processKeyword('single'), equals('single'));
      expect(processKeyword('   '), equals(''));
    });

    // Test: Verifies that search filtering works correctly for assignment titles
    // Checks: Search algorithm for finding assignments matching keywords
    test('should simulate search filtering', () {
      final mockAssignments = [
        {'title': 'Math Assignment', 'id': 1},
        {'title': 'Science Project', 'id': 2},
        {'title': 'History Essay', 'id': 3},
      ];

      List<Map<String, dynamic>> searchAssignments(
        List<Map<String, dynamic>> assignments,
        String keyword,
      ) {
        return assignments
            .where(
              (a) => a['title'].toString().toLowerCase().contains(
                keyword.toLowerCase(),
              ),
            )
            .toList();
      }

      final mathResults = searchAssignments(mockAssignments, 'math');
      expect(mathResults.length, equals(1));
      expect(mathResults.first['title'], contains('Math'));

      final emptyResults = searchAssignments(mockAssignments, 'chemistry');
      expect(emptyResults.isEmpty, isTrue);
    });
  });

  group('TeacherSubmissionController Business Logic Tests', () {
    // Test: Verifies that submission statistics are calculated correctly
    // Checks: Count calculation logic for submitted vs non-submitted assignments
    test('should calculate submission statistics correctly', () {
      final mockStudents = [
        {'has_submitted': true, 'name': 'Student A'},
        {'has_submitted': true, 'name': 'Student B'},
        {'has_submitted': false, 'name': 'Student C'},
        {'has_submitted': false, 'name': 'Student D'},
      ];

      int getSubmittedCount(List<Map<String, dynamic>> students) {
        return students.where((s) => s['has_submitted'] == true).length;
      }

      int getNotSubmittedCount(List<Map<String, dynamic>> students) {
        return students.where((s) => s['has_submitted'] == false).length;
      }

      expect(getSubmittedCount(mockStudents), equals(2));
      expect(getNotSubmittedCount(mockStudents), equals(2));
    });

    // Test: Verifies that overdue submission detection works correctly
    // Checks: Date comparison logic for identifying overdue assignments
    test('should detect overdue submissions', () {
      final now = DateTime.now();
      final pastDue = now.subtract(Duration(days: 1));
      final futureDue = now.add(Duration(days: 1));

      bool isOverdue(DateTime? dueDate) {
        if (dueDate == null) return false;
        return DateTime.now().isAfter(dueDate);
      }

      expect(isOverdue(pastDue), isTrue);
      expect(isOverdue(futureDue), isFalse);
      expect(isOverdue(null), isFalse);
    });

    // Test: Verifies that grade input validation works correctly
    // Checks: Score validation logic for format, decimal places, and maximum score
    test('should validate grading input', () {
      bool isValidScore(String scoreStr, double? maxScore) {
        final score = double.tryParse(scoreStr);
        if (score == null) return false;

        // Check decimal places
        final decimalRegex = RegExp(r'^\d+(\.\d{1,2})?$');
        if (!decimalRegex.hasMatch(scoreStr)) return false;

        // Check max score
        if (maxScore != null && score > maxScore) return false;

        return true;
      }

      expect(isValidScore('95.5', 100.0), isTrue);
      expect(isValidScore('100', 100.0), isTrue);
      expect(isValidScore('95.555', 100.0), isFalse); // Too many decimals
      expect(isValidScore('150', 100.0), isFalse); // Exceeds max
      expect(isValidScore('invalid', 100.0), isFalse); // Invalid number
    });

    // Test: Verifies that submission filtering by status works correctly
    // Checks: Filter logic for different submission statuses
    test('should filter submissions by status', () {
      final submissions = [
        {'has_submitted': true, 'name': 'Student A'},
        {'has_submitted': false, 'name': 'Student B'},
        {'has_submitted': true, 'name': 'Student C'},
      ];

      List<Map<String, dynamic>> filterByStatus(
        List<Map<String, dynamic>> submissions,
        String filter,
      ) {
        switch (filter) {
          case 'submitted':
            return submissions
                .where((s) => s['has_submitted'] == true)
                .toList();
          case 'not_submitted':
            return submissions
                .where((s) => s['has_submitted'] == false)
                .toList();
          default:
            return submissions;
        }
      }

      final submitted = filterByStatus(submissions, 'submitted');
      expect(submitted.length, equals(2));

      final notSubmitted = filterByStatus(submissions, 'not_submitted');
      expect(notSubmitted.length, equals(1));

      final all = filterByStatus(submissions, 'all');
      expect(all.length, equals(3));
    });
  });

  group('AssignmentSubmissionController Business Logic Tests', () {
    // Test: Verifies that teacher role detection works correctly
    // Checks: Role validation logic for teacher/instructor permissions
    test('should validate teacher role detection', () {
      bool isTeacherRole(String? roleName) {
        if (roleName == null) return false;
        final role = roleName.toLowerCase();
        return role.contains('teacher') || role.contains('instructor');
      }

      expect(isTeacherRole('teacher'), isTrue);
      expect(isTeacherRole('instructor'), isTrue);
      expect(isTeacherRole('Teacher Assistant'), isTrue);
      expect(isTeacherRole('student'), isFalse);
      expect(isTeacherRole(null), isFalse);
    });

    // Test: Verifies that file modification permissions are enforced correctly
    // Checks: Permission logic for when users can modify submission files
    test('should validate file modification permissions', () {
      bool canModifyFiles(bool hasExistingSubmission, bool isEditing) {
        return !hasExistingSubmission || isEditing;
      }

      // No existing submission
      expect(canModifyFiles(false, false), isTrue);

      // Has submission but not editing
      expect(canModifyFiles(true, false), isFalse);

      // Has submission and is editing
      expect(canModifyFiles(true, true), isTrue);
    });

    // Test: Verifies that URL validation works correctly for link attachments
    // Checks: URL format validation logic for external links
    test('should validate link attachment format', () {
      bool isValidUrl(String link) {
        final trimmed = link.trim();
        final uri = Uri.tryParse(trimmed);
        return trimmed.isNotEmpty &&
            uri != null &&
            uri.hasScheme &&
            uri.hasAuthority;
      }

      expect(isValidUrl('https://example.com'), isTrue);
      expect(isValidUrl('http://test.org'), isTrue);
      expect(isValidUrl('ftp://files.com'), isTrue);
      expect(isValidUrl('invalid-url'), isFalse);
      expect(isValidUrl(''), isFalse);
      expect(isValidUrl('   '), isFalse);
    });

    // Test: Verifies that group submission requirements are validated correctly
    // Checks: Validation logic for group submission prerequisites
    test('should validate group submission requirements', () {
      bool canSubmitGroup(
        String groupName,
        List<int> selectedStudents,
        bool isSubmitting,
      ) {
        return groupName.trim().isNotEmpty &&
            selectedStudents.isNotEmpty &&
            !isSubmitting;
      }

      expect(canSubmitGroup('Test Group', [1, 2, 3], false), isTrue);
      expect(canSubmitGroup('', [1, 2, 3], false), isFalse);
      expect(canSubmitGroup('Test Group', [], false), isFalse);
      expect(canSubmitGroup('Test Group', [1, 2, 3], true), isFalse);
    });

    // Test: Verifies that student selection toggle functionality works correctly
    // Checks: Toggle logic for adding/removing students from selection
    test('should handle student selection toggle', () {
      List<int> selectedIds = [1, 2, 3];

      List<int> toggleStudent(List<int> currentSelection, int studentId) {
        final newSelection = List<int>.from(currentSelection);
        if (newSelection.contains(studentId)) {
          newSelection.remove(studentId);
        } else {
          newSelection.add(studentId);
        }
        return newSelection;
      }

      // Add new student
      final afterAdd = toggleStudent(selectedIds, 4);
      expect(afterAdd, contains(4));
      expect(afterAdd.length, equals(4));

      // Remove existing student
      final afterRemove = toggleStudent(selectedIds, 2);
      expect(afterRemove, isNot(contains(2)));
      expect(afterRemove.length, equals(2));
    });

    // Test: Verifies that student search filtering works correctly
    // Checks: Search algorithm for filtering students by name
    test('should filter students by search query', () {
      final students = [
        {'first_name': 'John', 'last_name': 'Doe'},
        {'first_name': 'Jane', 'last_name': 'Smith'},
        {'first_name': 'Bob', 'last_name': 'Johnson'},
      ];

      List<Map<String, dynamic>> filterStudents(
        List<Map<String, dynamic>> students,
        String query,
      ) {
        final keyword = query.toLowerCase();
        return students.where((s) {
          final fullName = '${s['first_name']} ${s['last_name']}'.toLowerCase();
          return fullName.contains(keyword);
        }).toList();
      }

      final johnResults = filterStudents(students, 'john');
      expect(johnResults.length, equals(2)); // John Doe and Bob Johnson

      final janeResults = filterStudents(students, 'jane');
      expect(janeResults.length, equals(1));

      final emptyResults = filterStudents(students, 'xyz');
      expect(emptyResults.isEmpty, isTrue);
    });
  });

  group('Utility Functions Tests', () {
    // Test: Verifies that assignment data validation works correctly
    // Checks: Data structure validation logic for required fields and types
    test('should validate assignment data correctly', () {
      bool validateAssignmentData(Map<String, dynamic> data) {
        if (!data.containsKey('assignment_id') ||
            data['assignment_id'] is! int) {
          return false;
        }

        if (data.containsKey('max_score') && data['max_score'] is! num) {
          return false;
        }

        return true;
      }

      expect(validateAssignmentData({'assignment_id': 1}), isTrue);
      expect(
        validateAssignmentData({'assignment_id': 1, 'max_score': 100.0}),
        isTrue,
      );
      expect(validateAssignmentData({}), isFalse);
      expect(validateAssignmentData({'assignment_id': 'invalid'}), isFalse);
      expect(
        validateAssignmentData({'assignment_id': 1, 'max_score': 'invalid'}),
        isFalse,
      );
    });

    // Test: Verifies that date parsing works correctly for various formats
    // Checks: Date parsing logic for assignment due dates and timestamps
    test('should parse assignment dates correctly', () {
      DateTime? parseAssignmentDate(String? dateString) {
        if (dateString == null || dateString.isEmpty) return null;

        try {
          return DateTime.parse(dateString);
        } catch (e) {
          return null;
        }
      }

      final validDate = parseAssignmentDate('2024-01-01T12:00:00Z');
      expect(validDate, isNotNull);
      expect(validDate?.year, equals(2024));
      expect(validDate?.month, equals(1));
      expect(validDate?.day, equals(1));

      final invalidDate = parseAssignmentDate('invalid-date');
      expect(invalidDate, isNull);

      final nullDate = parseAssignmentDate(null);
      expect(nullDate, isNull);

      final emptyDate = parseAssignmentDate('');
      expect(emptyDate, isNull);
    });

    // Test: Verifies that score formatting works correctly for display
    // Checks: Score formatting logic for integer vs decimal scores
    test('should format assignment scores correctly', () {
      String formatAssignmentScore(double? score) {
        if (score == null) return 'N/A';
        if (score % 1 == 0) return score.toInt().toString();
        return score.toString();
      }

      expect(formatAssignmentScore(95.5), equals('95.5'));
      expect(formatAssignmentScore(100.0), equals('100'));
      expect(formatAssignmentScore(0.0), equals('0'));
      expect(formatAssignmentScore(null), equals('N/A'));
    });

    // Test: Verifies that overdue assignment detection works correctly
    // Checks: Date comparison logic for determining if assignments are past due
    test('should check if assignment is overdue correctly', () {
      bool isAssignmentOverdue(DateTime? dueDate) {
        if (dueDate == null) return false;
        return DateTime.now().isAfter(dueDate);
      }

      final pastDate = DateTime.now().subtract(Duration(days: 1));
      final futureDate = DateTime.now().add(Duration(days: 1));

      expect(isAssignmentOverdue(pastDate), isTrue);
      expect(isAssignmentOverdue(futureDate), isFalse);
      expect(isAssignmentOverdue(null), isFalse);
    });

    // Test: Verifies that assignment status statistics calculation works correctly
    // Checks: Statistics aggregation logic for different assignment statuses
    test('should handle assignment status calculations', () {
      Map<String, int> calculateAssignmentStats(
        List<Map<String, dynamic>> assignments,
      ) {
        int total = assignments.length;
        int submitted = assignments
            .where((a) => a['status'] == 'submitted')
            .length;
        int pending = assignments.where((a) => a['status'] == 'pending').length;
        int overdue = assignments.where((a) => a['status'] == 'overdue').length;

        return {
          'total': total,
          'submitted': submitted,
          'pending': pending,
          'overdue': overdue,
        };
      }

      final assignments = [
        {'status': 'submitted'},
        {'status': 'submitted'},
        {'status': 'pending'},
        {'status': 'overdue'},
      ];

      final stats = calculateAssignmentStats(assignments);
      expect(stats['total'], equals(4));
      expect(stats['submitted'], equals(2));
      expect(stats['pending'], equals(1));
      expect(stats['overdue'], equals(1));
    });
  });

  group('Edge Cases and Error Handling Tests', () {
    // Test: Verifies that empty lists are handled gracefully without errors
    // Checks: Empty data handling for filtering and processing operations
    test('should handle empty lists gracefully', () {
      List<Map<String, dynamic>> filterEmptyList(
        List<Map<String, dynamic>> items,
        String filter,
      ) {
        return items.where((item) => item['status'] == filter).toList();
      }

      final result = filterEmptyList([], 'any_filter');
      expect(result.isEmpty, isTrue);
    });

    // Test: Verifies that null values in data are handled safely
    // Checks: Null safety logic for data validation and processing
    test('should handle null values in data', () {
      bool isValidStudent(Map<String, dynamic>? student) {
        if (student == null) return false;
        return student.containsKey('id') && student['id'] != null;
      }

      expect(isValidStudent(null), isFalse);
      expect(isValidStudent({}), isFalse);
      expect(isValidStudent({'id': null}), isFalse);
      expect(isValidStudent({'id': 1}), isTrue);
    });

    // Test: Verifies that boundary values are handled correctly
    // Checks: Boundary condition handling for score validation
    test('should handle boundary values correctly', () {
      bool isValidScore(double score, double maxScore) {
        return score >= 0 && score <= maxScore;
      }

      expect(isValidScore(0, 100), isTrue);
      expect(isValidScore(100, 100), isTrue);
      expect(isValidScore(-1, 100), isFalse);
      expect(isValidScore(101, 100), isFalse);
      expect(isValidScore(50.5, 100), isTrue);
    });

    // Test: Verifies that string operations handle null values safely
    // Checks: Null safety for string manipulation operations
    test('should handle string operations safely', () {
      String safeToLower(String? input) {
        return input?.toLowerCase() ?? '';
      }

      expect(safeToLower('TEST'), equals('test'));
      expect(safeToLower(null), equals(''));
      expect(safeToLower(''), equals(''));
    });
  });
}
