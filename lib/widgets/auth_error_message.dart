import 'package:firebase_auth/firebase_auth.dart';

String authErrorMessage(Object error) {
  if (error is! FirebaseAuthException) {
    return 'Something went wrong. Please try again.';
  }

  return switch (error.code) {
    'invalid-email' => 'That email address is not valid.',
    'user-disabled' => 'This account has been disabled.',
    'user-not-found' || 'wrong-password' || 'invalid-credential' =>
      'Email or password is incorrect.',
    'email-already-in-use' => 'An account already exists for that email.',
    'weak-password' => 'Choose a stronger password.',
    'too-many-requests' => 'Too many attempts. Please try again later.',
    'network-request-failed' => 'Check your internet connection and try again.',
    _ => error.message ?? 'Authentication failed. Please try again.',
  };
}
