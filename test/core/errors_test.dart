import 'dart:async';
import 'dart:io';

import 'package:bessie/src/core/errors.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  String messageFor(Object error) => AppException.from(error).message;

  group('PostgrestException', () {
    test('database-raised messages pass through', () {
      for (final code in ['BS001', 'BS002', 'BS003', 'BS004']) {
        expect(messageFor(PostgrestException(message: 'You can request at most 3 activities', code: code)), 'You can request at most 3 activities');
      }
    });

    test('well-known SQLSTATEs become friendly messages', () {
      expect(messageFor(PostgrestException(message: 'x', code: '42501')), contains('permission'));
      expect(messageFor(PostgrestException(message: 'x', code: '23505')), contains('already exists'));
      expect(messageFor(PostgrestException(message: 'x', code: '23503')), contains('no longer exists'));
      expect(
        messageFor(PostgrestException(
          message: 'update or delete on table "activities" violates foreign key constraint',
          code: '23503',
          details: 'Key (id)=(1) is still referenced from table "scheduled_activities".',
        )),
        contains('still depends'),
        reason: 'a blocked delete is not a dangling reference',
      );
      expect(messageFor(PostgrestException(message: 'x', code: '23P01')), contains('overlaps'));
      expect(messageFor(PostgrestException(message: 'x', code: 'P0002')), contains('could not be found'));
      expect(messageFor(PostgrestException(message: 'JWT expired', code: 'PGRST301')), contains('expired'));
    });

    test('unknown codes never leak internals', () {
      expect(messageFor(PostgrestException(message: 'relation "campers" does not exist', code: '42P01')), isNot(contains('campers')));
    });
  });

  test('AuthException codes', () {
    expect(messageFor(const AuthApiException('bad', statusCode: '400', code: 'invalid_credentials')), 'Incorrect email or password.');
    expect(messageFor(const AuthApiException('bad', statusCode: '422', code: 'weak_password')), contains('too weak'));
    expect(messageFor(const AuthException('Something specific')), 'Something specific');
  });

  test('network failures', () {
    expect(messageFor(const SocketException('no route')), contains('reach the server'));
    expect(messageFor(TimeoutException('slow')), contains('reach the server'));
  });

  test('anything else is generic and keeps the cause', () {
    final error = StateError('boom');
    final wrapped = AppException.from(error);
    expect(wrapped.message, 'Something went wrong.');
    expect(wrapped.cause, error);
  });

  test('AppException passes through unchanged', () {
    final original = AppException('Already friendly');
    expect(identical(AppException.from(original), original), isTrue);
  });

  test('guarded converts and keeps the stack trace', () async {
    await expectLater(
      guarded(() async => throw const SocketException('down')),
      throwsA(isA<AppException>().having((e) => e.cause, 'cause', isA<SocketException>())),
    );
    expect(await guarded(() async => 42), 42);
  });

  test('ensureAffected', () {
    ensureAffected([{'id': 1}], 1);
    ensureAffected([], 0);
    expect(() => ensureAffected([], 2), throwsA(isA<AppException>()));
  });
}
