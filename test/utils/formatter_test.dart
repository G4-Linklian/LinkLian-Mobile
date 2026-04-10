import 'package:flutter_test/flutter_test.dart';
import 'package:LinkLian/core/utils/formatter.dart';

void main() {
  group('Formatter.formatPrice', () {
    test('should format positive price with 2 decimal places', () {
      final result = Formatter.formatPrice(100.0);
      expect(result, '100.00 บาท');
    });

    test('should format price with decimal values', () {
      final result = Formatter.formatPrice(99.99);
      expect(result, '99.99 บาท');
    });

    test('should format zero price', () {
      final result = Formatter.formatPrice(0.0);
      expect(result, '0.00 บาท');
    });

    test('should handle negative price appropriately', () {
      final result = Formatter.formatPrice(-50.0);
      expect(result, isNot(contains('-')),
          reason: 'Negative prices should not be displayed with minus sign or should throw error');
    });

    test('should format large numbers with thousand separators', () {
      final result = Formatter.formatPrice(1000000.0);
      expect(result, contains(','),
          reason: 'Large numbers should have thousand separators for readability');
    });

    test('should round correctly for more than 2 decimal places', () {
      final result = Formatter.formatPrice(10.999);
      expect(result, '11.00 บาท');
    });
  });

  group('Formatter.dayOfWeekToText', () {
    test('should return Monday for 1', () {
      final result = Formatter.dayOfWeekToText(1);
      expect(result, 'วันจันทร์');
    });

    test('should return Tuesday for 2', () {
      final result = Formatter.dayOfWeekToText(2);
      expect(result, 'วันอังคาร');
    });

    test('should return Wednesday for 3', () {
      final result = Formatter.dayOfWeekToText(3);
      expect(result, 'วันพุธ');
    });

    test('should return Thursday for 4', () {
      final result = Formatter.dayOfWeekToText(4);
      expect(result, 'วันพฤหัสบดี');
    });

    test('should return Friday for 5', () {
      final result = Formatter.dayOfWeekToText(5);
      expect(result, 'วันศุกร์');
    });

    test('should return Saturday for 6', () {
      final result = Formatter.dayOfWeekToText(6);
      expect(result, 'วันเสาร์');
    });

    test('should return Sunday for 7', () {
      final result = Formatter.dayOfWeekToText(7);
      expect(result, 'วันอาทิตย์');
    });

    test('should handle invalid day 0 with meaningful response', () {
      final result = Formatter.dayOfWeekToText(0);
      expect(result, isNotEmpty,
          reason: 'Invalid day should return error message, not empty string');
    });

    test('should handle invalid day 8 with meaningful response', () {
      final result = Formatter.dayOfWeekToText(8);
      expect(result, isNotEmpty,
          reason: 'Invalid day should return error message, not empty string');
    });

    test('should handle negative day with meaningful response', () {
      final result = Formatter.dayOfWeekToText(-1);
      expect(result, isNotEmpty,
          reason: 'Negative day should return error message, not empty string');
    });

    test('should be compatible with DateTime.weekday (Monday=1, Sunday=7)', () {
      final monday = DateTime(2024, 1, 1);
      final result = Formatter.dayOfWeekToText(monday.weekday);
      expect(result, 'วันจันทร์');
    });
  });

  group('Formatter.formatTime', () {
    test('should format standard HH:MM:SS time', () {
      final result = Formatter.formatTime('14:30:00');
      expect(result, '14.30');
    });

    test('should format HH:MM time', () {
      final result = Formatter.formatTime('09:15');
      expect(result, '09.15');
    });

    test('should handle time at midnight', () {
      final result = Formatter.formatTime('00:00:00');
      expect(result, '00.00');
    });

    test('should handle time at noon', () {
      final result = Formatter.formatTime('12:00:00');
      expect(result, '12.00');
    });

    test('should handle empty string gracefully', () {
      final result = Formatter.formatTime('');
      expect(result, isNotEmpty,
          reason: 'Empty string should return error message or default value');
    });

    test('should handle string shorter than 5 characters', () {
      final result = Formatter.formatTime('1:30');
      expect(result, '1.30',
          reason: 'Short time format should still be converted properly');
    });

    test('should handle invalid time format', () {
      final result = Formatter.formatTime('invalid');
      expect(result, isNot('inval'),
          reason: 'Invalid time format should not just truncate the string');
    });

    test('should handle null-like input with validation', () {
      final result = Formatter.formatTime('null');
      expect(result, isNot('null.'),
          reason: 'String "null" should be validated as invalid time');
    });

    test('should preserve leading zeros', () {
      final result = Formatter.formatTime('08:05:00');
      expect(result, '08.05');
    });

    test('should handle 24-hour format edge case', () {
      final result = Formatter.formatTime('23:59:59');
      expect(result, '23.59');
    });
  });
}
