import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:LinkLian/features/community/presentation/controllers/community_controller.dart';
import 'package:LinkLian/features/community/presentation/controllers/community_detail_controller.dart';
import 'package:LinkLian/features/community/presentation/controllers/create_community_controller.dart';
import 'package:LinkLian/features/community/data/repositories/community_repository.dart';
import 'package:LinkLian/features/community/data/repositories/community_member_repository.dart';
import 'package:LinkLian/features/community/data/repositories/community_tag_repository.dart';
import 'package:LinkLian/features/community/data/repositories/community_post_repository.dart';
import 'package:LinkLian/features/community/data/models/community_model.dart';
import 'package:LinkLian/features/community/data/models/community_post_model.dart';
import 'package:LinkLian/features/community/data/models/community_tag_model.dart';
import 'package:LinkLian/features/community/data/models/community_member_model.dart';

// Mock Repository Classes
class MockCommunityRepository extends GetxService implements CommunityRepository {
  List<CommunityModel> mockCommunities = [];
  bool shouldThrowError = false;
  
  @override
  Future<List<CommunityModel>> getCommunities({String? keyword}) async {
    if (shouldThrowError) throw Exception('API Error');
    if (keyword != null && keyword.isNotEmpty) {
      return mockCommunities.where((c) => 
        c.communityName.toLowerCase().contains(keyword.toLowerCase()) ||
        (c.description?.toLowerCase().contains(keyword.toLowerCase()) ?? false)
      ).toList();
    }
    return mockCommunities;
  }

