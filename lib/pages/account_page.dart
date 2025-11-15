import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:brain_circle/auth/auth_controller.dart';
import 'package:brain_circle/auth/auth_gate.dart';
import 'package:brain_circle/homepage.dart';

class AccountPage extends StatefulWidget {
  const AccountPage({super.key});

  @override
  State<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  final _nameC = TextEditingController();

  DateTime? _dob;
  String? _gender; // female | male | non_binary | prefer_not
  bool _loading = true;
  bool _savingProfile = false;
  bool _sendingResetLink = false;
  bool _deleting = false;

  String? _error;
  String? _info;

  User? get _user => FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _nameC.dispose();
    super.dispose();
  }

  Future<Map<String, dynamic>> _readProfiles() async {
    final sp = await SharedPreferences.getInstance();
    final raw = sp.getString('profiles');
    if (raw == null || raw.isEmpty) return {};
    return jsonDecode(raw) as Map<String, dynamic>;
  }

  Future<void> _writeProfiles(Map<String, dynamic> map) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setString('profiles', jsonEncode(map));
  }

  Future<void> _loadProfile() async {
    final user = _user;
    if (user == null) {
      setState(() {
        _error = 'No logged in user.';
        _loading = false;
      });
      return;
    }

    try {
      final email = user.email ?? '';
      final profiles = await _readProfiles();
      final p = profiles[email] as Map<String, dynamic>?;

      final rawGender = p?['gender'] as String?;
      const allowedGenders = ['female', 'male', 'non_binary', 'prefer_not'];
      final normalizedGender =
          (rawGender != null && allowedGenders.contains(rawGender))
              ? rawGender
              : null;

      setState(() {
        _nameC.text =
            (p?['displayName'] as String?) ?? (user.displayName ?? '');

        final bdMs = p?['birthDate'] as int?;
        _dob = bdMs != null
            ? DateTime.fromMillisecondsSinceEpoch(bdMs)
            : null;

        _gender = normalizedGender;
        _loading = false;
        _error = null;
      });
    } catch (_) {
      setState(() {
        _loading = false;
        _error = 'Could not load profile.';
      });
    }
  }

  Future<void> _pickDob() async {
    final now = DateTime.now();
    final initial = _dob ?? DateTime(now.year - 20, now.month, now.day);
    final first = DateTime(now.year - 100);
    final last = now;

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: first,
      lastDate: last,
    );
    if (picked != null) {
      setState(() => _dob = picked);
    }
  }

  Future<void> _saveProfile() async {
    final user = _user;
    if (user == null) return;

    setState(() {
      _savingProfile = true;
      _error = null;
      _info = null;
    });

    try {
      final email = user.email ?? '';
      final profiles = await _readProfiles();
      final existing = (profiles[email] as Map<String, dynamic>?) ?? {};

      profiles[email] = {
        ...existing,
        'displayName': _nameC.text.trim().isEmpty ? null : _nameC.text.trim(),
        'birthDate': _dob?.millisecondsSinceEpoch,
        'gender': _gender,
      };

      await _writeProfiles(profiles);

      if (_nameC.text.trim().isNotEmpty) {
        await user.updateDisplayName(_nameC.text.trim());
        await user.reload();
      }

      setState(() {
        _info = 'Profile updated.';
      });
    } catch (_) {
      setState(() {
        _error = 'Could not save profile. Please try again.';
      });
    } finally {
      if (mounted) {
        setState(() => _savingProfile = false);
      }
    }
  }

  Future<void> _sendPasswordResetLink() async {
    final email = _user?.email;
    if (email == null || email.isEmpty) {
      setState(() => _error = 'No email found for this account.');
      return;
    }

    setState(() {
      _sendingResetLink = true;
      _error = null;
      _info = null;
    });

    try {
      await context.read<AuthController>().sendPasswordReset(email);
      setState(() {
        _info = 'Password reset link sent to $email.';
      });
    } catch (_) {
      setState(() {
        _error = 'Could not send reset link. Please try again.';
      });
    } finally {
      if (mounted) {
        setState(() => _sendingResetLink = false);
      }
    }
  }

  Future<void> _deleteAccount() async {
    final user = _user;
    if (user == null) return;

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete account?'),
        content: const Text(
          'This will permanently delete your account and data on this device.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (ok != true) return;

    setState(() {
      _deleting = true;
      _error = null;
      _info = null;
    });

    try {
      final email = user.email ?? '';

      await user.delete();

      final profiles = await _readProfiles();
      profiles.remove(email);
      await _writeProfiles(profiles);

      await context.read<AuthController>().logout();
      if (!mounted) return;

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => const AuthGate(home: Homepage()),
        ),
        (_) => false,
      );
    } on FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
        setState(() => _error = 'Please sign in again to delete your account.');
      } else {
        setState(() => _error = 'Could not delete account. (${e.code})');
      }
    } catch (_) {
      setState(() => _error = 'Could not delete account. Please try again.');
    } finally {
      if (mounted) {
        setState(() => _deleting = false);
      }
    }
  }

  Future<void> _signOut() async {
    setState(() {
      _error = null;
      _info = null;
    });

    await context.read<AuthController>().logout();
    if (!mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => const AuthGate(home: Homepage()),
      ),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = _user;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Account'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : user == null
              ? const Center(child: Text('No logged in user.'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_error != null) ...[
                        Text(
                          _error!,
                          style: const TextStyle(color: Colors.red),
                        ),
                        const SizedBox(height: 8),
                      ],
                      if (_info != null) ...[
                        Text(
                          _info!,
                          style: const TextStyle(color: Colors.green),
                        ),
                        const SizedBox(height: 8),
                      ],

                      // Profile section
                      Text(
                        'Profile',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 12),
                      Text('Email: ${user.email ?? '-'}'),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _nameC,
                        decoration: const InputDecoration(
                          labelText: 'Name',
                        ),
                      ),
                      const SizedBox(height: 8),
                      InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Date of birth',
                        ),
                        child: InkWell(
                          onTap: _pickDob,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            child: Text(
                              _dob == null
                                  ? 'Not set'
                                  : '${_dob!.year}-${_dob!.month.toString().padLeft(2, '0')}-${_dob!.day.toString().padLeft(2, '0')}',
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        decoration:
                            const InputDecoration(labelText: 'Gender'),
                        value: _gender,
                        items: const [
                          DropdownMenuItem(
                            value: 'female',
                            child: Text('Female'),
                          ),
                          DropdownMenuItem(
                            value: 'male',
                            child: Text('Male'),
                          ),
                          DropdownMenuItem(
                            value: 'non_binary',
                            child: Text('Non-binary'),
                          ),
                          DropdownMenuItem(
                            value: 'prefer_not',
                            child: Text('Prefer not to say'),
                          ),
                        ],
                        onChanged: (v) => setState(() => _gender = v),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _savingProfile ? null : _saveProfile,
                          child: _savingProfile
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text('Save profile'),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Password reset link section
                      Text(
                        'Password',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'We’ll email you a link to change your password.',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: _sendingResetLink
                              ? null
                              : _sendPasswordResetLink,
                          child: _sendingResetLink
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text('Send reset link'),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Sign out / delete
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.logout),
                          label: const Text('Sign out'),
                          onPressed: _signOut,
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                          ),
                          onPressed: _deleting ? null : _deleteAccount,
                          child: _deleting
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text('Delete account'),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }
}
