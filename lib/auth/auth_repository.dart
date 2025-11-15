import 'dart:convert';
import 'dart:math';

import 'package:bcrypt/bcrypt.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

class LocalUser {
  final String id;
  final String email;
  final String? displayName;
  final String passwordHash;     // bcrypt
  final String recoveryHash;     // bcrypt (8-char recovery code)
  final int failed;              // failed login attempts
  final DateTime? lockoutUntil;  // temporary lock

  final DateTime? birthDate;
  final String? gender;          // female male non_binary prefer_not self-text
  final DateTime? consentAt;     // when Terms were accepted

  const LocalUser({
    required this.id,
    required this.email,
    this.displayName,
    required this.passwordHash,
    required this.recoveryHash,
    this.failed = 0,
    this.lockoutUntil,
    this.birthDate,
    this.gender,
    this.consentAt,
  });

  LocalUser copyWith({
    String? id,
    String? email,
    String? displayName,
    String? passwordHash,
    String? recoveryHash,
    int? failed,
    DateTime? lockoutUntil,
    DateTime? birthDate,
    String? gender,
    DateTime? consentAt,
  }) {
    return LocalUser(
      id: id ?? this.id,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      passwordHash: passwordHash ?? this.passwordHash,
      recoveryHash: recoveryHash ?? this.recoveryHash,
      failed: failed ?? this.failed,
      lockoutUntil: lockoutUntil ?? this.lockoutUntil,
      birthDate: birthDate ?? this.birthDate,
      gender: gender ?? this.gender,
      consentAt: consentAt ?? this.consentAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'displayName': displayName,
        'passwordHash': passwordHash,
        'recoveryHash': recoveryHash,
        'failed': failed,
        'lockoutUntil': lockoutUntil?.millisecondsSinceEpoch,
        'birthDate': birthDate?.millisecondsSinceEpoch,
        'gender': gender,
        'consentAt': consentAt?.millisecondsSinceEpoch,
      };

  factory LocalUser.fromJson(Map<String, dynamic> j) => LocalUser(
        id: j['id'] as String,
        email: j['email'] as String,
        displayName: j['displayName'] as String?,
        passwordHash: j['passwordHash'] as String,
        recoveryHash: j['recoveryHash'] as String,
        failed: (j['failed'] ?? 0) as int,
        lockoutUntil: j['lockoutUntil'] == null
            ? null
            : DateTime.fromMillisecondsSinceEpoch(j['lockoutUntil'] as int),
        birthDate: j['birthDate'] == null
            ? null
            : DateTime.fromMillisecondsSinceEpoch(j['birthDate'] as int),
        gender: j['gender'] as String?,
        consentAt: j['consentAt'] == null
            ? null
            : DateTime.fromMillisecondsSinceEpoch(j['consentAt'] as int),
      );
}

class AuthRepository {
  AuthRepository({this.maxAttempts = 5, this.lockoutMinutes = 5});

  final int maxAttempts;
  final int lockoutMinutes;
  final _secure = const FlutterSecureStorage();

  String _hash(String v) => BCrypt.hashpw(v, BCrypt.gensalt());
  bool _verify(String v, String h) => BCrypt.checkpw(v, h);
  String _token() => const Uuid().v4();

  Future<Map<String, LocalUser>> _readUsers() async {
    final sp = await SharedPreferences.getInstance();
    final raw = sp.getString('users') ?? '{}';
    final map = jsonDecode(raw) as Map<String, dynamic>;
    return map.map((k, v) => MapEntry(k, LocalUser.fromJson(v as Map<String, dynamic>)));
  }

  Future<void> _writeUsers(Map<String, LocalUser> users) async {
    final sp = await SharedPreferences.getInstance();
    final jsonMap = users.map((k, v) => MapEntry(k, v.toJson()));
    await sp.setString('users', jsonEncode(jsonMap));
  }

  Future<String> register(
    String email,
    String password, {
    String? name,
    DateTime? birthDate,
    String? gender,
    required bool consentAccepted,
  }) async {

    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
      throw Exception('Invalid email.');
    }
    if (password.length < 6) {
      throw Exception('Password must be at least 6 characters.');
    }
    if (!consentAccepted) {
      throw Exception('You must accept Terms & Privacy.');
    }

    if (birthDate != null) {
      final thirteen = DateTime.now().subtract(const Duration(days: 365 * 13 + 3));
      if (birthDate.isAfter(thirteen)) {
        throw Exception('You must be at least 13 years old.');
      }
    }

    final users = await _readUsers();
    if (users.containsKey(email)) {
      throw Exception('This email already exists.');
    }

    final recovery = _genRecoveryCode();
    users[email] = LocalUser(
      id: const Uuid().v4(),
      email: email,
      displayName: name,
      passwordHash: _hash(password),
      recoveryHash: _hash(recovery),
      birthDate: birthDate,
      gender: gender,
      consentAt: DateTime.now(),
    );
    await _writeUsers(users);
    return recovery;
  }

  Future<bool> login(String email, String password) async {
    final users = await _readUsers();
    if (!users.containsKey(email)) return false;

    var u = users[email]!;
    if (u.lockoutUntil != null && u.lockoutUntil!.isAfter(DateTime.now())) {
      throw Exception('Account locked until ${u.lockoutUntil}');
    }

    final ok = _verify(password, u.passwordHash);
    if (!ok) {
      final failed = u.failed + 1;
      final lock = failed >= maxAttempts
          ? DateTime.now().add(Duration(minutes: lockoutMinutes))
          : null;
      u = u.copyWith(failed: lock == null ? failed : 0, lockoutUntil: lock);
      users[email] = u;
      await _writeUsers(users);
      return false;
    }

    u = u.copyWith(failed: 0, lockoutUntil: null);
    users[email] = u;
    await _writeUsers(users);

    await _secure.write(key: 'session_token', value: _token());
    await _secure.write(key: 'session_email', value: email);
    return true;
  }

  Future<void> logout() async {
    await _secure.delete(key: 'session_token');
    await _secure.delete(key: 'session_email');
  }

  Future<bool> isLoggedIn() async =>
      (await _secure.read(key: 'session_token')) != null;

  Future<bool> resetPassword(String email, String recoveryCode, String newPass) async {
    final users = await _readUsers();
    if (!users.containsKey(email)) return false;

    var u = users[email]!;
    if (!_verify(recoveryCode, u.recoveryHash)) return false;

    u = u.copyWith(passwordHash: _hash(newPass));
    users[email] = u;
    await _writeUsers(users);
    return true;
  }

  String _genRecoveryCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final r = Random.secure();
    return List.generate(8, (_) => chars[r.nextInt(chars.length)]).join();
  }
}
