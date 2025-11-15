import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../auth/auth_controller.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key, this.onDone});
  final VoidCallback? onDone;

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameC = TextEditingController();
  final _emailC = TextEditingController();
  final _passC = TextEditingController();
  final _selfDescribeC = TextEditingController();

  DateTime? _dob;

  String? _gender; // female | male | non_binary | prefer_not | self
  bool _showSelfDescribe = false;
  bool _consent = false;

  bool _obscure = true;
  bool _success = false;
  bool _submitted = false; // <-- track if "Create account" was pressed
  String? _error;

  @override
  void dispose() {
    _nameC.dispose();
    _emailC.dispose();
    _passC.dispose();
    _selfDescribeC.dispose();
    super.dispose();
  }

  String? _emailValidator(String? v) {
    if (!_submitted) return null; // no error before first submit
    final s = v?.trim() ?? '';
    if (s.isEmpty) return 'Please enter your email';
    final ok = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(s);
    if (!ok) return 'Enter a valid email address';
    return null;
  }

  String? _passwordValidator(String? v) {
    if (!_submitted) return null;
    final s = v ?? '';
    if (s.length < 6) return 'Password must be at least 6 characters';
    return null;
  }

  String? _dobValidator() {
    if (!_submitted) return null;
    if (_dob == null) return 'Please select your date of birth';
    final thirteen =
        DateTime.now().subtract(const Duration(days: 365 * 13 + 3));
    if (_dob!.isAfter(thirteen)) return 'You must be at least 13 years old';
    return null;
  }

  String? _genderValidator(String? _) {
    if (!_submitted) return null;
    if (_gender == null) return 'Please choose your gender';
    if (_gender == 'self' && _selfDescribeC.text.trim().isEmpty) {
      return 'Please describe your gender';
    }
    return null;
  }

  String _deriveGender() =>
      _gender == 'self' ? 'self:${_selfDescribeC.text.trim()}' : _gender!;

  String _passwordHint(String v) {
    if (v.length >= 12) return 'Strong password';
    if (v.length >= 8) return 'Fair password';
    return 'Weak password';
  }

  Future<void> _pickDob() async {
    final now = DateTime.now();
    final initial = DateTime(now.year - 20, now.month, now.day);
    final first = DateTime(now.year - 100);
    final last = now;
    final picked = await showDatePicker(
      context: context,
      initialDate: _dob ?? initial,
      firstDate: first,
      lastDate: last,
    );
    if (picked != null) setState(() => _dob = picked);
  }

  Future<void> _submit() async {
    setState(() {
      _submitted = true; // from now on, show validation errors
      _error = null;
    });

    if (!_formKey.currentState!.validate()) return;

    if (!_consent) {
      setState(() => _error = 'Please accept the Terms & Privacy.');
      return;
    }

    try {
      await context.read<AuthController>().register(
            _emailC.text.trim(),
            _passC.text,
            name: _nameC.text.trim().isEmpty ? null : _nameC.text.trim(),
            birthDate: _dob,
            gender: _deriveGender(),
            consentAccepted: _consent,
          );
      setState(() => _success = true);
    } catch (e) {
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();

    return Scaffold(
      appBar: AppBar(title: const Text('Create account')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: _success
                ? Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.check_circle, size: 64),
                      const SizedBox(height: 12),
                      Text(
                        'Account created!',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'We sent a verification email to ${_emailC.text.trim()}.\nVerify your email to sign in.',
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: widget.onDone,
                        child: const Text('Back to sign in'),
                      ),
                    ],
                  )
                : Form(
                    key: _formKey,
                    // only auto-validate after first submit
                    autovalidateMode: _submitted
                        ? AutovalidateMode.always
                        : AutovalidateMode.disabled,
                    child: ListView(
                      shrinkWrap: true,
                      children: [
                        Text(
                          'Let’s get you started',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 16),

                        TextFormField(
                          controller: _nameC,
                          decoration: const InputDecoration(
                            labelText: 'Full name',
                            hintText: 'Jane Doe',
                          ),
                          textCapitalization: TextCapitalization.words,
                        ),
                        const SizedBox(height: 12),

                        // DOB
                        InputDecorator(
                          decoration: InputDecoration(
                            labelText: 'Date of birth',
                            errorText: _dobValidator(),
                          ),
                          child: InkWell(
                            onTap: _pickDob,
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 12),
                              child: Text(
                                _dob == null
                                    ? 'Select date'
                                    : '${_dob!.year}-${_dob!.month.toString().padLeft(2, '0')}-${_dob!.day.toString().padLeft(2, '0')}',
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),

                        TextFormField(
                          controller: _emailC,
                          decoration: const InputDecoration(
                            labelText: 'Email',
                            hintText: 'you@example.com',
                          ),
                          keyboardType: TextInputType.emailAddress,
                          autofillHints: const [AutofillHints.email],
                          validator: _emailValidator,
                        ),
                        const SizedBox(height: 12),

                        TextFormField(
                          controller: _passC,
                          obscureText: _obscure,
                          decoration: InputDecoration(
                            labelText: 'Password',
                            suffixIcon: IconButton(
                              onPressed: () =>
                                  setState(() => _obscure = !_obscure),
                              icon: Icon(_obscure
                                  ? Icons.visibility
                                  : Icons.visibility_off),
                              tooltip:
                                  _obscure ? 'Show password' : 'Hide password',
                            ),
                          ),
                          validator: _passwordValidator,
                          onChanged: (_) => setState(() {}),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            _passwordHint(_passC.text),
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                        const SizedBox(height: 12),

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
                            DropdownMenuItem(
                              value: 'self',
                              child: Text('Self-describe'),
                            ),
                          ],
                          onChanged: (v) {
                            setState(() {
                              _gender = v;
                              _showSelfDescribe = v == 'self';
                            });
                          },
                          validator: _genderValidator,
                        ),
                        if (_showSelfDescribe) ...[
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _selfDescribeC,
                            decoration: const InputDecoration(
                              labelText: 'Describe your gender',
                            ),
                            validator: (v) {
                              if (!_submitted) return null;
                              if (_gender == 'self' &&
                                  (v?.trim().isEmpty ?? true)) {
                                return 'Please describe your gender';
                              }
                              return null;
                            },
                          ),
                        ],
                        const SizedBox(height: 12),

                        CheckboxListTile(
                          value: _consent,
                          onChanged: (v) =>
                              setState(() => _consent = v ?? false),
                          title: const Text(
                            'I accept the Terms of Service and Privacy Policy',
                          ),
                          controlAffinity: ListTileControlAffinity.leading,
                          contentPadding: EdgeInsets.zero,
                        ),

                        if (_error != null) ...[
                          const SizedBox(height: 6),
                          Text(
                            _error!,
                            style: const TextStyle(color: Colors.red),
                          ),
                        ],

                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: auth.busy ? null : _submit,
                            child: auth.busy
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text('Create account'),
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