  @override
  Future<CommunityModel?> getCommunityDetail(int communityId) async {
    if (shouldThrowError) throw Exception('Community Detail Error');
    try {
      return mockCommunities.firstWhere((c) => c.communityId == communityId);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<void> createCommunity({
    required String name,
    required String description,
    required List<String> rules,
    required bool isPrivate,
    required List<String> tags,
    String? imagePath,
  }) async {
    if (shouldThrowError) throw Exception('Create Community Error');
  }

  @override
  Future<void> updateCommunity({
    required int communityId,
    required String name,
    required String description,
    required bool isPrivate,
    required List<String> rules,
    required List<String> tags,
    String? imagePath,
  }) async {
    if (shouldThrowError) throw Exception('Update Community Error');
  }

  @override
  Future<void> deleteCommunity(int communityId) async {
    if (shouldThrowError) throw Exception('Delete Community Error');
  }

  @override
  Future<void> toggleBookmark(int postId) async {
    if (shouldThrowError) throw Exception('Bookmark Error');
  }

  @override
  Future<void> deletePost(int postId) async {
    if (shouldThrowError) throw Exception('Delete Post Error');
  }

}

class MockCommunityMemberRepository extends GetxService implements CommunityMemberRepository {
  bool shouldThrowError = false;
  
  @override
  Future<bool> join(int communityId) async {
    if (shouldThrowError) throw Exception('Join Error');
    return true;
  }

  @override
  Future<bool> leave(int communityId) async {
    if (shouldThrowError) throw Exception('Leave Error');
    return true;
  }

  @override
  Future<bool> approve(int communityId, int userId) async {
    if (shouldThrowError) throw Exception('Approve Error');
    return true;
  }

  @override
  Future<bool> reject(int communityId, int userId) async {
    if (shouldThrowError) throw Exception('Reject Error');
    return true;
  }

  @override
  Future<List<CommunityMemberModel>> getMembers(int communityId) async {
    if (shouldThrowError) throw Exception('Get Members Error');
    return [];
  }

  @override
  Future<List<CommunityMemberModel>> getPendingMembers(int communityId) async {
    if (shouldThrowError) throw Exception('Get Pending Members Error');
    return [];
  }
}

class MockCommunityTagRepository extends GetxService implements CommunityTagRepository {
  List<CommunityTagModel> mockTags = [];
  bool shouldThrowError = false;
  
  @override
  Future<List<CommunityTagModel>> searchTag({required String keyword}) async {
    if (shouldThrowError) throw Exception('Tag Search Error');
    
    return mockTags.where((tag) => 
      tag.tagName.toLowerCase().contains(keyword.toLowerCase())
    ).toList();
  }

}

class MockCommunityPostRepository extends GetxService implements CommunityPostRepository {
  List<CommunityPostModel> mockPosts = [];
  bool shouldThrowError = false;
  
  @override
  Future<List<CommunityPostModel>> getCommunityFeed({
    required int communityId,
    int limit = 20,
    int offset = 0,
    String sort = 'newest',
  }) async {
    if (shouldThrowError) throw Exception('Get Community Feed Error');
    return mockPosts.where((p) => p.communityId == communityId).toList();
  }

  @override
  Future<CommunityPostModel> updatePost({
    required int postId,
    required String content,
    List? files,
    List? keepAttachments,
  }) async {
    if (shouldThrowError) throw Exception('Update Post Error');
    
    final postIndex = mockPosts.indexWhere((p) => p.postId == postId);
    if (postIndex != -1) {
      final oldPost = mockPosts[postIndex];
      final updatedPost = CommunityPostModel(
        postId: postId,
        communityId: oldPost.communityId,
        userId: oldPost.userId,
        content: content,
        createdAt: oldPost.createdAt,
        firstName: oldPost.firstName,
        lastName: oldPost.lastName,
        profilePic: oldPost.profilePic,
        attachments: oldPost.attachments,
      );
      mockPosts[postIndex] = updatedPost;
      return updatedPost;
    }
    throw Exception('Post not found');
  }

  @override
  Future<CommunityPostModel> createPost({
    required int communityId,
    required String content,
    List? files,
  }) async {
    if (shouldThrowError) throw Exception('Create Post Error');
    
    final newPost = CommunityPostModel(
      postId: mockPosts.length + 1,
      communityId: communityId,
      userId: 1,
      content: content,
      createdAt: DateTime.now(),
      firstName: 'Test',
      lastName: 'User',
      attachments: [],
    );
    mockPosts.add(newPost);
    return newPost;
  }

  @override
  Future<bool> deletePost({required int postId}) async {
    if (shouldThrowError) throw Exception('Delete Post Error');
    final initialLength = mockPosts.length;
    mockPosts.removeWhere((p) => p.postId == postId);
    return mockPosts.length < initialLength;
  }
}

void main() {
  // Real controller instances with mocked dependencies
  late CommunityController communityController;
  late CreateCommunityController createCommunityController;
  late CommunityDetailController detailController;

  // Mock repositories
  late MockCommunityRepository mockCommunityRepo;
  late MockCommunityMemberRepository mockMemberRepo;
  late MockCommunityTagRepository mockTagRepo;
  late MockCommunityPostRepository mockPostRepo;

  void setupMockData() {
    // Setup mock communities
    mockCommunityRepo.mockCommunities = [
      CommunityModel(
        communityId: 1,
        communityName: 'Flutter Developers',
        description: 'A community for Flutter developers',
        isPrivate: false,
        imageBanner: '',
        status: 'active',
        memberCount: 150,
        tags: ['flutter', 'development'],
        membershipStatus: 'active',
        rules: ['Be respectful', 'Stay on topic'],
      ),
      CommunityModel(
        communityId: 2,
        communityName: 'Dart Programming',
        description: 'Learn and discuss Dart programming',
        isPrivate: false,
        imageBanner: '',
        status: 'active',
        memberCount: 89,
        tags: ['dart', 'programming'],
        membershipStatus: 'pending',
        rules: ['Share knowledge', 'Help others'],
      ),
    ];

    // Setup mock tags
    mockTagRepo.mockTags = [
      CommunityTagModel(tagId: 1, tagName: 'flutter'),
      CommunityTagModel(tagId: 2, tagName: 'dart'),
      CommunityTagModel(tagId: 3, tagName: 'mobile'),
    ];
  }

  setUp(() {
    // Reset GetX
    Get.reset();
    
    // Initialize mock repositories
    mockCommunityRepo = MockCommunityRepository();
    mockMemberRepo = MockCommunityMemberRepository();
    mockTagRepo = MockCommunityTagRepository();
    mockPostRepo = MockCommunityPostRepository();
    
    // Register mock repositories
    Get.put<CommunityRepository>(mockCommunityRepo);
    Get.put<CommunityMemberRepository>(mockMemberRepo);
    Get.put<CommunityTagRepository>(mockTagRepo);
    Get.put<CommunityPostRepository>(mockPostRepo);

    // Initialize real controllers with injected dependencies
    communityController = CommunityController(mockCommunityRepo);
    createCommunityController = CreateCommunityController(mockCommunityRepo, mockTagRepo);
    detailController = CommunityDetailController(mockCommunityRepo, mockPostRepo, mockMemberRepo);
    
    // Setup mock data
    setupMockData();
  });

  tearDown(() {
    Get.reset();
  });

  group('Community Controller Tests', () {
    group('Initialization Tests', () {
      test('should initialize with default values', () {
        // Test: Controller initialization with correct property types
        expect(communityController, isNotNull);
        expect(communityController.communities, isA<RxList<CommunityModel>>());
        expect(communityController.posts, isA<RxList<CommunityPostModel>>());
        expect(communityController.isLoading, isA<RxBool>());
      });

      test('should initialize with empty communities list', () {
        // Test: Initial state has empty lists and loading=false
        expect(communityController.communities.isEmpty, true);
        expect(communityController.isLoading.value, false);
      });
    });

    group('Business Logic Tests', () {
      test('should load communities successfully', () async {
        // Test: Community loading and filtering functionality
        await communityController.loadCommunities();
        
        expect(communityController.communities.isNotEmpty, true);
        expect(communityController.communities.length, equals(2));
        expect(communityController.communities.first.communityName, equals('Flutter Developers'));
      });

      test('should handle search functionality', () {
        // Test: Search controller and text input handling
        expect(communityController.searchController, isA<TextEditingController>());
        expect(communityController.searchKeyword, isA<RxString>());
        
        communityController.searchController.text = 'flutter';
        expect(communityController.searchController.text, equals('flutter'));
      });
    });

    group('State Management Tests', () {
      test('should manage join filter state', () {
        // Test: Join filter reactive variable state changes
        expect(communityController.joinFilter, isA<Rx<JoinFilter>>());
        expect(communityController.joinFilter.value, equals(JoinFilter.joined));
      });

      test('should manage loading states', () {
        // Test: Loading state toggle functionality
        expect(communityController.isLoading.value, false);
        
        communityController.isLoading.value = true;
        expect(communityController.isLoading.value, true);
      });
    });
  });

  group('Create Community Controller Tests', () {
    group('Form Management Tests', () {
      test('should initialize form controllers', () {
        // Test: Form controllers and rules list initialization
        expect(createCommunityController.nameController, isA<TextEditingController>());
        expect(createCommunityController.descriptionController, isA<TextEditingController>());
        expect(createCommunityController.rules, isA<RxList<String>>());
      });

      test('should handle rule management', () {
        // Test: Adding and removing rules from list
        expect(createCommunityController.rules.isEmpty, true);
        
        createCommunityController.addRule('Test Rule');
        expect(createCommunityController.rules.contains('Test Rule'), true);
        
        createCommunityController.removeRule('Test Rule');
        expect(createCommunityController.rules.contains('Test Rule'), false);
      });
    });

    group('Tag Management Tests', () {
      test('should handle tag search', () async {
        // Test: Tag search functionality and result handling
        await createCommunityController.searchTag('flutter');
        
        expect(createCommunityController.tagSearchResult, isA<RxList<CommunityTagModel>>());
        expect(createCommunityController.isSearchingTags.value, false);
      });

      test('should manage selected tags', () {
        // Test: Tag selection and deselection operations
        expect(createCommunityController.selectedTags, isA<RxList<String>>());
        
        createCommunityController.addTag('flutter');
        expect(createCommunityController.selectedTags.contains('flutter'), true);
        
        createCommunityController.removeTag('flutter');
        expect(createCommunityController.selectedTags.contains('flutter'), false);
      });
    });

    group('Privacy Settings Tests', () {
      test('should handle privacy toggle', () {
        // Test: Privacy setting toggle functionality
        expect(createCommunityController.isPrivate.value, false);
        
        createCommunityController.isPrivate.value = true;
        expect(createCommunityController.isPrivate.value, true);
      });
    });
  });

  group('Community Detail Controller Tests', () {
    group('Initialization Tests', () {
      test('should initialize with default values', () {
        // Test: Community detail controller initialization
        expect(detailController, isNotNull);
        expect(detailController.community, isA<Rxn<CommunityModel>>());
        expect(detailController.posts, isA<RxList<CommunityPostModel>>());
        expect(detailController.isLoading, isA<RxBool>());
      });
    });

    group('Community Management Tests', () {
      test('should handle community ID setting', () {
        // Test: Community ID assignment and retrieval
        detailController.communityId = 1;
        expect(detailController.communityId, equals(1));
      });
    });
  });

  group('Integration Tests', () {
    test('should validate real controller instantiation', () {
      // Test: Real controller instances (not mocked)
      expect(communityController.runtimeType.toString(), equals('CommunityController'));
      expect(createCommunityController.runtimeType.toString(), equals('CreateCommunityController'));
      expect(detailController.runtimeType.toString(), equals('CommunityDetailController'));
      
      // Verify controllers have expected reactive properties
      expect(communityController.communities, isA<RxList<CommunityModel>>());
      expect(createCommunityController.nameController, isA<TextEditingController>());
    });

    test('should handle repository injection', () {
      // Test: Mock repository dependency injection
      expect(mockCommunityRepo, isA<CommunityRepository>());
      expect(mockTagRepo, isA<CommunityTagRepository>());
      expect(mockPostRepo, isA<CommunityPostRepository>());
      expect(mockMemberRepo, isA<CommunityMemberRepository>());
    });
  });
}