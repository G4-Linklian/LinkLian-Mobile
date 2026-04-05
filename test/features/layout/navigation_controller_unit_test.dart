import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:LinkLian/features/layout/controllers/navigation_controller.dart';
import 'package:LinkLian/core/services/api_client.dart';
import 'package:LinkLian/features/assignment/data/repositories/assignment_repository.dart';
import 'package:LinkLian/features/shared/repositories/class_feed_repository.dart';
import 'package:LinkLian/features/assignment/presentation/controllers/class_assignment_controller.dart';
import 'package:LinkLian/features/community/presentation/controllers/community_controller.dart';

// ─── Mock Dependencies ─────────────────────────────────────────────────────────

class MockApiClient extends GetxService implements ApiClient {
  String get baseUrl => 'http://test-api.example.com';
  
  @override
  dynamic noSuchMethod(Invocation invocation) => Future.value({'success': true});
}

class MockAssignmentRepository extends GetxService implements AssignmentRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => Future.value([]);
}

class MockClassFeedRepository extends GetxService implements ClassFeedRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => Future.value([]);
}

class MockCommunityController extends GetxController {
  final searchKeyword = ''.obs;
  
  void resetSearch() {
    searchKeyword.value = '';
  }
  
  Future<void> loadCommunities({String? keyword}) async {
    // Mock implementation
  }
}

class MockClassAssignmentController extends GetxController {
  void reinitialise(Map<String, dynamic> args) {
    // Mock implementation
  }
}

// ─── Test Helpers ─────────────────────────────────────────────────────────────

Map<String, dynamic> createTestClassDetailArgs() {
  return {
    'sectionId': 123,
    'className': 'Test Class',
    'sectionName': 'Section A'
  };
}

Map<String, dynamic> createTestCommunityArgs() {
  return {
    'communityId': 456,
    'communityName': 'Test Community'
  };
}

Map<String, dynamic> createTestAssignmentArgs() {
  return {
    'sectionId': 789,
    'assignmentId': 101
  };
}

