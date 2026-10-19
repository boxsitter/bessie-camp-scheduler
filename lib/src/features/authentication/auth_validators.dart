/// Checks for the sign-in, forgot-password and reset-password forms.
///
/// Each returns null when the value is fine, otherwise the message to show.
class AuthValidators {
  const AuthValidators._();

  /// Matches `minimum_password_length` in `supabase/config.toml`.
  static const minPasswordLength = 8;

  static final _email = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  static String? email(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return 'Enter your email address.';
    return _email.hasMatch(text) ? null : 'Enter a valid email address.';
  }

  /// For signing in: any password will do, the server decides if it is right.
  static String? password(String? value) => (value ?? '').isEmpty ? 'Enter your password.' : null;

  static String? newPassword(String? value) {
    final text = value ?? '';
    if (text.isEmpty) return 'Choose a new password.';
    return text.length < minPasswordLength ? 'Use at least $minPasswordLength characters.' : null;
  }

  static String? confirmPassword(String? value, String newPassword) {
    final text = value ?? '';
    if (text.isEmpty) return 'Type the new password again.';
    return text == newPassword ? null : 'The passwords don\'t match.';
  }
}
