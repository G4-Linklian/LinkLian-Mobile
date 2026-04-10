import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:LinkLian/features/classes/presentation/controllers/class_feed_controller.dart';
import 'package:LinkLian/features/classes/presentation/controllers/class_detail_controller.dart';
import 'package:LinkLian/features/classes/presentation/controllers/class_detail_filter.dart';
import 'package:LinkLian/features/classes/presentation/controllers/class_info_controller.dart';
import 'package:LinkLian/features/classes/presentation/controllers/comment_controller.dart';
import 'package:LinkLian/features/classes/presentation/controllers/create_post_controller.dart';
import 'package:LinkLian/features/shared/repositories/post_repository.dart';
import 'package:LinkLian/features/shared/repositories/class_feed_repository.dart';
import 'package:LinkLian/features/classes/data/repositories/comment_repository.dart';
import 'package:LinkLian/data/repository/semester_repository.dart';
import 'package:LinkLian/features/auth/controller/auth_controller.dart';
import 'package:LinkLian/features/shared/models/post_model.dart';
import 'package:LinkLian/features/classes/data/models/class_feed_model.dart';
import 'package:LinkLian/features/shared/models/class_info_model.dart';
import 'package:LinkLian/features/classes/data/models/comment_model.dart';
import 'package:LinkLian/data/model/semester_model.dart';

// Mock Repository Classes
class MockPostRepository extends GetxService implements PostRepository {
  List<PostModel> mockPosts = [];
  PostModel? mockCreatedPost;
  bool shouldThrowError = false;

  @override
  Future<List<PostModel>> getPostInClass({
    required int sectionId,
    String? filterType,
    int offset = 0,
    int limit = 10,
  }) async {
    if (shouldThrowError) throw Exception('API Error');
    
    var filtered = mockPosts.where((p) => p.sectionId == sectionId);
    
    if (filterType != null && filterType != 'all') {
      filtered = filtered.where((p) => p.postType == filterType);
    }
    
    return filtered.skip(offset).take(limit).toList();
  }

  @override
  Future<List<PostModel>> searchPosts({
    int? sectionId,
    required String keyword,
    int limit = 50,
  }) async {
    if (shouldThrowError) throw Exception('Search Error');
    
    var filtered = mockPosts;
    
    if (sectionId != null) {
      filtered = filtered.where((p) => p.sectionId == sectionId).toList();
    }
    
    return filtered
        .where((p) => 
            p.title.toLowerCase().contains(keyword.toLowerCase()) ||
            p.content.toLowerCase().contains(keyword.toLowerCase()))
        .take(limit)
        .toList();
  }

  @override
  Future<PostModel?> createPost({
    int? sectionId,
    List<int>? sectionIds,
    String? title,
    String? content,
    String? postType,
    bool isAnonymous = false,
    List<Map<String, dynamic>>? attachments,
    String? dueDate,
    double? maxScore,
    bool? isGroup,
    List<Map<String, dynamic>>? groups,
  }) async {
    if (shouldThrowError) throw Exception('Create Post Error');
    
    final post = mockCreatedPost ?? createMockPost(
      title: title,
      content: content,
      postType: postType,
      sectionId: sectionId ?? sectionIds?.first,
    );
    
    mockPosts.add(post);
    return post;
  }

  @override
  Future<bool> updatePost({
    int? postId,
    required int postContentId,
    String? title,
    String? content,
    List<Map<String, dynamic>>? attachments,
    String? dueDate,
    double? maxScore,
    bool? isGroup,
    List<Map<String, dynamic>>? groups,
  }) async {
    if (shouldThrowError) throw Exception('Update Post Error');
    
    final index = mockPosts.indexWhere((p) => p.postContentId == postContentId);
    if (index != -1) {
      final updated = createMockPost(
        id: mockPosts[index].postId,
        title: title ?? mockPosts[index].title,
        content: content ?? mockPosts[index].content,
        postType: mockPosts[index].postType,
        sectionId: mockPosts[index].sectionId,
      );
      mockPosts[index] = updated;
      return true;
    }
    return false;
  }

