import 'package:bessie/src/features/authentication/authentication_controller.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  String redirect(String base) => AuthenticationController.passwordResetRedirect(Uri.parse(base));

  test('brings the user back to the reset page of the app they asked from', () {
    expect(redirect('https://bessie.example.org/'), 'https://bessie.example.org/#/resetPassword');
  });

  test('keeps the port', () {
    expect(redirect('http://localhost:3000/'), 'http://localhost:3000/#/resetPassword');
    expect(redirect('https://bessie.example.org:8443'), 'https://bessie.example.org:8443/#/resetPassword');
  });

  test('replaces whatever route, query and code the page had', () {
    expect(redirect('https://bessie.example.org/?code=abc#/login'), 'https://bessie.example.org/#/resetPassword');
  });

  test('keeps the folder the app is served from', () {
    expect(redirect('https://example.org/bessie/#/'), 'https://example.org/bessie/#/resetPassword');
  });
}
