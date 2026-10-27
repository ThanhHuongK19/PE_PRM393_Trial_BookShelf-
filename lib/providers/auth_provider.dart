import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  AuthProvider({AuthService? authService})
    : _authService = authService ?? AuthService() {
    user = _authService.currentUser;
    _subscription = _authService.authStateChanges.listen(
      (user) {
        this.user = user;
        isInitializing = false;
        notifyListeners();
      },
      onError: (_) {
        isInitializing = false;
        notifyListeners();
      },
    );
  }

  final AuthService _authService;
  late final StreamSubscription<User?> _subscription;

  User? user;
  bool isInitializing = true;
  bool isBusy = false;
  String? _pendingSuccessMessage;

  bool get isSignedIn => user != null;

  Future<void> signIn({required String email, required String password}) {
    return _run(() async {
      await _authService.signIn(email: email, password: password);
    });
  }

  Future<void> register({
    required String email,
    required String password,
  }) async {
    await _run(() async {
      await _authService.register(email: email, password: password);
    });
    _pendingSuccessMessage = 'Registration successful';
    notifyListeners();
  }

  String? takePendingSuccessMessage() {
    final message = _pendingSuccessMessage;
    _pendingSuccessMessage = null;
    return message;
  }

  Future<void> sendPasswordResetEmail(String email) {
    return _run(() async {
      await _authService.sendPasswordResetEmail(email);
    });
  }

  Future<void> signOut() => _run(() => _authService.signOut());

  Future<void> _run(Future<void> Function() action) async {
    isBusy = true;
    notifyListeners();
    try {
      await action();
    } finally {
      isBusy = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
