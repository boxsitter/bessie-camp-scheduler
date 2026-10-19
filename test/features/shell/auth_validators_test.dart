import 'package:bessie/src/features/authentication/auth_validators.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('email', () {
    test('accepts ordinary addresses, ignoring surrounding space', () {
      expect(AuthValidators.email('director@bessie.test'), isNull);
      expect(AuthValidators.email('  first.last+camp@mail.example.org '), isNull);
      expect(AuthValidators.email('a@b.photography'), isNull);
    });

    test('asks for an address when empty', () {
      expect(AuthValidators.email(null), 'Enter your email address.');
      expect(AuthValidators.email('   '), 'Enter your email address.');
    });

    test('rejects text that is not an address', () {
      for (final bad in ['director', 'director@', '@bessie.test', 'director@bessie', 'two words@bessie.test', 'a@@b.co']) {
        expect(AuthValidators.email(bad), 'Enter a valid email address.', reason: bad);
      }
    });
  });

  group('password (signing in)', () {
    test('only needs to be filled in', () {
      expect(AuthValidators.password('x'), isNull);
      expect(AuthValidators.password(''), 'Enter your password.');
      expect(AuthValidators.password(null), 'Enter your password.');
    });
  });

  group('newPassword', () {
    test('needs at least as many characters as the server demands', () {
      expect(AuthValidators.minPasswordLength, 8);
      expect(AuthValidators.newPassword('1234567'), 'Use at least 8 characters.');
      expect(AuthValidators.newPassword('12345678'), isNull);
    });

    test('asks for a password when empty', () {
      expect(AuthValidators.newPassword(''), 'Choose a new password.');
      expect(AuthValidators.newPassword(null), 'Choose a new password.');
    });

    test('does not trim: spaces count', () {
      expect(AuthValidators.newPassword('        '), isNull);
    });
  });

  group('confirmPassword', () {
    test('must match the new password exactly', () {
      expect(AuthValidators.confirmPassword('hunter2hunter2', 'hunter2hunter2'), isNull);
      expect(AuthValidators.confirmPassword('hunter2hunter3', 'hunter2hunter2'), 'The passwords don\'t match.');
      expect(AuthValidators.confirmPassword('HUNTER2HUNTER2', 'hunter2hunter2'), 'The passwords don\'t match.');
    });

    test('asks to be filled in', () {
      expect(AuthValidators.confirmPassword('', 'hunter2hunter2'), 'Type the new password again.');
      expect(AuthValidators.confirmPassword(null, 'hunter2hunter2'), 'Type the new password again.');
    });
  });
}
