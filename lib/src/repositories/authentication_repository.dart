
import 'package:firebase_auth/firebase_auth.dart';

import '../ember_core.dart';
import '../debug/auth_exceptions.dart';

class AuthenticationRepository {
  final _auth = FirebaseAuth.instance;

  bool get isUserLoggedIn => _auth.currentUser != null;
  String? get firebaseUid => _auth.currentUser?.uid;

  /// Logs in a user with the provided email and password using Firebase Authentication.
  ///
  /// Parameters:
  ///   [email]: The user's registered email.
  ///   [password]: The user's password.
  ///
  /// Returns:
  ///   A [Future] that completes with the [UserCredential] on successful authentication.
  ///
  /// Throws:
  ///   A specific exception extending [EmberException] (e.g., [AuthCredentialsFailure], [AuthServiceError])
  ///   if the login fails or an unexpected error occurs.
  Future<UserCredential> loginWithEmailAndPassword(String email, String password, bool rememberMe, bool isWeb) async {

    Debug.logInfo(
      'Attempting Firebase login for email: ${CoreFormatter.maskEmail(email)}',
      verbosity: Verbosity.verbose,
    );

    try {
      if (isWeb) { // Only execute this block if the app is running on the web
        if (rememberMe) {
          await _auth.setPersistence(Persistence.LOCAL);
          Debug.logInfo('[AuthRepo] Set persistence to LOCAL');
        } else {
          await _auth.setPersistence(Persistence.SESSION);
          Debug.logInfo('[AuthRepo] Set persistence to SESSION');
        }
      } else {
        // For non-web platforms (Android, iOS, Desktop), Firebase handles persistence automatically.
        // You generally don't need to explicitly call setPersistence.
        // You might want to log a message here if 'rememberMe' is still a relevant concept
        // for your non-web users, but the actual persistence mechanism is internal to Firebase.
        Debug.logInfo('[AuthRepo] Persistence handled automatically by Firebase for non-web platform.');
      }

      // Attempt to sign in using Firebase Auth
      final UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Log successful login

      Debug.logSuccess('${CoreFormatter.maskEmail(email)} successfully authenticated by Firebase');

      // Return the credential on success
      return userCredential;

    } on FirebaseAuthException catch (e, st) {
      final exception = BessFirebaseAuthExceptionFactory.fromCode(e.code);
      Error.throwWithStackTrace(Debug.parseException(exception), st);
    } catch (e, st) {
      Error.throwWithStackTrace(Debug.parseException(e), st);
    }
  }

  /// Stream for listening to authentication state changes.
  /// Emits the current [User] when logged in, or null when logged out.
  Stream<User?> get authStateChanges {
    Debug.logInfo('authStateChanges stream accessed', verbosity: Verbosity.excessive);
    return _auth.authStateChanges();
  }

  /// Registers a new user with the provided email, password, and name using Firebase Authentication.
  ///
  /// Parameters:
  ///   [email]: The user's desired email.
  ///   [password]: The user's desired password.
  ///   [name]: The user's display name (Note: This might be stored separately, e.g., in Firestore, after registration).
  ///
  /// Returns:
  ///   A [Future] that completes with the [UserCredential] on successful registration.
  ///
  /// Throws:
  ///   A specific exception extending [EmberException] (e.g., [AuthCredentialsFailure], [AuthServiceError])
  ///   if the registration fails or an unexpected error occurs.
  Future<String> registerWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    Debug.logInfo(
      'Attempting Firebase registration for email: ${CoreFormatter.maskEmail(email)}',
      verbosity: Verbosity.verbose,
    );

