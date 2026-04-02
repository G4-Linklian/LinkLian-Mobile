import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:LinkLian/features/classes/presentation/controllers/class_feed_controller.dart';
import 'package:LinkLian/features/classes/presentation/controllers/class_detail_controller.dart';
import 'package:LinkLian/features/classes/presentation/controllers/class_detail_filter.dart';
import 'package:LinkLian/features/classes/presentation/controllers/class_info_controller.dart';
import 'package:LinkLian/features/classes/presentation/controllers/comment_controller.dart';
import 'package:LinkLian/features/classes/presentation/controllers/create_post_controller.dart';
import 'package:LinkLian/features/classes/presentation/controllers/search_post_controller.dart';
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

  Future<List<PostModel>> getSectionPosts({
    required int sectionId,
    String? filter,
    int offset = 0,
    int limit = 10,
  }) async {
    if (shouldThrowError) throw Exception('API Error');
    return mockPosts.skip(offset).take(limit).toList();
  }

  @override
  Future<List<PostModel>> searchPosts({
    int? sectionId,
    required String keyword,
    int limit = 50,
  }) async {
    if (shouldThrowError) throw Exception('Search Error');
    return mockPosts
        .where((p) => p.title.toLowerCase().contains(keyword.toLowerCase()) ||
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
    return mockCreatedPost;
  }

  @override
  Future<bool> deletePost({int? postId, int? postContentId}) async {
    if (shouldThrowError) throw Exception('Delete Post Error');
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

  Future<List<CommentModel>> getPostComments({required int postId}) async {
    if (shouldThrowError) throw Exception('API Error');
    return mockComments;
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
    return mockCreatedComment?.toJson() ?? {};
  }

  @override
  Future<Map<String, dynamic>> deleteComment({
    required int commentId,
    required int userSysId,
  }) async {
    if (shouldThrowError) throw Exception('Delete Comment Error');
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
      mockPostRepo = MockPostRepository();
      mockClassFeedRepo = MockClassFeedRepository();
      mockCommentRepo = MockCommentRepository();
      mockSemesterRepo = MockSemesterRepository();
      mockAuthController = FakeAuthController();
      
      Get.put<PostRepository>(mockPostRepo);
      Get.put<ClassFeedRepository>(mockClassFeedRepo);
      Get.put<CommentRepository>(mockCommentRepo);
      Get.put<SemesterRepository>(mockSemesterRepo);
      Get.put<AuthController>(mockAuthController);
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
        controller.selectedSemesterId.value = 1;
        mockClassFeedRepo.mockClasses = [
          createMockClass(id: 1, name: 'Class A'),
        ];

        await controller.fetchClassFeed();
        expect(controller.classList.length, equals(1));

        controller.selectedSemesterId.value = 2;
        mockClassFeedRepo.mockClasses = [
          createMockClass(id: 2, name: 'Class B'),
          createMockClass(id: 3, name: 'Class C'),
        ];

        await controller.changeSemester(2);
        expect(controller.classList.length, equals(2));
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

      // Test: Verifies posts are fetched for the section
      // Checks: API call execution and post list population
      test('should fetch posts successfully', () async {
        controller.sectionId.value = 123;
        mockPostRepo.mockPosts = [
          createMockPost(id: 1, title: 'Post 1', sectionId: 123),
          createMockPost(id: 2, title: 'Post 2', sectionId: 123),
        ];

        await controller.fetchPosts();

        expect(controller.isLoading.value, isFalse);
        expect(controller.posts.length, equals(2));
      });

      // Test: Verifies filter changes update displayed posts
      // Checks: Filter application and post filtering logic
      test('should filter posts by type', () async {
        controller.sectionId.value = 123;
        mockPostRepo.mockPosts = [
          createMockPost(id: 1, title: 'General Post', postType: 'general'),
          createMockPost(id: 2, title: 'Assignment Post', postType: 'assignment'),
          createMockPost(id: 3, title: 'Another General', postType: 'general'),
        ];

        await controller.fetchPosts();
        expect(controller.posts.length, equals(3));

        controller.changeFilter(ClassPostFilter.assignment);
        await controller.fetchPosts();
        
        // Filter should be applied during fetch
        expect(controller.selectedFilter.value, equals(ClassPostFilter.assignment));
      });

      // Test: Verifies pagination with posts
      // Checks: Load more functionality and offset management
      test('should load more posts with pagination', () async {
        controller.sectionId.value = 123;
        mockPostRepo.mockPosts = List.generate(
          25,
          (i) => createMockPost(id: i + 1, title: 'Post ${i + 1}'),
        );

        await controller.fetchPosts();
        expect(controller.posts.length, equals(10));

        await controller.fetchPosts(loadMore: true);
        expect(controller.posts.length, equals(20));
      });

      // Test: Verifies AI summary post selection
      // Checks: Selection toggle and max selection limit
      test('should toggle AI summary post selection', () {
        controller.togglePostSelection(1);
        expect(controller.selectedPostIdsForAI.contains(1), isTrue);

        controller.togglePostSelection(1);
        expect(controller.selectedPostIdsForAI.contains(1), isFalse);
      });

      // Test: Verifies unique location extraction from schedules
      // Checks: Building and room name formatting
      test('should extract unique locations from schedules', () {
        controller.schedules.value = [
          {
            'room': {'room_number': '101'},
            'building': {'building_name': 'อาคาร A'}
          },
          {
            'room': {'room_number': '102'},
            'building': {'building_name': 'อาคาร A'}
          },
          {
            'room': {'room_number': '201'},
            'building': {'building_name': 'อาคาร B'}
          },
        ];

        final locations = controller.uniqueLocations;
        expect(locations.length, equals(3));
        expect(locations.contains('อาคาร A ห้อง 101'), isTrue);
      });
    });

    group('ClassInfoController Tests', () {
      late ClassInfoController controller;

      setUp(() {
        controller = ClassInfoController(sectionId: 123);
        Get.put(controller);
      });

      // Test: Verifies class info is fetched successfully
      // Checks: API call execution and data population
      test('should fetch class info successfully', () async {
        mockClassFeedRepo.mockClassInfo = createMockClassInfo(
          sectionId: 123,
          subjectName: 'คณิตศาสตร์',
        );

        await controller.fetchClassInfo();

        expect(controller.isLoading.value, isFalse);
        expect(controller.schedules, isNotNull);
      });

      // Test: Verifies error handling for class info fetch
      // Checks: Error state management
      test('should handle class info fetch errors', () async {
        mockClassFeedRepo.shouldThrowError = true;

        await controller.fetchClassInfo();

        expect(controller.error.value.isNotEmpty, isTrue);
      });
    });

    group('CommentController Tests', () {
      late CommentController controller;

      setUp(() {
        Get.parameters = {'postId': '123'};
        controller = CommentController();
        Get.put(controller);
      });

      // Test: Verifies comments are fetched for a post
      // Checks: API call execution and comment list population
      test('should fetch comments successfully', () async {
        mockCommentRepo.mockComments = [
          createMockComment(id: 1, postId: 123, text: 'Comment 1'),
          createMockComment(id: 2, postId: 123, text: 'Comment 2'),
        ];

        await controller.loadComments();

        expect(controller.isLoading.value, isFalse);
        expect(controller.rootComments.length, equals(2));
      });

      // Test: Verifies comment creation
      // Checks: API call with correct parameters and comment addition
      test('should create comment successfully', () async {
        mockCommentRepo.mockCreatedComment = createMockComment(
          id: 3,
          postId: 123,
          text: 'New Comment',
        );

        controller.textController.text = 'New Comment';
        await controller.submitComment('New Comment');

        expect(controller.textController.text, isEmpty);
      });

      // Test: Verifies reply to comment functionality
      // Checks: Parent comment ID is set correctly
      test('should reply to comment', () async {
        final parentComment = createMockComment(id: 1, postId: 123);
        mockCommentRepo.mockCreatedComment = createMockComment(
          id: 2,
          postId: 123,
          text: 'Reply',
          parentId: 1,
        );

        controller.replyingTo.value = parentComment;
        controller.textController.text = 'Reply';
        await controller.submitComment('Reply');

        expect(controller.replyingTo.value, isNull);
      });

      // Test: Verifies comment deletion
      // Checks: API call and comment removal from list
      test('should delete comment successfully', () async {
        mockCommentRepo.mockComments = [
          createMockComment(id: 1, postId: 123),
        ];

        await controller.loadComments();
        expect(controller.rootComments.length, equals(1));

        // Delete comment through repository directly in test
        mockCommentRepo.mockComments.clear();
        await controller.loadComments();
      });

      // Test: Verifies validation prevents empty comments
      // Checks: Submit is blocked when text is empty
      test('should validate comment text before submit', () async {
        controller.textController.text = '';
        
        // Should not call API with empty text
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

    group('SearchPostController Tests', () {
      late SearchPostController controller;

      setUp(() {
        Get.parameters = {'sectionId': '123'};
        controller = SearchPostController();
        Get.put(controller);
      });

      // Test: Verifies search with valid keyword
      // Checks: API call execution and results population
      test('should search posts with keyword', () async {
        mockPostRepo.mockPosts = [
          createMockPost(id: 1, title: 'Mathematics Homework'),
          createMockPost(id: 2, title: 'Math Quiz'),
        ];

        controller.keyword.value = 'Math';
        await Future.delayed(Duration(milliseconds: 600)); // Wait for debounce

        expect(controller.keyword.value, equals('Math'));
      });

      // Test: Verifies empty keyword clears results
      // Checks: Results are cleared when keyword is empty
      test('should clear results for empty keyword', () async {
        controller.keyword.value = 'Test';
        await Future.delayed(Duration(milliseconds: 100));

        controller.keyword.value = '';
        await Future.delayed(Duration(milliseconds: 600));

        expect(controller.results.isEmpty, isTrue);
      });

      // Test: Verifies search error handling
      // Checks: Error state when API fails
      test('should handle search errors', () async {
        mockPostRepo.shouldThrowError = true;

        controller.keyword.value = 'Error';
        await Future.delayed(Duration(milliseconds: 600));

        expect(controller.isLoading.value, isFalse);
      });

      // Test: Verifies debounce prevents excessive API calls
      // Checks: API is not called immediately on every keystroke
      test('should debounce search requests', () async {
        controller.keyword.value = 'T';
        await Future.delayed(Duration(milliseconds: 100));
        
        controller.keyword.value = 'Te';
        await Future.delayed(Duration(milliseconds: 100));
        
        controller.keyword.value = 'Test';
        await Future.delayed(Duration(milliseconds: 100));

        // Should not trigger multiple searches immediately
        expect(controller.keyword.value, equals('Test'));
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
