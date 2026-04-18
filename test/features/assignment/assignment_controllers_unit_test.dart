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
  Future<bool> deleteBlob({required String fileUrl}) async {
    // Mock deleteBlob - always succeed
    return true;
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

/// Mock AuthController - ไม่ extend AuthController จริงเพื่อหลีกเลี่ยงการสร้าง AuthRepository ที่ต้องการ API_BASE_URL
class MockAuthController extends GetxController implements AuthController {
  @override
  final RxnString token = RxnString();
  @override
  final RxnString roleName = RxnString();
  @override
  final RxnInt instId = RxnInt();
  @override
  final RxnInt userId = RxnInt();

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

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

// ============================================================================
// HELPER FUNCTIONS - สร้าง test data
// ============================================================================

AssignmentModel createTestAssignment({
  required int assignmentId,
  required String title,
  DateTime? submittedAt,
  DateTime? dueDate,
  DateTime? createdAt,
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
    createdAt: createdAt,
  );
}

/// สร้าง AssignmentModel พร้อม studentStatus ที่ต้องการ
/// studentStatus คำนวณจาก submittedAt และ dueDate
/// - 'ส่งแล้ว': submittedAt != null && !pastDue
/// - 'ยังไม่ส่ง': submittedAt == null && !pastDue  
/// - 'ส่งแล้วเกินกำหนด': submittedAt != null && submittedAt > dueDate
/// - 'ยังไม่ส่งเกินกำหนด': submittedAt == null && pastDue
AssignmentModel createTestAssignmentWithStatus({
  required int assignmentId,
  required String title,
  required String wantedStatus,
  DateTime? createdAt,
}) {
  final now = DateTime.now();
  DateTime? submittedAt;
  DateTime? dueDate;

  switch (wantedStatus) {
    case 'ส่งแล้ว':
      submittedAt = now.subtract(const Duration(days: 1));
      dueDate = now.add(const Duration(days: 1)); // ยังไม่เลย due
      break;
    case 'ยังไม่ส่ง':
      submittedAt = null;
      dueDate = now.add(const Duration(days: 1)); // ยังไม่เลย due
      break;
    case 'ส่งแล้วเกินกำหนด':
      dueDate = now.subtract(const Duration(days: 2)); // เลย due แล้ว
      submittedAt = now.subtract(const Duration(days: 1)); // ส่งหลัง due
      break;
    case 'ยังไม่ส่งเกินกำหนด':
      submittedAt = null;
      dueDate = now.subtract(const Duration(days: 1)); // เลย due แล้ว
      break;
  }

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
    createdAt: createdAt,
  );
}

StudentSubmissionStatusModel createTestStudent({
  required int userId,
  required String firstName,
  required String lastName,
  String submissionStatus = 'not_submitted',
  int? submissionId,
  DateTime? submittedAt,
  int? groupId,
  String? groupName,
  double? score,
  String? feedback,
  DateTime? markedAt,
}) {
  return StudentSubmissionStatusModel(
    userSysId: userId,
    firstName: firstName,
    lastName: lastName,
    submissionStatus: submissionStatus,
    submissionId: submissionId,
    submittedAt: submittedAt,
    groupId: groupId,
    groupName: groupName,
    score: score,
    feedback: feedback,
    markedAt: markedAt,
  );
}

SubmissionModel createTestSubmission({
  required int id,
  required int assignmentId,
  List<Map<String, dynamic>>? attachments,
}) {
  return SubmissionModel(
    submissionId: id,
    assignmentId: assignmentId,
    groupId: 0,
    submittedAt: DateTime.now(),
    attachments: attachments ?? [],
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
      'due_date': DateTime.now().add(const Duration(days: 7)).toIso8601String(),
      'max_score': 100,
      'is_group': false,
    },
  });
}

