import 'package:flutter/foundation.dart';
import 'firebase_auth_repository.dart';

class AuthController extends ChangeNotifier {
  AuthController(this._repo);
  final FirebaseAuthRepository _repo;

  bool busy = false;

  // session
  Future<bool> isLoggedIn() => _repo.isLoggedIn();

  // email-password login
  Future<bool> login(String email, String pass) async {
    busy = true; notifyListeners();
    try {
      return await _repo.login(email, pass);
    } finally {
      busy = false; notifyListeners();
    }
  }

  // registration
  Future<void> register(
    String email,
    String pass, {
    String? name,
    DateTime? birthDate,
    String? gender,
    required bool consentAccepted,
  }) async {
    busy = true; notifyListeners();
    try {
      await _repo.register(
        email,
        pass,
        name: name,
        birthDate: birthDate,
        gender: gender,
        consentAccepted: consentAccepted,
      );
    } finally {
      busy = false; notifyListeners();
    }
  }

  // email verification helpers
  Future<void> resendVerificationEmail() => _repo.resendVerificationEmail();
  Future<bool> refreshEmailVerified() => _repo.refreshEmailVerified();

  // google sign in
  Future<bool> google() => _repo.signInWithGoogle();

  // password reset
  Future<void> sendPasswordReset(String email) => _repo.sendPasswordReset(email);
  Future<bool> reset(String email, String code, String newPass) async {
    await _repo.sendPasswordReset(email);
    return true;
  }

  // logout
  Future<void> logout() => _repo.logout();

    Future<Map<String, dynamic>?> loadProfile() => _repo.getCurrentProfile();

    Future<void> updateProfile({
      String? displayName,
      DateTime? birthDate,
    }) async {
      busy = true; notifyListeners();
      try {
        await _repo.updateProfile(
          displayName: displayName,
          birthDate: birthDate,
        );
      } finally {
        busy = false; notifyListeners();
      }
    }

    Future<void> deleteAccount() async {
      busy = true; notifyListeners();
      try {
        await _repo.deleteAccount();
      } finally {
        busy = false; notifyListeners();
      }
    }

}
