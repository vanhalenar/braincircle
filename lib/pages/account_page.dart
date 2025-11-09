import 'package:brain_circle/auth/auth_controller.dart';
import 'package:brain_circle/auth/auth_gate.dart';
import 'package:brain_circle/homepage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class AccountPage extends StatefulWidget {
  const AccountPage({super.key});

  @override
  State<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameC = TextEditingController();

  DateTime? _dob;
  bool _loading = true;
  String? _genderText;
  DateTime? _consentAt;

  String? _error;
  bool _saving = false;

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

  Future<void> _loadProfile() async {
    final auth = context.read<AuthController>();
    try {
      final profile = await auth.loadProfile();
      final user = FirebaseAuth.instance.currentUser;

      if (profile != null) {
        _nameC.text = (profile['displayName'] as String?) ?? (user?.displayName ?? '');
        final bd = profile['birthDate'] as int?;
        if (bd != null) {
          _dob = DateTime.fromMillisecondsSinceEpoch(bd);
        }
        _genderText = profile['gender'] as String?;
        final ca = profile['consentAt'] as int?;
        if (ca != null) {
          _consentAt = DateTime.fromMillisecondsSinceEpoch(ca);
        }
      } else {
        _nameC.text = FirebaseAuth.instance.currentUser?.displayName ?? '';
      }
    } catch (_) {
      _error = 'Could not load profile.';
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
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

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      await context.read<AuthController>().updateProfile(
            displayName: _nameC.text.trim().isEmpty ? null : _nameC.text.trim(),
            birthDate: _dob,
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated.')),
        );
      }
    } catch (_) {
      setState(() => _error = 'Could not save changes.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _sendPasswordReset() async {
    final email = FirebaseAuth.instance.currentUser?.email;
    if (email == null) return;

    try {
      await context.read<AuthController>().sendPasswordReset(email);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Password reset email sent to $email')),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not send reset email.')),
        );
      }
    }
  }

  Future<void> _deleteAccount() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete account'),
        content: const Text(
          'This will permanently delete your account and data. '
          'Are you sure?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await context.read<AuthController>().deleteAccount();
      if (!mounted) return;

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => const AuthGate(home: Homepage()),
        ),
        (_) => false,
      );
    } catch (e) {
      // Typical case: requires-recent-login
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not delete account. Try signing in again first.'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final email = user?.email ?? 'Unknown user';
    final auth = context.watch<AuthController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Account'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: ListView(
                  children: [
                    Row(
                      children: [
                        const CircleAvatar(
                          radius: 28,
                          child: Icon(Icons.person, size: 32),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                email,
                                style: Theme.of(context).textTheme.titleMedium,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Signed in',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    TextFormField(
                      controller: _nameC,
                      decoration: const InputDecoration(
                        labelText: 'Name',
                      ),
                    ),
                    const SizedBox(height: 12),

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
                                ? 'Tap to select'
                                : '${_dob!.year}-${_dob!.month.toString().padLeft(2, '0')}-${_dob!.day.toString().padLeft(2, '0')}',
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    if (_genderText != null) ...[
                      Text(
                        'Gender: $_genderText',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 8),
                    ],
                    if (_consentAt != null) ...[
                      Text(
                        'Consents accepted: '
                        '${_consentAt!.year}-${_consentAt!.month.toString().padLeft(2, '0')}-${_consentAt!.day.toString().padLeft(2, '0')}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 8),
                    ],

                    if (_error != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        _error!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ],

                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: auth.busy || _saving ? null : _save,
                        child: auth.busy || _saving
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Text('Save changes'),
                      ),
                    ),

                    const SizedBox(height: 24),
                    const Divider(),
                    const SizedBox(height: 12),

                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.lock_reset),
                      title: const Text('Change password'),
                      subtitle: const Text('Send a password reset email'),
                      onTap: _sendPasswordReset,
                    ),

                    const SizedBox(height: 12),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.delete_forever, color: Colors.red),
                      title: const Text('Delete account'),
                      subtitle: const Text('This cannot be undone'),
                      onTap: _deleteAccount,
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