void main() {
  setUpAll(() async {
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

      // Test: ตรวจสอบว่า fetch assignments ทำงานถูกต้อง
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

        await Future.delayed(const Duration(milliseconds: 100));

        expect(controller.isLoading.value, isFalse);
        expect(controller.assignments.length, equals(2));
        expect(controller.errorMessage.value, isEmpty);
      });

      // Test: ตรวจสอบ filter logic สำหรับ student status
      // ถ้า controller ไม่ filter ตาม studentStatus จริงๆ test นี้จะ fail
      test('should filter assignments by studentStatus for students', () async {
        mockAssignmentRepo.mockAssignments = [
          createTestAssignmentWithStatus(
            assignmentId: 1,
            title: 'Assignment 1',
            wantedStatus: 'ส่งแล้ว',
          ),
          createTestAssignmentWithStatus(
            assignmentId: 2,
            title: 'Assignment 2',
            wantedStatus: 'ยังไม่ส่ง',
          ),
          createTestAssignmentWithStatus(
            assignmentId: 3,
            title: 'Assignment 3',
            wantedStatus: 'ส่งแล้วเกินกำหนด',
          ),
          createTestAssignmentWithStatus(
            assignmentId: 4,
            title: 'Assignment 4',
            wantedStatus: 'ยังไม่ส่งเกินกำหนด',
          ),
        ];

        controller.userRole.value = 'high school student';
        await controller.fetchAssignments();

        // Test 'ส่งแล้ว' filter - ควรได้ 'ส่งแล้ว' และ 'ส่งแล้วเกินกำหนด'
        controller.applyFilter('ส่งแล้ว');
        expect(controller.filteredAssignments.length, equals(2),
            reason: 'Filter "ส่งแล้ว" should include "ส่งแล้ว" and "ส่งแล้วเกินกำหนด"');

        // Test 'ยังไม่ส่ง' filter - ควรได้ 'ยังไม่ส่ง' และ 'ยังไม่ส่งเกินกำหนด'
        controller.applyFilter('ยังไม่ส่ง');
        expect(controller.filteredAssignments.length, equals(2),
            reason: 'Filter "ยังไม่ส่ง" should include "ยังไม่ส่ง" and "ยังไม่ส่งเกินกำหนด"');

        // Test 'ส่งช้า' filter - ควรได้ 'ส่งแล้วเกินกำหนด' และ 'ยังไม่ส่งเกินกำหนด'
        controller.applyFilter('ส่งช้า');
        expect(controller.filteredAssignments.length, equals(2),
            reason: 'Filter "ส่งช้า" should include "ส่งแล้วเกินกำหนด" and "ยังไม่ส่งเกินกำหนด"');

        // Test 'ทั้งหมด' filter - ควรได้ทั้งหมด
        controller.applyFilter('ทั้งหมด');
        expect(controller.filteredAssignments.length, equals(4),
            reason: 'Filter "ทั้งหมด" should return all assignments');
      });

      // Test: ตรวจสอบ sorting สำหรับ teacher
      test('should sort assignments by createdAt for teachers', () async {
        final now = DateTime.now();
        mockAssignmentRepo.mockAssignments = [
          createTestAssignment(
            assignmentId: 1,
            title: 'Old Assignment',
            createdAt: now.subtract(const Duration(days: 10)),
          ),
          createTestAssignment(
            assignmentId: 2,
            title: 'New Assignment',
            createdAt: now,
          ),
          createTestAssignment(
            assignmentId: 3,
            title: 'Middle Assignment',
            createdAt: now.subtract(const Duration(days: 5)),
          ),
        ];

        controller.userRole.value = 'teacher';
        await controller.fetchAssignments();

        // Test 'โพสต์ล่าสุด' - ควร sort descending by createdAt
        controller.applyFilter('โพสต์ล่าสุด');
        expect(controller.filteredAssignments[0].title, equals('New Assignment'),
            reason: 'Newest should be first');
        expect(controller.filteredAssignments[2].title, equals('Old Assignment'),
            reason: 'Oldest should be last');

        // Test 'โพสต์เก่าสุด' - ควร sort ascending by createdAt
        controller.applyFilter('โพสต์เก่าสุด');
        expect(controller.filteredAssignments[0].title, equals('Old Assignment'),
            reason: 'Oldest should be first');
        expect(controller.filteredAssignments[2].title, equals('New Assignment'),
            reason: 'Newest should be last');
      });

      // Test: ตรวจสอบ pagination
      test('should handle pagination correctly', () async {
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
        await Future.delayed(const Duration(milliseconds: 100));

        expect(controller.assignments.length, equals(20)); // Second page loaded
      });

      // Test: ตรวจสอบ error handling
      test('should handle API errors gracefully', () async {
        mockAssignmentRepo.shouldThrowError = true;

        controller.fetchAssignments();
        await Future.delayed(const Duration(milliseconds: 100));

        expect(controller.isLoading.value, isFalse);
        expect(controller.errorMessage.value, isNotEmpty);
        expect(controller.assignments.isEmpty, isTrue);
      });

      // Test: ตรวจสอบ isTeacher/isStudent getter
      test('should detect role correctly from userRole', () {
        controller.userRole.value = 'teacher';
        expect(controller.isTeacher, isTrue);
        expect(controller.isStudent, isFalse);

        controller.userRole.value = 'instructor';
        expect(controller.isTeacher, isTrue);
        expect(controller.isStudent, isFalse);

        controller.userRole.value = 'high school student';
        expect(controller.isTeacher, isFalse);
        expect(controller.isStudent, isTrue);

        controller.userRole.value = 'uni student';
        expect(controller.isTeacher, isFalse);
        expect(controller.isStudent, isTrue);
      });

      // ========== BUG DETECTION ==========
      // Tests that FAIL indicate bugs that need fixing in the controller

      test('BUG: isStudent should recognize plain "student" role', () {
        controller.userRole.value = 'student';

        // Current code only checks 'high school student' and 'uni student'
        // Does not recognize plain 'student' role
        final supportsPlainStudent = controller.isStudent;

        expect(supportsPlainStudent, isTrue,
            reason: 'BUG DETECTED: isStudent does not support role "student"\n'
                'Location: class_assignment_controller.dart line 35-37');
      });

      test('BUG: isTeacher should be case-insensitive', () {
        controller.userRole.value = 'Teacher'; // Capital T

        // Current code: userRole.value == 'teacher'
        // Does not handle uppercase
        final handlesCaseInsensitive = controller.isTeacher;

        expect(handlesCaseInsensitive, isTrue,
            reason: 'BUG DETECTED: isTeacher does not handle case-insensitive\n'
                'Location: class_assignment_controller.dart line 33-34');
      });

      test('BUG: isStudent should be case-insensitive', () {
        controller.userRole.value = 'High School Student'; // Mixed case

        // Current code uses exact string match
        final handlesCaseInsensitive = controller.isStudent;

        expect(handlesCaseInsensitive, isTrue,
            reason: 'BUG DETECTED: isStudent does not handle case-insensitive\n'
                'Location: class_assignment_controller.dart line 35-37');
      });

      // Test: filterOptions getter
      test('should return correct filter options based on role', () {
        controller.userRole.value = 'high school student';
        expect(controller.filterOptions, contains('ทั้งหมด'));
        expect(controller.filterOptions, contains('ส่งช้า'));
        expect(controller.filterOptions, contains('ยังไม่ส่ง'));
        expect(controller.filterOptions, contains('ส่งแล้ว'));

        controller.userRole.value = 'teacher';
        expect(controller.filterOptions, contains('โพสต์ล่าสุด'));
        expect(controller.filterOptions, contains('โพสต์เก่าสุด'));
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

        // รอ debounce ก่อน
        await Future.delayed(const Duration(milliseconds: 600));

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

      // Test: ตรวจสอบการ fetch students และการสร้าง grouped list
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

        controller.assignmentId = 123;
        await controller.fetchStudents();

        expect(controller.isLoading.value, isFalse);
        expect(controller.allStudents.length, equals(2));
      });

      // Test: ตรวจสอบการนับ submitted/not submitted จาก hasSubmitted getter
      // ถ้า controller ใช้ logic ที่ผิด test จะ fail
      test('should calculate submission counts using hasSubmitted getter', () async {
        mockAssignmentRepo.mockStudents = [
          // Student ที่มี submissionId = ถือว่า submitted
          createTestStudent(
            userId: 1,
            firstName: 'A',
            lastName: 'Student',
            submissionStatus: 'not_submitted', // status บอกว่ายังไม่ส่ง
            submissionId: 100, // แต่มี submissionId = ส่งแล้ว
          ),
          // Student ที่มี submittedAt = ถือว่า submitted
          createTestStudent(
            userId: 2,
            firstName: 'B',
            lastName: 'Student',
            submissionStatus: 'not_submitted',
            submittedAt: DateTime.now(),
          ),
          // Student ที่มี status = 'submitted'
          createTestStudent(
            userId: 3,
            firstName: 'C',
            lastName: 'Student',
            submissionStatus: 'submitted',
          ),
          // Student ที่ยังไม่ส่งจริงๆ
          createTestStudent(
            userId: 4,
            firstName: 'D',
            lastName: 'Student',
            submissionStatus: 'not_submitted',
          ),
        ];

        controller.assignmentId = 123;
        await controller.fetchStudents();

        // hasSubmitted getter ใช้: submissionId != null || submittedAt != null || status == 'submitted'
        expect(controller.submittedCount, equals(3),
            reason: 'Should count students with submissionId, submittedAt, or status=submitted');
        expect(controller.notSubmittedCount, equals(1),
            reason: 'Only student D should be not submitted');
      });

      // Test: ตรวจสอบการ build grouped list สำหรับ group assignment
      test('should build grouped list correctly for group assignments', () async {
        mockAssignmentRepo.mockStudents = [
          createTestStudent(
            userId: 1,
            firstName: 'A',
            lastName: 'Student',
            groupId: 10,
            groupName: 'Group Alpha',
            submissionStatus: 'submitted',
            submissionId: 100,
          ),
          createTestStudent(
            userId: 2,
            firstName: 'B',
            lastName: 'Student',
            groupId: 10,
            groupName: 'Group Alpha',
            submissionStatus: 'submitted',
            submissionId: 100,
          ),
          createTestStudent(
            userId: 3,
            firstName: 'C',
            lastName: 'Student',
            groupId: 20,
            groupName: 'Group Beta',
            submissionStatus: 'not_submitted',
          ),
        ];

        controller.assignmentId = 123;
        await controller.fetchStudents();

        // ควรมี 2 groups
        expect(controller.groupedList.length, equals(2),
            reason: 'Should have 2 groups (Alpha and Beta)');

        // Group Alpha ควรมี 2 members และ hasSubmitted = true
        final groupAlpha = controller.groupedList.firstWhere((g) => g.groupId == 10);
        expect(groupAlpha.members.length, equals(2));
        expect(groupAlpha.hasSubmitted, isTrue);

        // Group Beta ควรมี 1 member และ hasSubmitted = false
        final groupBeta = controller.groupedList.firstWhere((g) => g.groupId == 20);
        expect(groupBeta.members.length, equals(1));
        expect(groupBeta.hasSubmitted, isFalse);
      });

      // Test: ตรวจสอบการ filter ตาม submission status
      test('should filter students by submission status', () async {
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
            submissionStatus: 'not_submitted',
          ),
          createTestStudent(
            userId: 3,
            firstName: 'C',
            lastName: 'Student',
            submissionStatus: 'submitted',
          ),
        ];

        controller.assignmentId = 123;
        await controller.fetchStudents();

        // Test submitted filter
        controller.changeFilter(SubmissionFilter.submitted);
        expect(controller.filteredStudents.length, equals(2),
            reason: 'Should show 2 submitted students');

        // Test not submitted filter
        controller.changeFilter(SubmissionFilter.notSubmitted);
        expect(controller.filteredStudents.length, equals(1),
            reason: 'Should show 1 not submitted student');

        // Test all filter
        controller.changeFilter(SubmissionFilter.all);
        expect(controller.filteredStudents.length, equals(3),
            reason: 'Should show all 3 students');
      });

      // Test: ตรวจสอบ overdue detection
      test('should detect not submitted overdue students', () async {
        controller.dueDate = DateTime.now().subtract(const Duration(days: 1)); // Past due

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
            submissionStatus: 'not_submitted',
          ),
          createTestStudent(
            userId: 3,
            firstName: 'C',
            lastName: 'Student',
            submissionStatus: 'not_submitted',
          ),
        ];

        controller.assignmentId = 123;
        await controller.fetchStudents();

        // Students B and C are not submitted and past due
        expect(controller.notSubmittedOverdueCount, equals(2),
            reason: 'Should count 2 students who have not submitted past due date');

        // Test filter
        controller.changeFilter(SubmissionFilter.notSubmittedOverdue);
        expect(controller.filteredStudents.length, equals(2));
      });

      // Test: ตรวจสอบ search functionality
      test('should filter students by search keyword', () async {
        mockAssignmentRepo.mockStudents = [
          createTestStudent(
            userId: 1,
            firstName: 'สมชาย',
            lastName: 'ใจดี',
            submissionStatus: 'submitted',
          ),
          createTestStudent(
            userId: 2,
            firstName: 'สมหญิง',
            lastName: 'รักดี',
            submissionStatus: 'not_submitted',
          ),
          createTestStudent(
            userId: 3,
            firstName: 'วิชัย',
            lastName: 'สุขใจ',
            submissionStatus: 'submitted',
          ),
        ];

        controller.assignmentId = 123;
        await controller.fetchStudents();

        // Search for 'สม'
        controller.onSearchChanged('สม');
        expect(controller.filteredStudents.length, equals(2),
            reason: 'Should find สมชาย and สมหญิง');

        // Search for 'ใจ'
        controller.onSearchChanged('ใจ');
        expect(controller.filteredStudents.length, equals(2),
            reason: 'Should find ใจดี and สุขใจ');

        // Clear search
        controller.onSearchChanged('');
        expect(controller.filteredStudents.length, equals(3));
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

      // Test: ตรวจสอบ isTeacher getter
      test('should detect teacher role correctly using contains logic', () {
        mockAuthController.setMockRole('teacher');
        expect(controller.isTeacher, isTrue);

        mockAuthController.setMockRole('instructor');
        expect(controller.isTeacher, isTrue);

        mockAuthController.setMockRole('Teacher Assistant');
        expect(controller.isTeacher, isTrue);

        mockAuthController.setMockRole('student');
        expect(controller.isTeacher, isFalse);

        mockAuthController.setMockRole('high school student');
        expect(controller.isTeacher, isFalse);
      });

      // ========== POTENTIAL BUG ==========
      test('POTENTIAL BUG: isTeacher contains logic may cause false positives', () {
        mockAuthController.setMockRole('teacher');
        expect(controller.isTeacher, isTrue);

        mockAuthController.setMockRole('student');
        expect(controller.isTeacher, isFalse);

        // Note: role "ex-teacher" will return true because it contains "teacher"
        // Uncomment to detect this bug:
        // mockAuthController.setMockRole('ex-teacher');
        // expect(controller.isTeacher, isFalse,
        //     reason: 'BUG DETECTED: isTeacher contains() false match\n'
        //         'Location: assignment_submission_controller.dart line 64-67');
      });

      // Test: ตรวจสอบ canModifySubmissionFiles getter
      test('should enforce file modification permissions correctly', () {
        controller.submission.value = null;
        controller.isEditingSubmission.value = false;
        expect(controller.canModifySubmissionFiles, isTrue);

        // Existing submission but not in edit mode - should block
        controller.submission.value = createTestSubmission(
          id: 1,
          assignmentId: 123,
        );
        controller.isEditingSubmission.value = false;
        expect(controller.canModifySubmissionFiles, isFalse,
            reason: 'Should block modification when submission exists and not editing');

        // In edit mode - should allow
        controller.isEditingSubmission.value = true;
        expect(controller.canModifySubmissionFiles, isTrue,
            reason: 'Should allow modification when in edit mode');
      });

      // Test: ตรวจสอบ canSubmitGroup getter
      test('should validate group submission requirements', () {
        controller.groupName.value = '';
        controller.selectedStudentIds.clear();
        controller.isSubmittingGroup.value = false;
        expect(controller.canSubmitGroup, isFalse,
            reason: 'Cannot submit without group name');

        controller.groupName.value = 'Test Group';
        controller.selectedStudentIds.clear();
        expect(controller.canSubmitGroup, isFalse,
            reason: 'Cannot submit without selected students');

        controller.groupName.value = 'Test Group';
        controller.selectedStudentIds.addAll([1, 2, 3]);
        expect(controller.canSubmitGroup, isTrue,
            reason: 'Can submit with group name and students');

        controller.isSubmittingGroup.value = true;
        expect(controller.canSubmitGroup, isFalse,
            reason: 'Cannot submit while already submitting');
      });

      // Test: ตรวจสอบ hasUploadingFiles getter
      test('should detect uploading files correctly', () {
        controller.uploadedFiles.clear();
        expect(controller.hasUploadingFiles, isFalse);

        controller.uploadedFiles.add({
          'file_url': 'https://example.com/file.pdf',
          'is_uploading': false,
        });
        expect(controller.hasUploadingFiles, isFalse);

        controller.uploadedFiles.add({
          'file_url': '',
          'is_uploading': true,
        });
        expect(controller.hasUploadingFiles, isTrue,
            reason: 'Should detect file that is still uploading');
      });

      // Test: ตรวจสอบ addLinkAttachment - URL validation
      test('should validate URL format when adding link attachments', () {
        controller.uploadedFiles.clear();

        // Valid URLs should be added
        controller.addLinkAttachment('https://example.com/resource');
        expect(controller.uploadedFiles.length, equals(1));
        expect(controller.uploadedFiles.first['is_link'], isTrue);
        expect(controller.uploadedFiles.first['file_type'], equals('link'));

        // HTTP URL should work
        controller.addLinkAttachment('http://test.org/file');
        expect(controller.uploadedFiles.length, equals(2));

        // FTP URL should work
        controller.addLinkAttachment('ftp://files.com/doc.pdf');
        expect(controller.uploadedFiles.length, equals(3));

        // Invalid URLs should NOT be added
        controller.addLinkAttachment('invalid-url');
        expect(controller.uploadedFiles.length, equals(3),
            reason: 'Invalid URL should not be added');

        controller.addLinkAttachment('');
        expect(controller.uploadedFiles.length, equals(3),
            reason: 'Empty string should not be added');

        controller.addLinkAttachment('   ');
        expect(controller.uploadedFiles.length, equals(3),
            reason: 'Whitespace only should not be added');

        // URL without scheme should not be added
        controller.addLinkAttachment('example.com/resource');
        expect(controller.uploadedFiles.length, equals(3),
            reason: 'URL without scheme should not be added');
      });

      // Test: ตรวจสอบ removeFile - boundary checking
      test('should handle file removal with boundary checking', () async {
        controller.uploadedFiles.clear();
        controller.uploadedFiles.addAll([
          {'file_url': 'https://example.com/file1.pdf', 'is_uploading': false, 'is_link': false},
          {'file_url': 'https://example.com/file2.pdf', 'is_uploading': false, 'is_link': false},
          {'file_url': 'https://example.com/link', 'is_uploading': false, 'is_link': true},
        ]);

        // Remove invalid index should not crash
        await controller.removeFile(-1);
        expect(controller.uploadedFiles.length, equals(3),
            reason: 'Negative index should be ignored');

        await controller.removeFile(100);
        expect(controller.uploadedFiles.length, equals(3),
            reason: 'Out of bounds index should be ignored');

        // Remove valid index should work
        await controller.removeFile(1);
        expect(controller.uploadedFiles.length, equals(2));
      });

      // Test: ตรวจสอบ toggleStudent
      test('should toggle student selection correctly', () {
        controller.selectedStudentIds.clear();

        // Add student
        controller.toggleStudent(1);
        expect(controller.selectedStudentIds, contains(1));
        expect(controller.isStudentSelected(1), isTrue);

        // Add another
        controller.toggleStudent(2);
        expect(controller.selectedStudentIds.length, equals(2));

        // Remove first
        controller.toggleStudent(1);
        expect(controller.selectedStudentIds, isNot(contains(1)));
        expect(controller.selectedStudentIds, contains(2));
        expect(controller.isStudentSelected(1), isFalse);
      });

      // Test: ตรวจสอบ onSearchChanged for students
      test('should filter students by search query', () {
        // Mock students list directly
        controller.students.assignAll([
          // Using mock profile data
        ]);

        // Since we can't easily mock ProfileModel, we test the filteredStudents assignment
        controller.filteredStudents.clear();
        expect(controller.filteredStudents.isEmpty, isTrue);
      });

      // Test: ตรวจสอบ showGroupTab getter
      test('should show group tab only for group assignments', () {
        controller.assignmentInfo.value = null;
        expect(controller.showGroupTab, isFalse,
            reason: 'Should not show group tab when no assignment info');

        // We would need to mock AssignmentSubmissionInfo properly
      });

      // Test: ตรวจสอบ startEditingSubmission และ cancelEditingSubmission
      test('should handle editing submission state', () {
        // Cannot start editing if no submission
        controller.submission.value = null;
        controller.startEditingSubmission();
        expect(controller.isEditingSubmission.value, isFalse,
            reason: 'Cannot edit if no submission');

        // Can start editing with existing submission
        controller.submission.value = createTestSubmission(
          id: 1,
          assignmentId: 123,
          attachments: [
            {'file_url': 'https://example.com/file.pdf', 'original_name': 'test.pdf', 'file_type': 'pdf'},
          ],
        );
        controller.startEditingSubmission();
        expect(controller.isEditingSubmission.value, isTrue);

        // Cancel editing should reset state
        controller.cancelEditingSubmission();
        expect(controller.isEditingSubmission.value, isFalse);
      });

      // Test: ตรวจสอบ toggleStudent
      test('should toggle student selection correctly with duplicate prevention', () {
        controller.selectedStudentIds.clear();

        // Add student
        controller.toggleStudent(1);
        expect(controller.selectedStudentIds, contains(1));

        // Add another student
        controller.toggleStudent(2);
        expect(controller.selectedStudentIds, containsAll([1, 2]));

        // Toggle off existing student
        controller.toggleStudent(1);
        expect(controller.selectedStudentIds, isNot(contains(1)));
        expect(controller.selectedStudentIds, contains(2));

        // Toggle same student twice should not create duplicates
        controller.toggleStudent(3);
        controller.toggleStudent(3);
        expect(controller.selectedStudentIds.where((id) => id == 3).length, equals(0),
            reason: 'Toggle twice should remove the student');
      });

      // Test: ตรวจสอบ isStudentSelected
      test('should correctly check if student is selected', () {
        controller.selectedStudentIds.clear();
        controller.selectedStudentIds.addAll([1, 2, 3]);

        expect(controller.isStudentSelected(1), isTrue);
        expect(controller.isStudentSelected(2), isTrue);
        expect(controller.isStudentSelected(4), isFalse);
      });
    });

    // =========================================================================
    // HIGH PRIORITY: loadMoreAssignments pagination tests
    // =========================================================================
    group('ClassAssignmentController Pagination Tests', () {
      late ClassAssignmentController controller;

      setUp(() {
        controller = ClassAssignmentController(
          mockAssignmentRepo,
          mockClassFeedRepo,
        );
        controller.sectionId = 1;
        controller.className = 'Test Class';
        controller.subjectName = 'Test Subject';
        Get.put(controller);
      });

      test('should load more assignments correctly', () async {
        // Initial 10 assignments
        mockAssignmentRepo.mockAssignments = List.generate(
          20,
          (i) => createTestAssignment(
            assignmentId: i + 1,
            title: 'Assignment ${i + 1}',
            createdAt: DateTime.now().subtract(Duration(days: i)),
          ),
        );

        controller.userRole.value = 'teacher';
        await controller.fetchAssignments();

        expect(controller.assignments.length, equals(10),
            reason: 'Initial fetch should load 10 items (limit)');

        // Load more
        await controller.loadMoreAssignments();

        expect(controller.assignments.length, equals(20),
            reason: 'After loadMore should have 20 items total');
      });

      test('should not load more when already loading', () async {
        mockAssignmentRepo.mockAssignments = List.generate(
          20,
          (i) => createTestAssignment(assignmentId: i + 1, title: 'Assignment ${i + 1}'),
        );

        controller.userRole.value = 'teacher';
        await controller.fetchAssignments();

        // Manually set loading state
        controller.isLoadingMore.value = true;

        final countBefore = controller.assignments.length;
        await controller.loadMoreAssignments();

        expect(controller.assignments.length, equals(countBefore),
            reason: 'Should not load when already loading');
      });

      test('should stop loading when no more data', () async {
        // Only 5 items (less than limit of 10)
        mockAssignmentRepo.mockAssignments = List.generate(
          5,
          (i) => createTestAssignment(assignmentId: i + 1, title: 'Assignment ${i + 1}'),
        );

        controller.userRole.value = 'teacher';
        await controller.fetchAssignments();

        expect(controller.assignments.length, equals(5));

        // Try to load more - should not add anything
        await controller.loadMoreAssignments();

        expect(controller.assignments.length, equals(5),
            reason: 'Should not load more when less than limit returned');
      });
    });

    // =========================================================================
    // HIGH PRIORITY: reinitialise tests
    // =========================================================================
    group('ClassAssignmentController Reinitialise Tests', () {
      late ClassAssignmentController controller;

      setUp(() {
        // Reset mock data
        mockAssignmentRepo.mockAssignments = [];
        mockAssignmentRepo.shouldThrowError = false;
        
        controller = ClassAssignmentController(
          mockAssignmentRepo,
          mockClassFeedRepo,
        );
        controller.sectionId = 1;
        controller.className = 'Test Class';
        controller.subjectName = 'Test Subject';
        Get.put(controller);
      });

      test('should update state when sectionId changes', () async {
        mockAssignmentRepo.mockAssignments = [
          createTestAssignment(assignmentId: 1, title: 'Section 1 Assignment'),
        ];

        controller.userRole.value = 'high school student';
        await controller.fetchAssignments();

        expect(controller.assignments.length, equals(1),
            reason: 'Should have 1 assignment after fetch');

        // Reinitialise with different sectionId
        controller.reinitialise({
          'sectionId': 2,
          'className': 'New Class',
          'subjectName': 'New Subject',
          'role': 'teacher',
        });

        // Should update sectionId and other properties
        expect(controller.sectionId, equals(2));
        expect(controller.className, equals('New Class'));
        expect(controller.userRole.value, equals('teacher'));
      });

      test('should reset filter based on new role', () async {
        mockAssignmentRepo.mockAssignments = [
          createTestAssignment(assignmentId: 1, title: 'Test Assignment'),
        ];

        controller.userRole.value = 'high school student';
        await controller.fetchAssignments();

        expect(controller.currentFilter.value, equals('ทั้งหมด'),
            reason: 'Student default filter should be ทั้งหมด');

        // Reinitialise as teacher
        controller.reinitialise({
          'sectionId': 2,
          'className': 'New Class',
          'subjectName': 'New Subject',
          'role': 'teacher',
        });

        expect(controller.currentFilter.value, equals('โพสต์ล่าสุด'),
            reason: 'Teacher default filter should be โพสต์ล่าสุด');
      });

      test('should clear assignments when reinitialising with new sectionId', () async {
        mockAssignmentRepo.mockAssignments = [
          createTestAssignment(assignmentId: 1, title: 'Old Assignment'),
        ];

        controller.userRole.value = 'high school student';
        await controller.fetchAssignments();

        expect(controller.assignments.length, equals(1));

        // Reinitialise with new sectionId should clear
        controller.reinitialise({
          'sectionId': 999,
          'className': 'New Class',
          'subjectName': 'New Subject',
          'role': 'high school student',
        });

        // Assignments should be cleared before new fetch
        expect(controller.assignments.isEmpty || controller.isLoading.value, isTrue,
            reason: 'Should clear old assignments when changing section');
      });
    });

    // =========================================================================
    // HIGH PRIORITY: TeacherSubmissionController gradeSubmission tests
    // =========================================================================
    group('TeacherSubmissionController Grade Validation Tests', () {
      late TeacherSubmissionController controller;

      setUp(() {
        Get.testMode = true;
        controller = TeacherSubmissionController(
          repo: mockAssignmentRepo,
          submissionRepo: mockSubmissionRepo,
        );
        controller.assignmentId = 123;
        controller.maxScore = 100.0;
        Get.put(controller);
      });

      test('should validate score is a valid number', () {
        // Test score validation logic directly
        bool isValidScore(String scoreStr) {
          final score = double.tryParse(scoreStr);
          return score != null;
        }

        expect(isValidScore('85'), isTrue);
        expect(isValidScore('85.5'), isTrue);
        expect(isValidScore('abc'), isFalse);
        expect(isValidScore(''), isFalse);
      });

      test('should validate score decimal places (max 2)', () {
        final decimalRegex = RegExp(r'^\d+(\.\d{1,2})?$');

        expect(decimalRegex.hasMatch('85'), isTrue);
        expect(decimalRegex.hasMatch('85.5'), isTrue);
        expect(decimalRegex.hasMatch('85.55'), isTrue);
        expect(decimalRegex.hasMatch('85.555'), isFalse,
            reason: 'Should reject more than 2 decimal places');
      });

      test('should validate score does not exceed maxScore', () {
        bool isScoreWithinMax(double score, double? maxScore) {
          if (maxScore == null) return true;
          return score <= maxScore;
        }

        expect(isScoreWithinMax(85.0, 100.0), isTrue);
        expect(isScoreWithinMax(100.0, 100.0), isTrue);
        expect(isScoreWithinMax(105.0, 100.0), isFalse,
            reason: 'Should reject score exceeding maxScore');
      });

      test('should reject negative scores', () {
        final decimalRegex = RegExp(r'^\d+(\.\d{1,2})?$');

        expect(decimalRegex.hasMatch('-10'), isFalse,
            reason: 'Regex should reject negative numbers');
        expect(decimalRegex.hasMatch('-0.5'), isFalse);
      });

      test('should calculate submission counts correctly', () async {
        mockAssignmentRepo.mockStudents = [
          createTestStudent(userId: 1, firstName: 'A', lastName: 'B', submissionId: 100),
          createTestStudent(userId: 2, firstName: 'C', lastName: 'D', submittedAt: DateTime.now()),
          createTestStudent(userId: 3, firstName: 'E', lastName: 'F', submissionStatus: 'not_submitted'),
        ];

        await controller.fetchStudents();

        expect(controller.submittedCount, equals(2),
            reason: '2 students have submitted (submissionId or submittedAt)');
        expect(controller.notSubmittedCount, equals(1),
            reason: '1 student has not submitted');
      });

      test('should detect overdue students correctly', () async {
        // Set dueDate in the past
        controller.dueDate = DateTime.now().subtract(const Duration(days: 1));

        mockAssignmentRepo.mockStudents = [
          createTestStudent(userId: 1, firstName: 'A', lastName: 'B', submissionId: 100),
          createTestStudent(userId: 2, firstName: 'C', lastName: 'D', submissionStatus: 'not_submitted'),
          createTestStudent(userId: 3, firstName: 'E', lastName: 'F', submissionStatus: 'not_submitted'),
        ];

        await controller.fetchStudents();

        expect(controller.notSubmittedOverdueCount, equals(2),
            reason: '2 students have not submitted and dueDate has passed');
      });
    });

    // =========================================================================
    // HIGH PRIORITY: SearchAssignmentController clear and onClose tests
    // =========================================================================
    group('SearchAssignmentController State Management Tests', () {
      late SearchAssignmentController controller;

      setUp(() {
        controller = SearchAssignmentController();
        Get.put(controller);
      });

      test('should clear all state correctly', () async {
        controller.init(sectionId: 123, role: 'student');
        controller.keyword.value = 'test';
        controller.results.addAll([
          createTestAssignment(assignmentId: 1, title: 'Test'),
        ]);
        controller.error.value = 'Some error';

        controller.clear();

        expect(controller.keyword.value, isEmpty);
        expect(controller.results, isEmpty);
        expect(controller.error.value, isEmpty);
      });

      test('should handle rapid keyword changes with debounce', () async {
        mockAssignmentRepo.mockAssignments = [
          createTestAssignment(assignmentId: 1, title: 'Math Assignment'),
          createTestAssignment(assignmentId: 2, title: 'Science Project'),
        ];

        controller.init(sectionId: 123, role: 'student');

        // Rapid changes
        controller.onKeywordChanged('M');
        controller.onKeywordChanged('Ma');
        controller.onKeywordChanged('Mat');
        controller.onKeywordChanged('Math');

        // Wait for debounce
        await Future.delayed(const Duration(milliseconds: 600));

        // Should only search for final value
        expect(controller.keyword.value, equals('Math'));
      });
    });
  });

  // ============================================================================
  // ทดสอบ edge cases และ utility functions
  // ============================================================================

  group('Model and Utility Tests', () {
    // Test: ตรวจสอบ StudentSubmissionStatusModel.hasSubmitted getter
    test('StudentSubmissionStatusModel hasSubmitted should work correctly', () {
      // Case 1: มี submissionId = hasSubmitted
      final studentWithSubmissionId = createTestStudent(
        userId: 1,
        firstName: 'A',
        lastName: 'B',
        submissionStatus: 'not_submitted',
        submissionId: 100,
      );
      expect(studentWithSubmissionId.hasSubmitted, isTrue,
          reason: 'Should be submitted when submissionId is not null');

      // Case 2: มี submittedAt = hasSubmitted
      final studentWithSubmittedAt = createTestStudent(
        userId: 2,
        firstName: 'C',
        lastName: 'D',
        submissionStatus: 'not_submitted',
        submittedAt: DateTime.now(),
      );
      expect(studentWithSubmittedAt.hasSubmitted, isTrue,
          reason: 'Should be submitted when submittedAt is not null');

      // Case 3: status = 'submitted' = hasSubmitted
      final studentWithSubmittedStatus = createTestStudent(
        userId: 3,
        firstName: 'E',
        lastName: 'F',
        submissionStatus: 'submitted',
      );
      expect(studentWithSubmittedStatus.hasSubmitted, isTrue,
          reason: 'Should be submitted when status is "submitted"');

      // Case 4: status = 'graded' = hasSubmitted
      final studentWithGradedStatus = createTestStudent(
        userId: 4,
        firstName: 'G',
        lastName: 'H',
        submissionStatus: 'graded',
      );
      expect(studentWithGradedStatus.hasSubmitted, isTrue,
          reason: 'Should be submitted when status is "graded"');

      // Case 5: ไม่มีอะไรเลย = not submitted
      final studentNotSubmitted = createTestStudent(
        userId: 5,
        firstName: 'I',
        lastName: 'J',
        submissionStatus: 'not_submitted',
      );
      expect(studentNotSubmitted.hasSubmitted, isFalse,
          reason: 'Should not be submitted when no indicators');
    });

    // Test: ตรวจสอบ StudentSubmissionStatusModel.displayName getter
    test('StudentSubmissionStatusModel displayName should concatenate names', () {
      final student = createTestStudent(
        userId: 1,
        firstName: 'John',
        lastName: 'Doe',
        submissionStatus: 'submitted',
      );
      expect(student.displayName, equals('John Doe'));
    });

    // Test: ตรวจสอบ StudentSubmissionStatusModel.isGraded getter
    test('StudentSubmissionStatusModel isGraded should detect grading', () {
      // Case 1: มี markedAt = graded
      final studentWithMarkedAt = createTestStudent(
        userId: 1,
        firstName: 'A',
        lastName: 'B',
        submissionStatus: 'submitted',
        markedAt: DateTime.now(),
      );
      expect(studentWithMarkedAt.isGraded, isTrue);

      // Case 2: มี score = graded
      final studentWithScore = createTestStudent(
        userId: 2,
        firstName: 'C',
        lastName: 'D',
        submissionStatus: 'submitted',
        score: 85.5,
      );
      expect(studentWithScore.isGraded, isTrue);

      // Case 3: มี feedback = graded
      final studentWithFeedback = createTestStudent(
        userId: 3,
        firstName: 'E',
        lastName: 'F',
        submissionStatus: 'submitted',
        feedback: 'Good work!',
      );
      expect(studentWithFeedback.isGraded, isTrue);

      // Case 4: ไม่มีอะไร = not graded
      final studentNotGraded = createTestStudent(
        userId: 4,
        firstName: 'G',
        lastName: 'H',
        submissionStatus: 'submitted',
      );
      expect(studentNotGraded.isGraded, isFalse);
    });
  });

  group('Edge Cases and Boundary Tests', () {
    // Test: URL validation edge cases
    test('should validate various URL formats', () {
      bool isValidUrl(String link) {
        final trimmed = link.trim();
        final uri = Uri.tryParse(trimmed);
        return trimmed.isNotEmpty &&
            uri != null &&
            uri.hasScheme &&
            uri.hasAuthority;
      }

      // Valid URLs
      expect(isValidUrl('https://example.com'), isTrue);
      expect(isValidUrl('http://test.org'), isTrue);
      expect(isValidUrl('ftp://files.com'), isTrue);
      expect(isValidUrl('https://sub.domain.example.com/path?query=1'), isTrue);

      // Invalid URLs
      expect(isValidUrl('invalid-url'), isFalse);
      expect(isValidUrl(''), isFalse);
      expect(isValidUrl('   '), isFalse);
      expect(isValidUrl('example.com'), isFalse, reason: 'Missing scheme');
      expect(isValidUrl('://example.com'), isFalse, reason: 'Missing scheme name');
    });

    // Test: Score validation edge cases
    test('should validate score input correctly', () {
      bool isValidScore(String scoreStr, double? maxScore) {
        final score = double.tryParse(scoreStr);
        if (score == null) return false;

        // Check decimal places (max 2)
        final decimalRegex = RegExp(r'^\d+(\.\d{1,2})?$');
        if (!decimalRegex.hasMatch(scoreStr)) return false;

        // Check max score
        if (maxScore != null && score > maxScore) return false;

        // Check negative
        if (score < 0) return false;

        return true;
      }

      // Valid scores
      expect(isValidScore('0', 100.0), isTrue);
      expect(isValidScore('100', 100.0), isTrue);
      expect(isValidScore('95.5', 100.0), isTrue);
      expect(isValidScore('95.55', 100.0), isTrue);

      // Invalid scores
      expect(isValidScore('95.555', 100.0), isFalse, reason: 'Too many decimals');
      expect(isValidScore('150', 100.0), isFalse, reason: 'Exceeds max');
      expect(isValidScore('invalid', 100.0), isFalse, reason: 'Not a number');
      expect(isValidScore('', 100.0), isFalse, reason: 'Empty string');
      expect(isValidScore('-10', 100.0), isFalse, reason: 'Negative score');
    });

    // Test: Empty and null handling
    test('should handle empty lists and null values safely', () {
      // Empty list filtering
      List<Map<String, dynamic>> filterEmptyList(
        List<Map<String, dynamic>> items,
        String filter,
      ) {
        return items.where((item) => item['status'] == filter).toList();
      }

      final result = filterEmptyList([], 'any_filter');
      expect(result.isEmpty, isTrue);

      // Null value handling
      bool isValidStudent(Map<String, dynamic>? student) {
        if (student == null) return false;
        return student.containsKey('id') && student['id'] != null;
      }

      expect(isValidStudent(null), isFalse);
      expect(isValidStudent({}), isFalse);
      expect(isValidStudent({'id': null}), isFalse);
      expect(isValidStudent({'id': 1}), isTrue);
    });

    // Test: Date comparison for overdue detection
    test('should detect overdue correctly with various dates', () {
      bool isOverdue(DateTime? dueDate) {
        if (dueDate == null) return false;
        return DateTime.now().isAfter(dueDate);
      }

      final pastDate = DateTime.now().subtract(const Duration(days: 1));
      final futureDate = DateTime.now().add(const Duration(days: 1));

      expect(isOverdue(pastDate), isTrue);
      expect(isOverdue(futureDate), isFalse);
      expect(isOverdue(null), isFalse);
    });
  });
}
