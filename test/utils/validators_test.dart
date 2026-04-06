import 'package:flutter_test/flutter_test.dart';
import 'package:LinkLian/core/utils/validators.dart';
import 'package:LinkLian/core/constants/strings.dart';

void main() {
  group('Validators.validateEmail', () {
    test('should return error when email is null', () {
      final result = Validators.validateEmail(null);
      expect(result, AppStrings.emailRequired);
    });

    test('should return error when email is empty', () {
      final result = Validators.validateEmail('');
      expect(result, AppStrings.emailRequired);
    });

    test('should return null for valid email', () {
      final result = Validators.validateEmail('test@example.com');
      expect(result, isNull);
    });

    test('should return error for email without @', () {
      final result = Validators.validateEmail('testexample.com');
      expect(result, AppStrings.emailInvalid);
    });

    test('should return error for email without domain', () {
      final result = Validators.validateEmail('test@');
      expect(result, AppStrings.emailInvalid);
    });

    test('should return error for email with consecutive dots', () {
      final result = Validators.validateEmail('test..email@domain.com');
      expect(result, AppStrings.emailInvalid,
          reason: 'Email with consecutive dots should be invalid');
    });

    test('should return error for email starting with dot', () {
      final result = Validators.validateEmail('.test@domain.com');
      expect(result, AppStrings.emailInvalid,
          reason: 'Email starting with dot should be invalid');
    });

    test('should return error for email with dot before @', () {
      final result = Validators.validateEmail('test.@domain.com');
      expect(result, AppStrings.emailInvalid,
          reason: 'Email with dot before @ should be invalid');
    });

    test('should return error for email with spaces', () {
      final result = Validators.validateEmail('test @example.com');
      expect(result, AppStrings.emailInvalid);
    });
  });

  group('Validators.validatePassword', () {
    test('should return error when password is null', () {
      final result = Validators.validatePassword(null);
      expect(result, AppStrings.passwordRequired);
    });

    test('should return error when password is empty', () {
      final result = Validators.validatePassword('');
      expect(result, AppStrings.passwordRequired);
    });

    test('should return error when password is less than 6 characters', () {
      final result = Validators.validatePassword('12345');
      expect(result, AppStrings.passwordTooShort);
    });

    test('should return null for valid password with 6 characters', () {
      final result = Validators.validatePassword('123456');
      expect(result, isNull);
    });

    test('should return null for valid password with more than 6 characters', () {
      final result = Validators.validatePassword('password123');
      expect(result, isNull);
    });

    test('should return error for password with only whitespace', () {
      final result = Validators.validatePassword('      ');
      expect(result, isNotNull,
          reason: 'Password with only whitespace should be invalid');
    });

    test('should return error for password with whitespace exceeding 6 chars', () {
      final result = Validators.validatePassword('        ');
      expect(result, isNotNull,
          reason: 'Password with 8 spaces should not be valid');
    });
  });

  group('Validators.validateRequired', () {
    test('should return error when value is null', () {
      final result = Validators.validateRequired(null, 'ชื่อ');
      expect(result, 'กรุณากรอกชื่อ');
    });

    test('should return error when value is empty', () {
      final result = Validators.validateRequired('', 'นามสกุล');
      expect(result, 'กรุณากรอกนามสกุล');
    });

    test('should return null for valid value', () {
      final result = Validators.validateRequired('John', 'ชื่อ');
      expect(result, isNull);
    });

    test('should return error for whitespace-only value', () {
      final result = Validators.validateRequired('   ', 'ชื่อ');
      expect(result, isNotNull,
          reason: 'Whitespace-only value should be invalid for required field');
    });
  });

  group('Validators.validatePhone', () {
    test('should return error when phone is null', () {
      final result = Validators.validatePhone(null);
      expect(result, 'กรุณากรอกหมายเลขโทรศัพท์');
    });

    test('should return error when phone is empty', () {
      final result = Validators.validatePhone('');
      expect(result, 'กรุณากรอกหมายเลขโทรศัพท์');
    });

    test('should return null for valid 10-digit phone', () {
      final result = Validators.validatePhone('0812345678');
      expect(result, isNull);
    });

    test('should return null for valid phone with dashes', () {
      final result = Validators.validatePhone('081-234-5678');
      expect(result, isNull);
    });

    test('should return error for phone with less than 10 digits', () {
      final result = Validators.validatePhone('081234567');
      expect(result, 'หมายเลขโทรศัพท์ไม่ถูกต้อง');
    });

    test('should return error for phone with more than 10 digits', () {
      final result = Validators.validatePhone('08123456789');
      expect(result, 'หมายเลขโทรศัพท์ไม่ถูกต้อง');
    });

    test('should return error for phone with letters', () {
      final result = Validators.validatePhone('08123abc78');
      expect(result, 'หมายเลขโทรศัพท์ไม่ถูกต้อง');
    });

    test('should return null for valid Thai phone starting with 0', () {
      final result = Validators.validatePhone('0912345678');
      expect(result, isNull);
    });

    test('should handle phone with spaces', () {
      final result = Validators.validatePhone('081 234 5678');
      expect(result, isNull,
          reason: 'Phone with spaces should be handled like dashes');
    });

    test('should return error for phone not starting with 0 (Thai standard)', () {
      final result = Validators.validatePhone('8123456789');
      expect(result, 'หมายเลขโทรศัพท์ไม่ถูกต้อง',
          reason: 'Thai phone numbers should start with 0');
    });
  });
}
