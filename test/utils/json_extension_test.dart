import 'package:flutter_test/flutter_test.dart';
import 'package:LinkLian/core/utils/json_extension.dart';

Map<String, dynamic> createJson(String key, dynamic value) {
  return {key: value};
}

void main() {
  group('JsonParsing.toInt', () {
    test('should return null for null value from JSON', () {
      final json = createJson('value', null);
      final result = json['value'].toInt();
      expect(result, isNull);
    });

    test('should return int when value is int from JSON', () {
      final json = createJson('value', 42);
      final result = json['value'].toInt();
      expect(result, 42);
    });

    test('should parse string to int from JSON', () {
      final json = createJson('value', '123');
      final result = json['value'].toInt();
      expect(result, 123);
    });

    test('should return null for invalid string from JSON', () {
      final json = createJson('value', 'abc');
      final result = json['value'].toInt();
      expect(result, isNull);
    });

    test('should handle negative int from JSON', () {
      final json = createJson('value', -10);
      final result = json['value'].toInt();
      expect(result, -10);
    });

    test('should parse negative string to int from JSON', () {
      final json = createJson('value', '-50');
      final result = json['value'].toInt();
      expect(result, -50);
    });

    test('should convert double to int from JSON', () {
      final json = createJson('value', 10.5);
      final result = json['value'].toInt();
      expect(result, 10,
          reason: 'Double value should be convertible to int');
    });

    test('should handle string with whitespace from JSON', () {
      final json = createJson('value', ' 123 ');
      final result = json['value'].toInt();
      expect(result, 123,
          reason: 'String with whitespace should be trimmed and parsed');
    });

    test('should handle empty string from JSON', () {
      final json = createJson('value', '');
      final result = json['value'].toInt();
      expect(result, isNull);
    });

    test('should handle bool value from JSON', () {
      final json = createJson('value', true);
      final result = json['value'].toInt();
      expect(result, isNull,
          reason: 'Bool should not be converted to int');
    });
  });

  group('JsonParsing.toDouble', () {
    test('should return null for null value from JSON', () {
      final json = createJson('value', null);
      final result = json['value'].toDouble();
      expect(result, isNull);
    });

    test('should return double when value is double from JSON', () {
      final json = createJson('value', 3.14);
      final result = json['value'].toDouble();
      expect(result, 3.14);
    });

    test('should convert int to double from JSON', () {
      final json = createJson('value', 10);
      final result = json['value'].toDouble();
      expect(result, 10.0);
    });

    test('should parse string to double from JSON', () {
      final json = createJson('value', '99.99');
      final result = json['value'].toDouble();
      expect(result, 99.99);
    });

    test('should return null for invalid string from JSON', () {
      final json = createJson('value', 'not a number');
      final result = json['value'].toDouble();
      expect(result, isNull);
    });

    test('should handle negative double from JSON', () {
      final json = createJson('value', -25.5);
      final result = json['value'].toDouble();
      expect(result, -25.5);
    });

    test('should handle string with whitespace from JSON', () {
      final json = createJson('value', ' 3.14 ');
      final result = json['value'].toDouble();
      expect(result, 3.14,
          reason: 'String with whitespace should be trimmed and parsed');
    });

    test('should handle empty string from JSON', () {
      final json = createJson('value', '');
      final result = json['value'].toDouble();
      expect(result, isNull);
    });

    test('should handle scientific notation from JSON', () {
      final json = createJson('value', '1.5e10');
      final result = json['value'].toDouble();
      expect(result, 1.5e10);
    });

    test('should return null for infinity string from JSON', () {
      final json = createJson('value', 'Infinity');
      final result = json['value'].toDouble();
      expect(result, isNull,
          reason: 'Infinity should not be parsed as valid double');
    });

    test('should return null for NaN string from JSON', () {
      final json = createJson('value', 'NaN');
      final result = json['value'].toDouble();
      expect(result, isNull,
          reason: 'NaN should not be parsed as valid double');
    });
  });

  group('JsonParsing.toDateTime', () {
    test('should return null for null value from JSON', () {
      final json = createJson('value', null);
      final result = json['value'].toDateTime();
      expect(result, isNull);
    });

    test('should parse ISO 8601 date string from JSON', () {
      final json = createJson('value', '2024-01-15T10:30:00');
      final result = json['value'].toDateTime();
      expect(result, isNotNull);
      expect(result!.year, 2024);
      expect(result.month, 1);
      expect(result.day, 15);
    });

    test('should parse date only string from JSON', () {
      final json = createJson('value', '2024-01-15');
      final result = json['value'].toDateTime();
      expect(result, isNotNull);
      expect(result!.year, 2024);
    });

    test('should return null for invalid date string from JSON', () {
      final json = createJson('value', 'not a date');
      final result = json['value'].toDateTime();
      expect(result, isNull);
    });

    test('should handle Unix timestamp milliseconds from JSON', () {
      final json = createJson('value', 1705312200000);
      final result = json['value'].toDateTime();
      expect(result, isNotNull,
          reason: 'Unix timestamp in milliseconds should be parsed');
    });

    test('should handle Unix timestamp seconds from JSON', () {
      final json = createJson('value', 1705312200);
      final result = json['value'].toDateTime();
      expect(result, isNotNull,
          reason: 'Unix timestamp in seconds should be parsed');
    });

    test('should parse ISO 8601 with timezone from JSON', () {
      final json = createJson('value', '2024-01-15T10:30:00Z');
      final result = json['value'].toDateTime();
      expect(result, isNotNull);
    });

    test('should handle empty string from JSON', () {
      final json = createJson('value', '');
      final result = json['value'].toDateTime();
      expect(result, isNull);
    });

    test('should handle Thai date format from JSON', () {
      final json = createJson('value', '15/01/2567');
      final result = json['value'].toDateTime();
      expect(result, isNotNull,
          reason: 'Thai date format should be supported');
    });

    test('should handle common API datetime format from JSON', () {
      final json = createJson('value', '2024-01-15 10:30:00');
      final result = json['value'].toDateTime();
      expect(result, isNotNull,
          reason: 'Space-separated datetime should be supported');
    });
  });

  group('JsonParsing.toStr', () {
    test('should return null for null value from JSON', () {
      final json = createJson('value', null);
      final result = json['value'].toStr();
      expect(result, isNull);
    });

    test('should convert string to string from JSON', () {
      final json = createJson('value', 'hello');
      final result = json['value'].toStr();
      expect(result, 'hello');
    });

    test('should convert int to string from JSON', () {
      final json = createJson('value', 123);
      final result = json['value'].toStr();
      expect(result, '123');
    });

    test('should convert double to string from JSON', () {
      final json = createJson('value', 3.14);
      final result = json['value'].toStr();
      expect(result, '3.14');
    });

    test('should convert bool to string from JSON', () {
      final json = createJson('value', true);
      final result = json['value'].toStr();
      expect(result, 'true');
    });

    test('should handle empty string from JSON', () {
      final json = createJson('value', '');
      final result = json['value'].toStr();
      expect(result, '');
    });

    test('should not convert list to string from JSON', () {
      final json = createJson('value', [1, 2, 3]);
      final result = json['value'].toStr();
      expect(result, isNull,
          reason: 'List should not be converted to string representation');
    });

    test('should not convert map to string from JSON', () {
      final json = createJson('value', {'key': 'value'});
      final result = json['value'].toStr();
      expect(result, isNull,
          reason: 'Map should not be converted to string representation');
    });

    test('should trim whitespace from string in JSON', () {
      final json = createJson('value', '  hello  ');
      final result = json['value'].toStr();
      expect(result, 'hello',
          reason: 'String should be trimmed');
    });
  });
}
