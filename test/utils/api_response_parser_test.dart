import 'package:flutter_test/flutter_test.dart';
import 'package:LinkLian/core/utils/api_response_parser.dart';

class TestModel {
  final int id;
  final String name;

  TestModel({required this.id, required this.name});

  factory TestModel.fromJson(Map<String, dynamic> json) {
    return TestModel(
      id: json['id'] as int,
      name: json['name'] as String,
    );
  }
}

void main() {
  group('ApiResponseParser.parseObject', () {
    test('should parse valid response with data object', () {
      final response = {
        'data': {'id': 1, 'name': 'Test'}
      };
      final result = ApiResponseParser.parseObject(response, TestModel.fromJson);
      expect(result, isNotNull);
      expect(result!.id, 1);
      expect(result.name, 'Test');
    });

    test('should return null when data is null', () {
      final response = {'data': null};
      final result = ApiResponseParser.parseObject(response, TestModel.fromJson);
      expect(result, isNull);
    });

    test('should return null when response has no data key', () {
      final response = {'result': {'id': 1, 'name': 'Test'}};
      final result = ApiResponseParser.parseObject(response, TestModel.fromJson);
      expect(result, isNull);
    });

    test('should return null for empty response', () {
      final response = {};
      final result = ApiResponseParser.parseObject(response, TestModel.fromJson);
      expect(result, isNull);
    });

    test('should handle response with success and data', () {
      final response = {
        'success': true,
        'data': {'id': 1, 'name': 'Test'}
      };
      final result = ApiResponseParser.parseObject(response, TestModel.fromJson);
      expect(result, isNotNull);
    });

    test('should handle string response gracefully', () {
      const response = 'invalid response';
      final result = ApiResponseParser.parseObject(response, TestModel.fromJson);
      expect(result, isNull);
    });

    test('should handle null response gracefully', () {
      final result = ApiResponseParser.parseObject(null, TestModel.fromJson);
      expect(result, isNull);
    });

    test('should handle nested data structure', () {
      final response = {
        'data': {
          'data': {'id': 1, 'name': 'Nested'}
        }
      };
      final result = ApiResponseParser.parseObject(response, TestModel.fromJson);
      expect(result, isNull,
          reason: 'Nested data structure should not parse inner data directly');
    });

    test('should check success flag before parsing', () {
      final response = {
        'success': false,
        'data': {'id': 1, 'name': 'Test'},
        'error': 'Some error'
      };
      final result = ApiResponseParser.parseObject(response, TestModel.fromJson);
      expect(result, isNull,
          reason: 'Should not parse data when success is false');
    });
  });

  group('ApiResponseParser.parseList', () {
    test('should parse valid list from data key', () {
      final response = {
        'data': [
          {'id': 1, 'name': 'Test1'},
          {'id': 2, 'name': 'Test2'}
        ]
      };
      final result = ApiResponseParser.parseList(response, TestModel.fromJson);
      expect(result.length, 2);
      expect(result[0].id, 1);
      expect(result[1].id, 2);
    });

    test('should parse direct list response', () {
      final response = [
        {'id': 1, 'name': 'Test1'},
        {'id': 2, 'name': 'Test2'}
      ];
      final result = ApiResponseParser.parseList(response, TestModel.fromJson);
      expect(result.length, 2);
    });

    test('should return empty list for empty data', () {
      final response = {'data': []};
      final result = ApiResponseParser.parseList(response, TestModel.fromJson);
      expect(result, isEmpty);
    });

    test('should return empty list for null data', () {
      final response = {'data': null};
      final result = ApiResponseParser.parseList(response, TestModel.fromJson);
      expect(result, isEmpty);
    });

    test('should return empty list for invalid response', () {
      const response = 'invalid';
      final result = ApiResponseParser.parseList(response, TestModel.fromJson);
      expect(result, isEmpty);
    });

    test('should filter out invalid items in list', () {
      final response = {
        'data': [
          {'id': 1, 'name': 'Valid'},
          'invalid_item',
          null,
          {'id': 2, 'name': 'Valid2'}
        ]
      };
      final result = ApiResponseParser.parseList(response, TestModel.fromJson);
      expect(result.length, 2);
    });

    test('should handle null response gracefully', () {
      final result = ApiResponseParser.parseList(null, TestModel.fromJson);
      expect(result, isEmpty);
    });

    test('should check success flag before parsing list', () {
      final response = {
        'success': false,
        'data': [
          {'id': 1, 'name': 'Test'}
        ],
        'error': 'Access denied'
      };
      final result = ApiResponseParser.parseList(response, TestModel.fromJson);
      expect(result, isEmpty,
          reason: 'Should not parse list when success is false');
    });

    test('should handle paginated response with meta', () {
      final response = {
        'data': [
          {'id': 1, 'name': 'Test'}
        ],
        'meta': {'total': 100, 'page': 1}
      };
      final result = ApiResponseParser.parseList(response, TestModel.fromJson);
      expect(result.length, 1);
    });

    test('should handle response with items key instead of data', () {
      final response = {
        'items': [
          {'id': 1, 'name': 'Test'}
        ]
      };
      final result = ApiResponseParser.parseList(response, TestModel.fromJson);
      expect(result, isNotEmpty,
          reason: 'Common API patterns use "items" key for lists');
    });

    test('should handle response with results key instead of data', () {
      final response = {
        'results': [
          {'id': 1, 'name': 'Test'}
        ]
      };
      final result = ApiResponseParser.parseList(response, TestModel.fromJson);
      expect(result, isNotEmpty,
          reason: 'Common API patterns use "results" key for lists');
    });
  });

  group('ApiResponseParser.parseSuccess', () {
    test('should return true when success is true', () {
      final response = {'success': true};
      final result = ApiResponseParser.parseSuccess(response);
      expect(result, isTrue);
    });

    test('should return false when success is false', () {
      final response = {'success': false};
      final result = ApiResponseParser.parseSuccess(response);
      expect(result, isFalse);
    });

    test('should return false when success key is missing', () {
      final response = {'data': {}};
      final result = ApiResponseParser.parseSuccess(response);
      expect(result, isFalse);
    });

    test('should return false for non-map response', () {
      const response = 'invalid';
      final result = ApiResponseParser.parseSuccess(response);
      expect(result, isFalse);
    });

    test('should return false for null response', () {
      final result = ApiResponseParser.parseSuccess(null);
      expect(result, isFalse);
    });

    test('should handle success as string "true"', () {
      final response = {'success': 'true'};
      final result = ApiResponseParser.parseSuccess(response);
      expect(result, isTrue,
          reason: 'Some APIs return success as string "true"');
    });

    test('should handle success as integer 1', () {
      final response = {'success': 1};
      final result = ApiResponseParser.parseSuccess(response);
      expect(result, isTrue,
          reason: 'Some APIs return success as integer 1');
    });

    test('should handle ok key as alternative to success', () {
      final response = {'ok': true};
      final result = ApiResponseParser.parseSuccess(response);
      expect(result, isTrue,
          reason: 'Common API patterns use "ok" key for success status');
    });

    test('should handle status key with value "success"', () {
      final response = {'status': 'success'};
      final result = ApiResponseParser.parseSuccess(response);
      expect(result, isTrue,
          reason: 'Common API patterns use status: "success"');
    });

    test('should handle HTTP status code 200 as success indicator', () {
      final response = {'statusCode': 200, 'data': {}};
      final result = ApiResponseParser.parseSuccess(response);
      expect(result, isTrue,
          reason: 'HTTP 200 status code indicates success');
    });
  });
}
