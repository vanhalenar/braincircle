import 'dart:convert';
import 'dart:math';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_sign_in/google_sign_in.dart';

class FirebaseAuthRepository {
  FirebaseAuthRepository({
    this.maxAttempts = 5,
    this.lockoutMinutes = 5,
  });

  final int maxAttempts;
  final int lockoutMinutes;

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final _secure = const FlutterSecureStorage();

  Future<Map<String, dynamic>> _readJson(String key) async {
    final sp = await SharedPreferences.getInstance();
    final raw = sp.getString(key);
    if (raw == null || raw.isEmpty) return {};
    return jsonDecode(raw) as Map<String, dynamic>;
  }

  Future<void> _writeJson(String key, Map<String, dynamic> value) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setString(key, jsonEncode(value));
  }

  Future<Map<String, dynamic>> _readProfiles() => _readJson('profiles');
  Future<void> _writeProfiles(Map<String, dynamic> map) => _writeJson('profiles', map);

  Future<Map<String, dynamic>> _readLockout() => _readJson('lockout');
  Future<void> _writeLockout(Map<String, dynamic> map) => _writeJson('lockout', map);

  String _newToken() => const Uuid().v4();

  Future<bool> signInWithGoogle() async {
    try {
      UserCredential? cred;

      if (kIsWeb) {
        final provider = GoogleAuthProvider()
          ..addScope('email')
          ..addScope('profile');
        cred = await _auth.signInWithPopup(provider);
      } else {
        final googleSignIn = GoogleSignIn(
          scopes: const ['email', 'profile'],
        );

        final googleUser = await googleSignIn.signIn();
        if (googleUser == null) {
          return false;
        }

        final googleAuth = await googleUser.authentication;
        final oAuthCred = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );

        cred = await _auth.signInWithCredential(oAuthCred);
      }

      if (cred == null) return false;

      final email = cred.user?.email ?? '';
      await _secure.write(key: 'session_token', value: _newToken());
      await _secure.write(key: 'session_email', value: email);

      final profiles = await _readProfiles();
      profiles[email] ??= {
        'displayName': cred.user?.displayName,
        'birthDate': null,
        'gender': null,
        'consentAt': DateTime.now().millisecondsSinceEpoch,
      };
      await _writeProfiles(profiles);

      return true;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'popup-closed-by-user') return false;
      rethrow;
    }
  }

  Future<void> register(
    String email,
    String password, {
    String? name,
    DateTime? birthDate,
    String? gender,
    required bool consentAccepted,
  }) async {
    if (!consentAccepted) throw Exception('You must accept Terms & Privacy.');

    if (birthDate != null) {
      final thirteen = DateTime.now().subtract(const Duration(days: 365 * 13 + 3));
      if (birthDate.isAfter(thirteen)) {
        throw Exception('You must be at least 13 years old.');
      }
    }

    final cred = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    await cred.user?.sendEmailVerification();

    final profiles = await _readProfiles();
    profiles[email] = {
      'displayName': name,
      'birthDate': birthDate?.millisecondsSinceEpoch,
      'gender': gender,
      'consentAt': DateTime.now().millisecondsSinceEpoch,
    };
    await _writeProfiles(profiles);

  }

  Future<bool> login(String email, String password) async {
    final lock = await _readLockout();
    final info = lock[email] as Map<String, dynamic>?;
    if (info != null && info['until'] != null) {
      final until = DateTime.fromMillisecondsSinceEpoch(info['until'] as int);
      if (until.isAfter(DateTime.now())) {
        throw Exception('Account locked until $until');
      }
    }

    try {
      final cred = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      await cred.user?.reload();
      final verified = _auth.currentUser?.emailVerified ?? false;
      if (!verified) {
        throw EmailNotVerifiedException(email);
      }

      final updated = {...?lock[email] as Map<String, dynamic>?};
      updated['failed'] = 0;
      updated['until'] = null;
      lock[email] = updated;
      await _writeLockout(lock);

      await _secure.write(key: 'session_token', value: _newToken());
      await _secure.write(key: 'session_email', value: email);
      return true;
    } on FirebaseAuthException catch (e) {
      final m = {...?lock[email] as Map<String, dynamic>?};
      final failed = (m['failed'] ?? 0) as int;
      final next = failed + 1;
      if (next >= maxAttempts) {
        m['failed'] = 0;
        m['until'] = DateTime.now()
            .add(Duration(minutes: lockoutMinutes))
            .millisecondsSinceEpoch;
      } else {
        m['failed'] = next;
      }
      lock[email] = m;
      await _writeLockout(lock);

      if (e.code == 'user-not-found' || e.code == 'wrong-password') {
        return false;
      }
      rethrow;
    }
  }

  Future<void> logout() async {
    await _auth.signOut();
    await _secure.delete(key: 'session_token');
    await _secure.delete(key: 'session_email');
  }

  Future<bool> isLoggedIn() async => _auth.currentUser != null;

  Future<void> resendVerificationEmail() async {
    final u = _auth.currentUser;
    if (u != null && !u.emailVerified) {
      await u.sendEmailVerification();
    }
  }

  Future<bool> refreshEmailVerified() async {
    final u = _auth.currentUser;
    await u?.reload();
    return u?.emailVerified ?? false;
  }

  Future<void> sendPasswordReset(String email) =>
      _auth.sendPasswordResetEmail(email: email);

  String _genRecoveryCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final r = Random.secure();
    return List.generate(8, (_) => chars[r.nextInt(chars.length)]).join();
  }
}

class EmailNotVerifiedException implements Exception {
  final String email;
  EmailNotVerifiedException(this.email);
  @override
  String toString() => 'Email not verified for $email';
}
