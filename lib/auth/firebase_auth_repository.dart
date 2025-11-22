import 'dart:convert';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_sign_in/google_sign_in.dart';

class FirebaseAuthRepository {
  FirebaseAuthRepository({this.maxAttempts = 5, this.lockoutMinutes = 5});

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
  Future<void> _writeProfiles(Map<String, dynamic> map) =>
      _writeJson('profiles', map);

  Future<Map<String, dynamic>> _readLockout() => _readJson('lockout');
  Future<void> _writeLockout(Map<String, dynamic> map) =>
      _writeJson('lockout', map);

  String _newToken() => const Uuid().v4();

  Future<bool> signInWithGoogle() async {
    try {
      UserCredential? cred;

      if (kIsWeb) {
        // Web: Firebase popup
        final provider = GoogleAuthProvider()
          ..addScope('email')
          ..addScope('profile');
        cred = await _auth.signInWithPopup(provider);
      } else {
        // Mobile/desktop: google_sign_in v7 style
        final signIn = GoogleSignIn.instance;

        await signIn.initialize();
        await signIn.signOut(); // optional: force account picker

        final account = await signIn.authenticate(
          scopeHint: const ['email', 'profile'],
        );

        // v7: authentication is sync and only has idToken
        final googleAuth = account.authentication;

        final oAuthCred = GoogleAuthProvider.credential(
          idToken: googleAuth.idToken,
          // no accessToken here in v7
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
      final thirteen = DateTime.now().subtract(
        const Duration(days: 365 * 13 + 3),
      );
      if (birthDate.isAfter(thirteen)) {
        throw Exception('You must be at least 13 years old.');
      }
    }

    final cred = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    await cred.user?.sendEmailVerification();
    final uid = cred.user!.uid;

    await FirebaseFirestore.instance.collection('users').doc(uid).set({
      'name': name,
      'friends': [],
      'studying': false,
    });

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

  Future<Map<String, dynamic>?> getCurrentProfile() async {
    final user = _auth.currentUser;
    final email = user?.email;
    if (email == null) return null;

    final profiles = await _readProfiles();
    final raw = profiles[email];
    if (raw is Map<String, dynamic>) return raw;
    return null;
  }

  Future<void> updateProfile({String? displayName, DateTime? birthDate}) async {
    final user = _auth.currentUser;
    final email = user?.email;
    if (email == null) return;

    // Update Firebase display name
    if (displayName != null && displayName.isNotEmpty) {
      await user!.updateDisplayName(displayName);
    }

    // Update local profile
    final profiles = await _readProfiles();
    final raw = (profiles[email] as Map<String, dynamic>?) ?? {};
    profiles[email] = {
      ...raw,
      if (displayName != null) 'displayName': displayName,
      if (birthDate != null) 'birthDate': birthDate.millisecondsSinceEpoch,
    };
    await _writeProfiles(profiles);
  }

  Future<void> deleteAccount() async {
    final user = _auth.currentUser;
    final email = user?.email;
    if (user == null || email == null) return;

    // Drop local profile + lockout info
    final profiles = await _readProfiles();
    profiles.remove(email);
    await _writeProfiles(profiles);

    final lockout = await _readLockout();
    lockout.remove(email);
    await _writeLockout(lockout);

    // Delete from Firebase + clear session
    await user.delete();
    await logout();
  }

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