    try {
      // Attempt to create a new user using Firebase Auth
      final UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Log successful registration
      final userId = userCredential.user!.uid;
      Debug.logInfo(
        'Firebase registration successful. User ID: $userId',
        verbosity: Verbosity.verbose,
        metadata: {'userId': userId, 'email': CoreFormatter.maskEmail(email)},
      );
      return userId;
    } on FirebaseAuthException catch (e, st) {
      final exception = BessFirebaseAuthExceptionFactory.fromCode(e.code);
      Error.throwWithStackTrace(Debug.parseException(exception), st);
    } catch (e, st) {
      Error.throwWithStackTrace(Debug.parseException(e), st);
    }
  }

  /// Sends an email verification link to the currently authenticated user.
  ///
  /// Throws an exception if no user is currently logged in or if an error occurs during sending.
  Future<void> sendEmailVerification() async {
    final user = _auth.currentUser;
    if (user == null) {
      Error.throwWithStackTrace(AuthSessionFailure(reason: 'Attempted to send email verification while user was not logged in'), StackTrace.current);
    }

    Debug.logInfo(
      'Attempting to send verification email to: ${CoreFormatter.maskEmail(user.email)}',
      verbosity: Verbosity.verbose,
      metadata: {'userId': user.uid},
    );

    try {
      await user.sendEmailVerification();
      Debug.logInfo(
        'Verification email sent successfully to ${CoreFormatter.maskEmail(user.email)}.',
        verbosity: Verbosity.verbose,
        metadata: {'userId': user.uid},
      );
    } on FirebaseAuthException catch (e, st) {
      final exception = BessFirebaseAuthExceptionFactory.fromCode(e.code);
      Error.throwWithStackTrace(Debug.parseException(exception), st);
    } catch (e, st) {
      Error.throwWithStackTrace(Debug.parseException(e), st);
    }
  }

  /// Sends a password reset email to the specified email address.
  ///
  /// Parameters:
  ///   [email]: The email address to send the reset link to.
  ///
  /// Throws an exception if an error occurs during sending.
  Future<void> sendPasswordResetEmail(String email) async {
    Debug.logInfo(
      'Attempting to send password reset email to: ${CoreFormatter.maskEmail(email)}',
      verbosity: Verbosity.verbose,
    );

    try {
      await _auth.sendPasswordResetEmail(email: email);
      Debug.logInfo(
        'Password reset email sent successfully to ${CoreFormatter.maskEmail(email)}.',
        verbosity: Verbosity.verbose,
      );
    } on FirebaseAuthException catch (e, st) {
      final exception = BessFirebaseAuthExceptionFactory.fromCode(e.code);
      Error.throwWithStackTrace(Debug.parseException(exception), st);
    } catch (e, st) {
      Error.throwWithStackTrace(Debug.parseException(e), st);
    }
  }

  /// Logs out the currently authenticated user.
  ///
  /// Throws an exception if an error occurs during sign out.
  Future<void> logout() async {
    final userId = _auth.currentUser?.uid;
    final maskedEmail = CoreFormatter.maskEmail(_auth.currentUser?.email);
    Debug.logInfo(
      'Attempting to log out user: ${userId ?? 'N/A'} ($maskedEmail)',
      verbosity: Verbosity.verbose,
      metadata: {'userId': userId ?? 'null'},
    );

    try {
      await _auth.signOut();
      Debug.logInfo(
        'User logged out successfully.',
        verbosity: Verbosity.verbose,
        metadata: {'previousUserId': userId ?? 'null'},
      );
    } on FirebaseAuthException catch (e, st) {
      // Although less common, catch specific auth errors if they occur
      final exception = BessFirebaseAuthExceptionFactory.fromCode(e.code);
      Error.throwWithStackTrace(Debug.parseException(exception), st);
    } catch (e, st) {
      Error.throwWithStackTrace(Debug.parseException(e), st);
    }
  }

  /// Placeholder for deactivating a user account.
  ///
  /// **Important:** Firebase Auth itself doesn't have a "deactivate" state via the client SDK.
  /// Actual deactivation typically involves setting a flag (e.g., `isActive = false`)
  /// in the user's data record within Firestore or another database. This method
  /// might coordinate with a UserRepository or backend function to perform that update.
  ///
  /// Throws an exception if no user is signed in or if an error occurs during the process.
  Future<void> deactivateUser() async {
    final user = _auth.currentUser;
    if (user == null) {
      Error.throwWithStackTrace(AuthSessionFailure(reason: 'Cannot deactivate user: No user is currently signed in'), StackTrace.current);
    }

    final userId = user.uid;
    Debug.logInfo(
      'Attempting to deactivate user: $userId',
      verbosity: Verbosity.verbose,
      metadata: {'userId': userId},
    );

    try {
      // TODO: Implement actual deactivation logic.
      // This usually involves:
      // 1. Calling a UserRepository or backend service.
      // 2. Updating a flag in the user's Firestore document (e.g., {'isActive': false}).
      // 3. Potentially signing the user out after updating the flag.
      // Example: await UserRepository.instance.updateUserFlag(userId, 'isActive', false);
      // Example: await callCloudFunction('deactivateUser', {'userId': userId});

      // For now, just log the intent.
      Debug.logInfo(
        'Deactivation placeholder called for user: $userId. Actual logic (DB flag update) TBD.',
        verbosity: Verbosity.verbose,
        metadata: {'userId': userId},
      );
      // Optionally, log the user out after initiating deactivation
      // await logout();

    } catch (e, st) {
      // Catch errors related to finding the user or potentially calling other services
      Error.throwWithStackTrace(Debug.parseException(e), st);
    }
  }

  /// Deletes the currently authenticated user's account from Firebase Authentication.
  ///
  /// **Warning:** This action is permanent and irreversible.
  /// It often requires the user to have recently signed in due to security reasons.
  /// Throws an exception if no user is signed in, if re-authentication is required,
  /// or if any other error occurs during deletion.
  Future<void> deleteUser() async {
    final user = _auth.currentUser;
    if (user == null) {
      Error.throwWithStackTrace(AuthSessionFailure(reason: 'Cannot delete user: No user is currently signed in.'), StackTrace.current);
    }

    final userId = user.uid;
    final maskedEmail = CoreFormatter.maskEmail(user.email);
    Debug.logWarning(
      'Attempting to permanently delete user: $userId ($maskedEmail)',
      verbosity: Verbosity.verbose,
      metadata: {'userId': userId},
    );

    try {
      await user.delete();
      Debug.logInfo(
        'User account deleted successfully from Firebase Auth: $userId',
        verbosity: Verbosity.verbose,
        metadata: {'userId': userId},
      );
      // TODO: Consider adding logic here or in a backend function (triggered by auth deletion)
      // to delete associated user data from Firestore/Database/Storage.

    } on FirebaseAuthException catch (e, st) {
      Error.throwWithStackTrace(Debug.parseException(e), st);
    } catch (e, st) {
      Error.throwWithStackTrace(Debug.parseException(e), st);
    }
  }
}