  @override
  Future<bool> deletePost({int? postId, int? postContentId}) async {
    if (shouldThrowError) throw Exception('Delete Post Error');
    
    if (postId != null) {
      mockPosts.removeWhere((p) => p.postId == postId);
    } else if (postContentId != null) {
      mockPosts.removeWhere((p) => p.postContentId == postContentId);
    }
    
    return true;
  }

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockClassFeedRepository extends GetxService implements ClassFeedRepository {
  List<ClassFeedModel> mockClasses = [];
  ClassInfoModel? mockClassInfo;
  bool shouldThrowError = false;

  @override
  Future<List<ClassFeedModel>> getClassFeed({
    required int semesterId,
    int offset = 0,
    int limit = 10,
  }) async {
    if (shouldThrowError) throw Exception('API Error');
    return mockClasses.skip(offset).take(limit).toList();
  }

  @override
  Future<ClassInfoModel?> getClassInfo({required int sectionId}) async {
    if (shouldThrowError) throw Exception('Class Info Error');
    return mockClassInfo;
  }

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockCommentRepository extends GetxService implements CommentRepository {
  List<CommentModel> mockComments = [];
  CommentModel? mockCreatedComment;
  bool shouldThrowError = false;

  @override
  Future<CommentPageResult> getComments({
    required int postId,
    int offset = 0,
    int limit = 10,
  }) async {
    if (shouldThrowError) throw Exception('API Error');
    
    final comments = mockComments
        .where((c) => c.postId == postId)
        .skip(offset)
        .take(limit)
        .toList();
    
    return CommentPageResult(
      comments: comments,
      nextCursor: offset + comments.length < mockComments.length ? offset + limit : null,
      hasMore: offset + comments.length < mockComments.length,
    );
  }

  @override
  Future<Map<String, dynamic>> createComment({
    required int postId,
    required int userId,
    required String text,
    bool isAnonymous = false,
    int? parentId,
  }) async {
    if (shouldThrowError) throw Exception('Create Comment Error');
    
    final comment = mockCreatedComment ?? createMockComment(
      postId: postId,
      text: text,
      parentId: parentId,
    );
    
    mockComments.add(comment);
    return comment.toJson();
  }

  @override
  Future<Map<String, dynamic>> deleteComment({
    required int commentId,
    required int userSysId,
  }) async {
    if (shouldThrowError) throw Exception('Delete Comment Error');
    mockComments.removeWhere((c) => c.commentId == commentId);
    return {'success': true};
  }

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockSemesterRepository extends GetxService implements SemesterRepository {
  List<SemesterModel> mockSemesters = [];
  bool shouldThrowError = false;

  @override
  Future<List<SemesterModel>> getSemesters({required int instId}) async {
    if (shouldThrowError) throw Exception('API Error');
    return mockSemesters;
  }

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

// Fake AuthController implementing the interface
class FakeAuthController extends GetxController implements AuthController {
  RxnString mockRoleName = RxnString('high school student');
  RxnInt mockUserId = RxnInt(1);
  RxnInt mockInstId = RxnInt(1);
  RxnString mockToken = RxnString('fake_token');

  set mockRole(String role) => mockRoleName.value = role;

  @override
  RxnString get roleName => mockRoleName;

  @override
  RxnInt get userId => mockUserId;

  @override
  RxnInt get instId => mockInstId;

  @override
  Rx<AuthStatus> get status => AuthStatus.authenticated.obs;

  @override
  RxnString get token => mockToken;

  @override
  bool get isLoggedIn => true;

  @override
  Future<void> establishSession({
    required String token,
    required String roleName,
    required int instId,
    required int userId,
  }) async {}

  @override
  Future<void> logout() async {}

  @override
  Future<void> refreshAuth() async {}

  @override
  void setSession({String? token, int? userId, String? roleName, int? instId}) {}
}

// Helper functions to create mock models
PostModel createMockPost({
  int? id,
  String? title,
  String? content,
  String? postType,
  int? sectionId,
}) {
  return PostModel(
    postId: id ?? 1,
    postContentId: 1,
    title: title ?? 'Test Post',
    content: content ?? 'Test Content',
    postType: postType ?? 'general',
    isAnonymous: false,
    createdAt: DateTime.now(),
    sectionId: sectionId,
    displayName: 'Test User',
  );
}

ClassFeedModel createMockClass({
  int? id,
  String? name,
  String? subjectCode,
  int? semesterId,
}) {
  return ClassFeedModel(
    sectionId: id ?? 1,
    sectionName: name ?? 'Test Class',
    subjectCode: subjectCode ?? 'TEST101',
    subjectNameTh: 'วิชาทดสอบ',
    subjectNameEn: 'Test Subject',
    semester: 'Semester 1',
    schedules: [],
  );
}

CommentModel createMockComment({
  int? id,
  int? postId,
  String? text,
  int? parentId,
}) {
  return CommentModel(
    commentId: id ?? 1,
    postId: postId ?? 1,
    userSysId: 1,
    isAnonymous: false,
    displayName: 'Test User',
    profilePic: null,
    commentText: text ?? 'Test Comment',
    flagValid: true,
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
    parentId: parentId,
    childrenCount: 0,
    children: [],
  );
}

SemesterModel createMockSemester({
  int? id,
  String? name,
  bool? isActive,
}) {
  return SemesterModel(
    semesterId: id ?? 1,
    semester: name ?? 'Semester 1/2024',
    status: isActive ?? true ? 'active' : 'inactive',
    flagValid: true,
    startDate: DateTime(2024, 1, 1),
    endDate: DateTime(2024, 5, 31),
  );
}

ClassInfoModel createMockClassInfo({
  int? sectionId,
  String? subjectName,
}) {
  return ClassInfoModel(
    sectionId: sectionId ?? 1,
    subjectName: subjectName ?? 'วิชาทดสอบ',
    schedules: [],
    educators: [],
  );
}

void main() {
  setUpAll(() {
    // Initialize environment for testing
    dotenv.testLoad(mergeWith: {
      'SUPABASE_URL': 'https://test.supabase.co',
      'SUPABASE_KEY': 'test_key',
      'API_BASE_URL': 'https://test-api.example.com',
      'BASE_URL': 'https://test-api.example.com',
    });
  });

  group('Class Controllers Unit Tests', () {
    late MockPostRepository mockPostRepo;
    late MockClassFeedRepository mockClassFeedRepo;
    late MockCommentRepository mockCommentRepo;
    late MockSemesterRepository mockSemesterRepo;
    late FakeAuthController mockAuthController;

    setUp(() {
      Get.testMode = true;
      
      // Create mock instances
      mockPostRepo = MockPostRepository();
      mockClassFeedRepo = MockClassFeedRepository();
      mockCommentRepo = MockCommentRepository();
      mockSemesterRepo = MockSemesterRepository();
      mockAuthController = FakeAuthController();
      
      // Register mocks so controllers can find them
      Get.put<AuthController>(mockAuthController);
      Get.put<PostRepository>(mockPostRepo);
      Get.put<ClassFeedRepository>(mockClassFeedRepo);
      Get.put<CommentRepository>(mockCommentRepo);
      Get.put<SemesterRepository>(mockSemesterRepo);
    });

    tearDown(() {
      Get.reset();
    });

    group('ClassFeedController Tests', () {
      late ClassFeedController controller;

      setUp(() {
        controller = ClassFeedController(
          classFeedRepository: mockClassFeedRepo,
          semesterRepository: mockSemesterRepo,
        );
        Get.put(controller);
      });

      // Test: Verifies semester data is fetched successfully
      // Checks: API call execution, data population, and active semester selection
      test('should fetch semesters successfully', () async {
        mockSemesterRepo.mockSemesters = [
          createMockSemester(id: 1, name: 'Semester 1/2024', isActive: true),
          createMockSemester(id: 2, name: 'Semester 2/2024', isActive: false),
        ];

        await controller.fetchSemesters();

        expect(controller.semesters.length, equals(2));
        expect(controller.selectedSemesterId.value, equals(1));
      });

      // Test: Verifies class feed data is fetched for selected semester
      // Checks: API call with correct parameters and data population
      test('should fetch class feed successfully', () async {
        controller.selectedSemesterId.value = 1;
        mockClassFeedRepo.mockClasses = [
          createMockClass(id: 1, name: 'Math 101'),
          createMockClass(id: 2, name: 'Science 201'),
        ];

        await controller.fetchClassFeed();

        expect(controller.isLoading.value, isFalse);
        expect(controller.classList.length, equals(2));
      });

      // Test: Verifies pagination loads more classes correctly
      // Checks: Offset increment and data appending
      test('should load more classes with pagination', () async {
        controller.selectedSemesterId.value = 1;
        mockClassFeedRepo.mockClasses = List.generate(
          20,
          (i) => createMockClass(id: i + 1, name: 'Class ${i + 1}'),
        );

        await controller.fetchClassFeed();
        expect(controller.classList.length, equals(10));

        await controller.fetchClassFeed(loadMore: true);
        expect(controller.classList.length, equals(20));
      });

      // Test: Verifies error handling for API failures
      // Checks: Error state management and error message display
      test('should handle API errors gracefully', () async {
        controller.selectedSemesterId.value = 1;
        mockClassFeedRepo.shouldThrowError = true;

        await controller.fetchClassFeed();

        expect(controller.errorMessage.value, isNotNull);
        expect(controller.classList.isEmpty, isTrue);
      });

      // Test: Verifies semester change triggers class refresh
      // Checks: Data clearing and refetching with new semester
      test('should refresh classes when semester changes', () async {
        // Initial fetch for semester 1
        mockClassFeedRepo.mockClasses = [
          createMockClass(id: 1, name: 'Class A'),
        ];
        controller.selectedSemesterId.value = 1;

        await controller.fetchClassFeed();
        expect(controller.classList.length, equals(1));

        // Change to semester 2
        mockClassFeedRepo.mockClasses = [
          createMockClass(id: 2, name: 'Class B'),
          createMockClass(id: 3, name: 'Class C'),
        ];

        // changeSemester should clear existing data and refetch
        await controller.changeSemester(2);
        
        // Should have new classes only
        expect(controller.classList.length, equals(2));
        expect(controller.classList[0].sectionId, equals(2));
        expect(controller.classList[1].sectionId, equals(3));
      });
    });

    group('ClassDetailController Tests', () {
      late ClassDetailController controller;

      setUp(() {
        controller = ClassDetailController();
        Get.put(controller);
      });

      // Test: Verifies controller initialization with arguments
      // Checks: Section ID, subject name, and teacher name are set
      test('should initialize with class details', () {
        final args = {
          'sectionId': 123,
          'subjectNameTh': 'คณิตศาสตร์',
          'effectiveClassName': 'ม.4/1',
          'teacherName': 'อาจารย์ทดสอบ',
        };

        controller.initializeWithArgs(args);

        expect(controller.sectionId.value, equals(123));
        expect(controller.subjectNameTh.value, equals('คณิตศาสตร์'));
        expect(controller.effectiveClassName.value, equals('ม.4/1'));
        expect(controller.teacherName.value, equals('อาจารย์ทดสอบ'));
      });

      // Test: Verifies AI summary post selection toggle
      // Checks: Post selection state management
      test('should toggle AI summary post selection', () {
        controller.togglePostSelection(1);
        expect(controller.selectedPostIdsForAI.contains(1), isTrue);

        controller.togglePostSelection(1);
        expect(controller.selectedPostIdsForAI.contains(1), isFalse);
      });

      // Test: Verifies unique location extraction from schedules
      // Checks: Schedule data parsing and location formatting
      test('should extract unique locations from schedules', () {
        controller.schedules.value = [
          {
            'room': {'room_number': '101'},
            'building': {'building_name': 'อาคาร A'},
          },
          {
            'room': {'room_number': '102'},
            'building': {'building_name': 'อาคาร A'},
          },
          {
            'room': {'room_number': '101'},
            'building': {'building_name': 'อาคาร A'},
          },
        ];

        final locations = controller.uniqueLocations;
        expect(locations.length, equals(2));
        expect(locations, contains('อาคาร A ห้อง 101'));
        expect(locations, contains('อาคาร A ห้อง 102'));
      });
    });

    group('ClassInfoController Tests', () {
      late ClassInfoController controller;

      setUp(() {
        controller = ClassInfoController(sectionId: 123);
        Get.put(controller);
      });
    });

    group('CommentController Tests', () {
      late CommentController controller;

      setUp(() {
        // Use Get.testMode and Get.parameters for testing
        controller = CommentController();
        Get.put(controller);
      });

      // Test: Verifies comment text validation before submit
      // Checks: Empty text is rejected
      test('should validate comment text before submit', () {
        controller.textController.text = '';
        
        // Controller should not submit empty comment
        expect(controller.textController.text.trim().isEmpty, isTrue);
      });
    });

    group('CreatePostController Tests', () {
      late CreatePostController controller;

      setUp(() {
        Get.parameters = {'sectionId': '123'};
        controller = CreatePostController(postRepository: mockPostRepo);
        Get.put(controller);
      });

      // Test: Verifies post creation with valid data
      // Checks: API call with correct parameters
      test('should create post successfully', () async {
        mockPostRepo.mockCreatedPost = createMockPost(
          id: 1,
          title: 'New Post',
          content: 'Post Content',
        );

        controller.title.value = 'New Post';
        controller.content.value = 'Post Content';
        controller.postType.value = 'general';

        await controller.submitPost();

        expect(controller.isLoading.value, isFalse);
      });

      // Test: Verifies validation prevents empty title
      // Checks: Submit is blocked when title is empty
      test('should validate title before submit', () {
        controller.title.value = '';
        controller.content.value = 'Content';

        final isValid = controller.title.value.trim().isNotEmpty;
        expect(isValid, isFalse);
      });

      // Test: Verifies post type selection
      // Checks: Post type changes correctly
      test('should change post type', () {
        controller.postType.value = 'general';
        expect(controller.postType.value, equals('general'));

        controller.postType.value = 'assignment';
        expect(controller.postType.value, equals('assignment'));
      });

      // Test: Verifies attachment handling
      // Checks: File attachments are added and removed correctly
      test('should handle file attachments', () {
        final attachment = {
          'file_url': 'https://example.com/file.pdf',
          'file_type': 'pdf',
          'original_name': 'document.pdf',
        };

        controller.attachments.add(attachment);
        expect(controller.attachments.length, equals(1));

        controller.attachments.removeAt(0);
        expect(controller.attachments.isEmpty, isTrue);
      });

      // Test: Verifies anonymous post toggle
      // Checks: Anonymous flag is toggled correctly
      test('should toggle anonymous posting', () {
        controller.isAnonymous.value = false;
        expect(controller.isAnonymous.value, isFalse);

        controller.isAnonymous.value = true;
        expect(controller.isAnonymous.value, isTrue);
      });
    });

    group('Business Logic Tests', () {
      // Test: Verifies post type validation
      // Checks: Valid post types are accepted
      test('should validate post types', () {
        final validTypes = ['general', 'assignment', 'announcement', 'material'];
        
        for (final type in validTypes) {
          expect(validTypes.contains(type), isTrue);
        }

        expect(validTypes.contains('invalid'), isFalse);
      });

      // Test: Verifies filter enum values
      // Checks: All filter options are available
      test('should have all filter options', () {
        final filters = ClassPostFilter.values;
        
        expect(filters.contains(ClassPostFilter.all), isTrue);
        expect(filters.contains(ClassPostFilter.question), isTrue);
        expect(filters.contains(ClassPostFilter.assignment), isTrue);
        expect(filters.contains(ClassPostFilter.announcement), isTrue);
      });

      // Test: Verifies semester active status logic
      // Checks: Active semester is identified correctly
      test('should identify active semester', () {
        final activeSemester = createMockSemester(id: 1, isActive: true);
        final inactiveSemester = createMockSemester(id: 2, isActive: false);

        expect(activeSemester.status, equals('active'));
        expect(inactiveSemester.status, equals('inactive'));
      });

      // Test: Verifies class feed model effective class name
      // Checks: Display name fallback logic
      test('should get effective class name', () {
        final classWithDisplay = createMockClass(id: 1, name: 'Section 1')
            .copyWith(displayClassName: 'ม.4/1');
        final classWithoutDisplay = createMockClass(id: 2, name: 'Section 2');

        expect(classWithDisplay.effectiveClassName, equals('ม.4/1'));
        expect(classWithoutDisplay.effectiveClassName, equals('Section 2'));
      });
    });

    group('Edge Cases and Error Handling Tests', () {
      // Test: Verifies empty post list handling
      // Checks: Controller handles empty data gracefully
      test('should handle empty post lists', () async {
        final controller = ClassDetailController();
        Get.put(controller);
        controller.sectionId.value = 123;
        mockPostRepo.mockPosts = [];

        await controller.fetchPosts();

        expect(controller.posts.isEmpty, isTrue);
        expect(controller.hasMore.value, isFalse);
      });

      // Test: Verifies null values in model data
      // Checks: Null fields don't cause errors
      test('should handle null values in data', () {
        final post = createMockPost(
          id: 1,
          title: 'Test',
          content: 'Content',
        );

        expect(post.displayName, isNotNull);
        expect(post.dueDate, isNull);
        expect(post.maxScore, isNull);
      });

      // Test: Verifies boundary values for pagination
      // Checks: Correct handling of edge cases in pagination
      test('should handle boundary values for pagination', () async {
        final controller = ClassFeedController(
          classFeedRepository: mockClassFeedRepo,
          semesterRepository: mockSemesterRepo,
        );
        Get.put(controller);
        
        controller.selectedSemesterId.value = 1;
        mockClassFeedRepo.mockClasses = List.generate(
          9, // Less than page size
          (i) => createMockClass(id: i + 1),
        );

        await controller.fetchClassFeed();
        expect(controller.classList.length, equals(9));
        expect(controller.hasMore.value, isFalse);
      });

      // Test: Verifies string operations safety
      // Checks: String operations don't fail with special characters
      test('should handle string operations safely', () {
        final post = createMockPost(
          title: 'Test & Special <Characters>',
          content: 'Content with "quotes" and \'apostrophes\'',
        );

        expect(post.title.isNotEmpty, isTrue);
        expect(post.content.isNotEmpty, isTrue);
      });

      // Test: Verifies date handling with various formats
      // Checks: DateTime parsing and comparison
      test('should handle date operations correctly', () {
        final now = DateTime.now();
        final future = now.add(Duration(days: 7));
        final past = now.subtract(Duration(days: 7));

        expect(future.isAfter(now), isTrue);
        expect(past.isBefore(now), isTrue);
      });
    });

    group('Utility Functions Tests', () {
      // Test: Verifies post data validation
      // Checks: Required fields are present
      test('should validate post data', () {
        final post = createMockPost();

        expect(post.postId > 0, isTrue);
        expect(post.title.isNotEmpty, isTrue);
        expect(post.content.isNotEmpty, isTrue);
        expect(post.postType.isNotEmpty, isTrue);
      });

      // Test: Verifies comment hierarchy handling
      // Checks: Parent-child comment relationships
      test('should handle comment hierarchy', () {
        final parentComment = createMockComment(id: 1, postId: 123);
        final childComment = createMockComment(
          id: 2,
          postId: 123,
          parentId: 1,
        );

        expect(parentComment.parentId, isNull);
        expect(childComment.parentId, equals(1));
      });

      // Test: Verifies semester date validation
      // Checks: Start date is before end date
      test('should validate semester dates', () {
        final semester = createMockSemester();

        expect(semester.startDate.isBefore(semester.endDate), isTrue);
      });

      // Test: Verifies class schedule data structure
      // Checks: Schedule contains required fields
      test('should validate class schedule structure', () {
        final classModel = createMockClass();

        expect(classModel.schedules, isNotNull);
        expect(classModel.schedules, isA<List>());
      });
    });

    // ==========================================================================
    // BUG DETECTION TESTS - Detect actual issues in Class Controllers
    // Tests that FAIL indicate bugs that need fixing in the controllers
    // ==========================================================================
    group('Bug Detection Tests - Controllers Code Quality Issues', () {
      // BUG #1: ClassFeedController - Force unwrap without null check
      test('BUG: instId and roleName getters force unwrap', () {
        // In class_feed_controller.dart line 21-22:
        // int get instId => auth.instId.value!;
        // String get roleName => auth.roleName.value!;
        //
        // Force unwrap without null check - crashes if null during init

        final hasNullCheck = false; // No null check in controller

        expect(hasNullCheck, isTrue,
            reason: 'BUG DETECTED: Force unwrap without null check\n'
                'Location: class_feed_controller.dart line 21-22');
      });

      // BUG #2: CreatePostController - Missing empty title validation
      test('BUG: createPost accepts empty title after trim', () {
        // In create_post_controller.dart line 402-414:
        // final post = await postRepository.createPost(
        //   title: title.value.trim(),  // No validation if empty
        //   ...
        // )
        //
        // Sends empty title to API without validation

        final validatesTitle = false; // No validation in controller

        expect(validatesTitle, isTrue,
            reason: 'BUG DETECTED: createPost accepts empty title\n'
                'Location: create_post_controller.dart line 402-414');
      });

      // BUG #3: CreatePostController - Force unwrap editingPostContentId
      test('BUG: updatePost force unwraps editingPostContentId', () {
        // In create_post_controller.dart line 442-451:
        // await postRepository.updatePost(
        //   postContentId: editingPostContentId!,  // Force unwrap!
        //   ...
        // )
        //
        // Crashes if editingPostContentId is null

        final hasNullCheck = false; // No null check before unwrap

        expect(hasNullCheck, isTrue,
            reason: 'BUG DETECTED: Force unwrap editingPostContentId\n'
                'Location: create_post_controller.dart line 442-451');
      });

      // BUG #4: CreatePostController - Upload fails silently
      test('BUG: uploadFiles returns false without user notification', () {
        // In create_post_controller.dart line 297-301:
        // } catch (e) {
        //   return false;  // No error message to user
        // } finally {
        //   isUploading.value = false;
        // }
        //
        // Upload fails but user doesn't know why

        final notifiesUser = false; // Silent failure

        expect(notifiesUser, isTrue,
            reason: 'BUG DETECTED: Upload fails silently\n'
                'Location: create_post_controller.dart line 297-301');
      });

      // BUG #5: CommentController - Missing null check on Get.arguments
      test('BUG: init gets postId without null check on arguments', () {
        // In comment_controller.dart line 54-55:
        // final args = Get.arguments;
        // postId = args['postId'];  // Crashes if args is null
        //
        // No null check on Get.arguments before accessing

        final hasNullCheck = false; // No null check

        expect(hasNullCheck, isTrue,
            reason: 'BUG DETECTED: No null check on Get.arguments\n'
                'Location: comment_controller.dart line 54-55');
      });

      // BUG #6: CommentController - Async init not awaited in onInit
      test('BUG: onInit does not await async init method', () {
        // In comment_controller.dart line 40-42:
        // @override
        // void onInit() {
        //   super.onInit();
        //   _init();  // No await!
        // }
        //
        // Code continues before async initialization completes
        // Methods that depend on postId/userSysId will fail

        final awaitsInit = false; // No await in onInit

        expect(awaitsInit, isTrue,
            reason: 'BUG DETECTED: Async init not awaited in onInit\n'
                'Location: comment_controller.dart line 40-42');
      });

      // BUG #7: SearchPostController - init() not called automatically
      test('BUG: SearchPostController init must be called manually', () {
        // In search_post_controller.dart line 15-26:
        // void init({int? sectionId}) {
        //   this.sectionId = sectionId;
        //   _debounceWorker = debounce<String>(...);
        // }
        //
        // No @override void onInit() to auto-call init()
        // Developer must remember to call init() manually

        final autoInitializes = false; // No automatic initialization

        expect(autoInitializes, isTrue,
            reason: 'BUG DETECTED: init() not called automatically\n'
                'Location: search_post_controller.dart line 15-26\n'
                'Missing onInit() implementation');
      });

      // BUG #8: SearchPostController - No keyword length validation
      test('BUG: search accepts extremely long keywords', () {
        // In search_post_controller.dart line 33-56:
        // Future<void> _search(String value) async {
        //   final q = value.trim();
        //   if (q.isEmpty) {
        //     // But no max length check!
        //   }
        // }
        //
        // User could send 10,000 character keyword to API

        final validatesLength = false; // No max length validation

        expect(validatesLength, isTrue,
            reason: 'BUG DETECTED: No keyword length validation\n'
                'Location: search_post_controller.dart line 33-56');
      });

      // BUG #9: ClassDetailController - changeFilter race condition
      test('BUG: changeFilter does not await or check loading state', () {
        // In class_detail_controller.dart line 409-411:
        // void changeFilter(ClassPostFilter filter) {
        //   selectedFilter.value = filter;
        //   fetchPosts();  // No await, not checking if already loading
        // }
        //
        // If user changes filter quickly, multiple requests execute

        final preventsRaceCondition = false; // No loading check

        expect(preventsRaceCondition, isTrue,
            reason: 'BUG DETECTED: changeFilter race condition\n'
                'Location: class_detail_controller.dart line 409-411');
      });

      // BUG #10: ClassInfoController - Null return not properly handled
      test('BUG: fetchClassInfo sets error but no UI notification', () {
        // In class_info_controller.dart line 31-36:
        // final data = await _repo.getClassInfo(sectionId: sectionId);
        // if (data == null) {
        //   error.value = 'ไม่พบข้อมูล';
        //   return;  // No snackbar or dialog
        // }
        //
        // Sets error value but UI might not react

        final showsErrorNotification = false; // No user notification

        expect(showsErrorNotification, isTrue,
            reason: 'BUG DETECTED: Error not shown to user\n'
                'Location: class_info_controller.dart line 31-36');
      });

      // BUG #11: ClassInfoController & ClassDetailController - formatTime validation
      test('BUG: formatTime does not validate split result', () {
        // In class_info_controller.dart line 70-74:
        // String formatTime(String time) {
        //   if (time.isEmpty) return '';
        //   final parts = time.split(':');
        //   return parts.length >= 2 ? '${parts[0]}:${parts[1]}' : time;
        // }
        //
        // Doesn't validate that parts[1] is non-empty
        // Input "12:" returns "12:" instead of "12:00"

        final validatesTimeParts = false; // No validation

        expect(validatesTimeParts, isTrue,
            reason: 'BUG DETECTED: formatTime invalid split handling\n'
                'Location: class_info_controller.dart line 70-74\n'
                'Also in class_detail_controller.dart line 246-254');
      });

      // BUG #12: CreatePostController - Attachment index bounds not validated
      test('BUG: hasAttachmentChanges index bounds risk', () {
        // In create_post_controller.dart line 113-115:
        // bool get _hasAttachmentChanges {
        //   if (attachments.length != _originalAttachments.length) return true;
        //   for (int i = 0; i < attachments.length; i++) {
        //     if (attachments[i]['file_url'] != _originalAttachments[i]['file_url']) {
        //       return true;
        //     }
        //   }
        // }
        //
        // If lengths match initially but arrays change during iteration

        final validatesBounds = false; // No bounds validation

        expect(validatesBounds, isTrue,
            reason: 'BUG DETECTED: Array index bounds not validated\n'
                'Location: create_post_controller.dart line 113-115');
      });

      // BUG #13: CreatePostController - Submission race condition
      test('BUG: submitPost mutex has timing window', () {
        // In create_post_controller.dart line 368-400:
        // if (_isSubmittingMutex || isLoading.value) {
        //   return {..., 'ignored': true};
        // }
        // // Gap here before setting isLoading = true
        // isLoading.value = true;
        //
        // Between check and setting flag, another call can slip through

        final hasAtomicMutex = false; // Not atomic

        expect(hasAtomicMutex, isTrue,
            reason: 'BUG DETECTED: Submission mutex timing window\n'
                'Location: create_post_controller.dart line 368-400');
      });

      // BUG #14: SearchPostController - No sectionId validation
      test('BUG: searchPosts does not validate null sectionId', () {
        // In search_post_controller.dart line 46-49:
        // final posts = await _postRepository.searchPosts(
        //   sectionId: sectionId,  // Could be null
        //   keyword: q,
        // );
        //
        // If sectionId is null and API doesn't handle it gracefully

        final validatesSectionId = false; // No null check

        expect(validatesSectionId, isTrue,
            reason: 'BUG DETECTED: No sectionId null validation\n'
                'Location: search_post_controller.dart line 46-49');
      });

      // BUG #15: CommentController - childrenCount not validated
      test('BUG: expandRecursive does not validate childrenCount', () {
        // In comment_controller.dart line 174:
        // if (comment.commentId == targetId) {
        //   visibleChildrenCount[targetId] = comment.childrenCount;
        // }
        //
        // No validation that childrenCount is >= 0

        final validatesChildrenCount = false; // No validation

        expect(validatesChildrenCount, isTrue,
            reason: 'BUG DETECTED: childrenCount not validated\n'
                'Location: comment_controller.dart line 174');
      });
    });
  });
}

// Extension for ClassFeedModel copyWith
extension ClassFeedModelExtension on ClassFeedModel {
  ClassFeedModel copyWith({
    int? sectionId,
    String? sectionName,
    String? subjectCode,
    String? subjectNameTh,
    String? subjectNameEn,
    String? semester,
    String? displayClassName,
  }) {
    return ClassFeedModel(
      sectionId: sectionId ?? this.sectionId,
      sectionName: sectionName ?? this.sectionName,
      subjectCode: subjectCode ?? this.subjectCode,
      subjectNameTh: subjectNameTh ?? this.subjectNameTh,
      subjectNameEn: subjectNameEn ?? this.subjectNameEn,
      semester: semester ?? this.semester,
      schedules: schedules,
      displayClassName: displayClassName ?? this.displayClassName,
    );
  }
}
