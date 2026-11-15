import 'package:flutter_test/flutter_test.dart';
import 'package:asset_flow_flutter/utils/login_validation.dart';

void main() {
  group('Login validation', () {
    test('accepts a valid email and trims surrounding whitespace', () {
      expect(isValidLoginEmail('  user@example.com  '), isTrue);
    });

    test('rejects missing, malformed, and whitespace-containing emails', () {
      for (final value in ['', 'user', 'user@', 'user@example', 'a b@example.com']) {
        expect(isValidLoginEmail(value), isFalse, reason: value);
      }
    });

    test('returns the first actionable Arabic validation message', () {
      expect(loginValidationMessage(email: ' ', password: ''), 'يرجى إدخال البريد الإلكتروني');
      expect(loginValidationMessage(email: 'bad', password: 'x'), 'صيغة البريد الإلكتروني غير صحيحة');
      expect(loginValidationMessage(email: 'user@example.com', password: ''), 'يرجى إدخال كلمة المرور');
      expect(loginValidationMessage(email: 'user@example.com', password: 'secret'), isNull);
    });
  });
}