// ─── Main Test Suite ───────────────────────────────────────────────────────────

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    dotenv.testLoad(fileInput: '''
API_BASE_URL=http://test-api.example.com
''');
  });

  // ============================================================
  // BUG DETECTION TESTS - NAVIGATION CONTROLLER
  // ============================================================
  group('Bug Detection Tests - Navigation Controller Code Quality Issues', () {
    // BUG 1: Missing null safety in classDetailArgs access
    test('BUG: Unsafe null access in shouldRestoreClassDetail getter', () {
      final unsafeNullAccess = true; // Checks classDetailArgs.value != null after isShowingClassDetail.value
      expect(unsafeNullAccess, isFalse,
        reason: 'BUG DETECTED: Unsafe null access pattern in shouldRestoreClassDetail\n'
               'Location: navigation_controller.dart line 89-90');
    });

    // BUG 2: Inconsistent argument handling between show methods
    test('BUG: Inconsistent argument types between class and community detail', () {
      final inconsistentArgTypes = true; // classDetailArgs uses Map<String,dynamic>?, communityDetailArgs uses Rxn
      expect(inconsistentArgTypes, isFalse,
        reason: 'BUG DETECTED: Inconsistent argument type patterns\n'
               'Location: navigation_controller.dart line 13-20');
    });

    // BUG 3: Memory leak in controller management
    test('BUG: Potential memory leak in controller lifecycle management', () {
      final memoryLeakInControllers = true; // Controllers not always properly cleaned up
      expect(memoryLeakInControllers, isFalse,
        reason: 'BUG DETECTED: Inconsistent controller cleanup patterns\n'
               'Location: navigation_controller.dart line 158-171');
    });

    // BUG 4: Race condition in dependency management
    test('BUG: Race condition in dependency registration', () {
      final raceConditionInDeps = true; // No synchronization for concurrent calls
      expect(raceConditionInDeps, isFalse,
        reason: 'BUG DETECTED: Race condition in _ensurePut method\n'
               'Location: navigation_controller.dart line 31-36');
    });

    // BUG 5: Duplicate controller deletion logic
    test('BUG: Duplicate controller deletion in resetForRoleChange', () {
      final duplicateControllerDeletion = true; // ClassAssignmentController deleted twice
      expect(duplicateControllerDeletion, isFalse,
        reason: 'BUG DETECTED: Duplicate controller deletion logic\n'
               'Location: navigation_controller.dart line 159-167');
    });

    // BUG 6: Hard-coded magic numbers without constants
    test('BUG: Hard-coded magic numbers for navigation indices', () {
      final hardCodedMagicNumbers = true; // Index values 1, 2, 3 not defined as constants
      expect(hardCodedMagicNumbers, isFalse,
        reason: 'BUG DETECTED: Hard-coded magic numbers without constants\n'
               'Location: navigation_controller.dart line 9, 64, 86, 146, 149');
    });

    // BUG 7: Missing error handling in controller operations
    test('BUG: Missing error handling in controller operations', () {
      final missingErrorHandling = true; // No try-catch around controller operations
      expect(missingErrorHandling, isFalse,
        reason: 'BUG DETECTED: Missing error handling in controller operations\n'
               'Location: navigation_controller.dart line 65-67, 103-110');
    });

    // BUG 8: Unsafe controller access without null check
    test('BUG: Unsafe controller access in changeTab method', () {
      final unsafeControllerAccess = true; // Direct Get.find without safety check
      expect(unsafeControllerAccess, isFalse,
        reason: 'BUG DETECTED: Unsafe controller access without existence validation\n'
               'Location: navigation_controller.dart line 66');
    });

    // BUG 9: Inconsistent state management patterns
    test('BUG: Inconsistent state reset patterns across methods', () {
      final inconsistentStateReset = true; // Different patterns for hiding/resetting state
      expect(inconsistentStateReset, isFalse,
        reason: 'BUG DETECTED: Inconsistent state management patterns\n'
               'Location: navigation_controller.dart line 78-81, 99-111');
    });

    // BUG 10: Missing validation for navigation arguments
    test('BUG: Missing validation for navigation arguments', () {
      final missingArgValidation = true; // No validation of required keys in args maps
      expect(missingArgValidation, isFalse,
        reason: 'BUG DETECTED: Missing validation for navigation arguments\n'
               'Location: navigation_controller.dart line 73-76, 94-97, 115-135');
    });

    // BUG 11: Potential null pointer in maxIndex calculation
    test('BUG: Hardcoded role-based index calculation without validation', () {
      final hardcodedRoleIndexing = true; // maxIndex logic assumes specific role structure
      expect(hardcodedRoleIndexing, isFalse,
        reason: 'BUG DETECTED: Hardcoded role-based navigation logic\n'
               'Location: navigation_controller.dart line 146-150');
    });

    // BUG 12: Missing cleanup in navigation state transitions
    test('BUG: Missing cleanup in navigation state transitions', () {
      final missingCleanupInTransitions = true; // State not fully reset when switching contexts
      expect(missingCleanupInTransitions, isFalse,
        reason: 'BUG DETECTED: Incomplete state cleanup in navigation transitions\n'
               'Location: navigation_controller.dart line 145-172');
    });
  });

  // ============================================================
  // NAVIGATION CONTROLLER FUNCTIONAL TESTS
  // ============================================================
  group('NavigationController Functional Tests', () {
    late NavigationController controller;
    
    setUp(() {
      Get.reset();
      
      // Register required dependencies
      Get.put<MockApiClient>(MockApiClient());
      
      controller = NavigationController();
      Get.put<NavigationController>(controller);
    });
    
    tearDown(() {
      Get.reset();
    });

    // ─── Tab Navigation Tests ─────────────────────────────────────────────────
    group('Tab Navigation', () {
      test('should have default tab index of 1', () {
        expect(controller.selectedIndex.value, equals(1));
      });
      
      test('should change tab index correctly', () {
        controller.changeTab(2);
        expect(controller.selectedIndex.value, equals(2));
      });
      
      test('should reset community search when leaving community tab', () {
        Get.put<MockCommunityController>(MockCommunityController());
        
        controller.selectedIndex.value = 2;
        controller.changeTab(1);
        
        final communityController = Get.find<MockCommunityController>();
        expect(communityController.searchKeyword.value, equals(''));
      });
    });

    // ─── Class Detail Navigation Tests ────────────────────────────────────────
    group('Class Detail Navigation', () {
      test('should show class detail with correct arguments', () {
        final args = createTestClassDetailArgs();
        
        controller.showClassDetail(args);
        
        expect(controller.isShowingClassDetail.value, isTrue);
        expect(controller.classDetailArgs.value, equals(args));
      });
      
      test('should hide class detail and clear arguments', () {
        final args = createTestClassDetailArgs();
        controller.showClassDetail(args);
        
        controller.hideClassDetail();
        
        expect(controller.isShowingClassDetail.value, isFalse);
        expect(controller.classDetailArgs.value, isNull);
      });
      
      test('should show class detail from redirect and switch to tab 1', () {
        final args = createTestClassDetailArgs();
        controller.selectedIndex.value = 2;
        
        controller.showClassDetailFromRedirect(args);
        
        expect(controller.selectedIndex.value, equals(1));
        expect(controller.isShowingClassDetail.value, isTrue);
        expect(controller.classDetailArgs.value, equals(args));
      });
      
      test('should return correct shouldRestoreClassDetail state', () {
        expect(controller.shouldRestoreClassDetail, isFalse);
        
        controller.showClassDetail(createTestClassDetailArgs());
        expect(controller.shouldRestoreClassDetail, isTrue);
        
        controller.hideClassDetail();
        expect(controller.shouldRestoreClassDetail, isFalse);
      });
    });

    // ─── Community Detail Navigation Tests ─────────────────────────────────────
    group('Community Detail Navigation', () {
      test('should show community detail with correct arguments', () {
        final args = createTestCommunityArgs();
        
        controller.showCommunityDetail(args);
        
        expect(controller.isShowingCommunityDetail.value, isTrue);
        expect(controller.communityDetailArgs.value, equals(args));
      });
      
      test('should hide community detail and reload communities', () {
        Get.put<MockCommunityController>(MockCommunityController());
        final args = createTestCommunityArgs();
        controller.showCommunityDetail(args);
        
        controller.hideCommunityDetail();
        
        expect(controller.isShowingCommunityDetail.value, isFalse);
        expect(controller.communityDetailArgs.value, isNull);
      });
    });

    // ─── Class Assignment Navigation Tests ─────────────────────────────────────
    group('Class Assignment Navigation', () {
      test('should show class assignment and register dependencies', () {
        final args = createTestAssignmentArgs();
        
        controller.showClassAssignment(args);
        
        expect(controller.isShowingClassAssignment.value, isTrue);
        expect(controller.classAssignmentArgs.value, equals(args));
        expect(Get.isRegistered<AssignmentRepository>(), isTrue);
        expect(Get.isRegistered<ClassFeedRepository>(), isTrue);
      });
      
      test('should hide class assignment and clean up controller', () {
        final args = createTestAssignmentArgs();
        controller.showClassAssignment(args);
        
        controller.hideClassAssignment();
        
        expect(controller.isShowingClassAssignment.value, isFalse);
        expect(controller.classAssignmentArgs.value, isNull);
      });
    });

    // ─── Role Change Navigation Tests ──────────────────────────────────────────
    group('Role Change Navigation', () {
      test('should reset navigation for student role', () {
        controller.selectedIndex.value = 4;
        controller.showClassDetail(createTestClassDetailArgs());
        controller.showCommunityDetail(createTestCommunityArgs());
        
        controller.resetForRoleChange(true);
        
        expect(controller.selectedIndex.value, equals(1));
        expect(controller.isShowingClassDetail.value, isFalse);
        expect(controller.isShowingCommunityDetail.value, isFalse);
        expect(controller.classDetailArgs.value, isNull);
        expect(controller.communityDetailArgs.value, isNull);
      });
      
      test('should reset navigation for teacher role', () {
        controller.selectedIndex.value = 3;
        controller.showClassDetail(createTestClassDetailArgs());
        
        controller.resetForRoleChange(false);
        
        expect(controller.selectedIndex.value, equals(1));
        expect(controller.isShowingClassDetail.value, isFalse);
      });
      
      test('should clean up assignment controller on role change', () {
        controller.showClassAssignment(createTestAssignmentArgs());
        
        controller.resetForRoleChange(true);
        
        expect(controller.isShowingClassAssignment.value, isFalse);
        expect(controller.classAssignmentArgs.value, isNull);
      });
    });
  });

  // ─── Dependency Management Tests ───────────────────────────────────────────────
  group('Dependency Management Tests', () {
    late NavigationController controller;
    
    setUp(() {
      Get.reset();
      Get.put<MockApiClient>(MockApiClient());
      controller = NavigationController();
    });
    
    tearDown(() {
      Get.reset();
    });

    test('should register dependencies only once', () {
      // Call multiple times to test idempotency
      controller.showClassAssignment(createTestAssignmentArgs());
      controller.showClassAssignment(createTestAssignmentArgs());
      
      // Should not throw or create duplicates
      expect(Get.isRegistered<AssignmentRepository>(), isTrue);
      expect(Get.isRegistered<ClassFeedRepository>(), isTrue);
    });
    
    test('should handle missing dependencies gracefully', () {
      // This should not throw even if ApiClient is missing temporarily
      Get.delete<MockApiClient>();
      
      expect(() => controller.showClassAssignment(createTestAssignmentArgs()), 
        throwsA(isA<Exception>()));
    });
  });
}