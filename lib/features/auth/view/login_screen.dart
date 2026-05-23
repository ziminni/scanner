import 'package:flutter/material.dart';

import '../../../core/services/app_controller.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _obscured = true;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'School Attendance Monitoring',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Sign in with your assigned administrator or scanner account.',
                  ),
                  const SizedBox(height: 28),
                  TextFormField(
                    controller: _email,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      prefixIcon: Icon(Icons.mail_outline),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) => value == null || !value.contains('@')
                        ? 'Enter a valid email.'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _password,
                    obscureText: _obscured,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscured
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                        onPressed: () => setState(() => _obscured = !_obscured),
                      ),
                    ),
                    validator: (value) => value == null || value.length < 6
                        ? 'Password must be at least 6 characters.'
                        : null,
                  ),
                  if (app.authError != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      app.authError!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                  FilledButton.icon(
                    icon: app.loading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.login),
                    label: const Text('Login'),
                    onPressed: app.loading
                        ? null
                        : () async {
                            if (!_formKey.currentState!.validate()) return;
                            try {
                              await app.login(_email.text, _password.text);
                            } catch (_) {}
                          },
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
