import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../auth/auth_controller.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({
    super.key,
    this.onLoggedIn,
    this.onGoRegister,
    this.onGoForgot,
  });

  final VoidCallback? onLoggedIn;
  final VoidCallback? onGoRegister;
  final VoidCallback? onGoForgot;

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailC = TextEditingController();
  final _passC = TextEditingController();

  bool _obscure = true;
  String? _error;

  @override
  void dispose() {
    _emailC.dispose();
    _passC.dispose();
    super.dispose();
  }

  String? _emailValidator(String? v) {
    final s = v?.trim() ?? '';
    if (s.isEmpty) return 'Please enter your email';
    final ok = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(s);
    if (!ok) return 'Enter a valid email address';
    return null;
  }

  String? _passValidator(String? v) {
    final s = v ?? '';
    if (s.length < 6) return 'Password must be at least 6 characters';
    return null;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _error = null);
    final auth = context.read<AuthController>();

    try {
      final ok = await auth.login(_emailC.text.trim(), _passC.text);
      if (ok) {
        widget.onLoggedIn?.call();
      } else {
        setState(() => _error = 'Invalid email or password.');
      }
    } catch (e) {
      final msg = e.toString();
      if (msg.contains('Email not verified')) {
        setState(() => _error = 'Please verify your email. Check your inbox.');
      } else if (msg.contains('locked')) {
        setState(() => _error = 'Account temporarily locked. Please try again later.');
      } else {
        setState(() => _error = 'Something went wrong. Please try again.');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    return Scaffold(
      appBar: AppBar(title: const Text('Sign in')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Title
                  Text(
                    'Welcome back',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 16),

                  // email
                  TextFormField(
                    controller: _emailC,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      hintText: 'you@example.com',
                    ),
                    keyboardType: TextInputType.emailAddress,
                    autofillHints: const [AutofillHints.email, AutofillHints.username],
                    validator: _emailValidator,
                  ),
                  const SizedBox(height: 12),

                  // password
                  TextFormField(
                    controller: _passC,
                    obscureText: _obscure,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      suffixIcon: IconButton(
                        onPressed: () => setState(() => _obscure = !_obscure),
                        icon: Icon(_obscure ? Icons.visibility : Icons.visibility_off),
                        tooltip: _obscure ? 'Show password' : 'Hide password',
                      ),
                    ),
                    autofillHints: const [AutofillHints.password],
                    validator: _passValidator,
                    onFieldSubmitted: (_) => _submit(),
                  ),
                  const SizedBox(height: 16),

                  if (_error != null) ...[
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(_error!, style: const TextStyle(color: Colors.red)),
                    ),
                    // extra actions when email is not verified
                    if (_error!.startsWith('Please verify')) Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        TextButton(
                          onPressed: auth.busy ? null : () async {
                            try {
                              await context.read<AuthController>().resendVerificationEmail();
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Verification email sent again.')),
                                );
                              }
                            } catch (_) {}
                          },
                          child: const Text('Resend email'),
                        ),
                        TextButton(
                          onPressed: auth.busy ? null : () async {
                            try {
                              final ok = await context.read<AuthController>().refreshEmailVerified();
                              if (ok) {
                                widget.onLoggedIn?.call();
                              } else {
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Not verified yet.')),
                                  );
                                }
                              }
                            } catch (_) {}
                          },
                          child: const Text("I've verified"),
                        ),
                      ],
                    ),
                  ],

                  // sign in button
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: auth.busy ? null : _submit,
                      child: auth.busy
                          ? const SizedBox(
                              height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Text('Sign in'),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // divider
                  Row(children: const [
                    Expanded(child: Divider()),
                    Padding(padding: EdgeInsets.symmetric(horizontal: 8), child: Text('or')),
                    Expanded(child: Divider()),
                  ]),
                  const SizedBox(height: 12),

                  // google sign-in
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.g_mobiledata, size: 24),
                      label: const Text('Continue with Google'),
                      onPressed: auth.busy ? null : () async {
                        setState(() => _error = null);
                        final ok = await context.read<AuthController>().google();
                        if (ok) {
                          widget.onLoggedIn?.call();
                        } else {
                          // user cancelled or popup closed
                        }
                      },
                    ),
                  ),

                  // bottom links
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton(
                        onPressed: widget.onGoForgot,
                        child: const Text('Forgot password?'),
                      ),
                      TextButton(
                        onPressed: widget.onGoRegister,
                        child: const Text('Create account'),
                      ),
                    ],
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
