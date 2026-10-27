import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../validators/auth_validators.dart';
import '../../widgets/auth_error_message.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _hasSubmitted = false;
  String? _submitError;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _hasSubmitted = true;
      _submitError = null;
    });
    if (!_formKey.currentState!.validate()) return;
    try {
      await context.read<AuthProvider>().register(
        email: _emailController.text,
        password: _passwordController.text,
      );
    } catch (error) {
      if (mounted) setState(() => _submitError = authErrorMessage(error));
    }
  }

  void _clearSubmitError() {
    if (_submitError != null) setState(() => _submitError = null);
  }

  @override
  Widget build(BuildContext context) {
    final isBusy = context.watch<AuthProvider>().isBusy;
    return Scaffold(
      appBar: AppBar(title: const Text('Create account')),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(
                key: _formKey,
                autovalidateMode: _hasSubmitted
                    ? AutovalidateMode.onUserInteraction
                    : AutovalidateMode.disabled,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Join BookShelf',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 8),
                    const Text('Create an account with your email.'),
                    const SizedBox(height: 28),
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      autofillHints: const [AutofillHints.newUsername],
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (_) => _clearSubmitError(),
                      validator: AuthValidators.email,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: true,
                      autofillHints: const [AutofillHints.newPassword],
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Password',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (_) => _clearSubmitError(),
                      validator: AuthValidators.password,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _confirmPasswordController,
                      obscureText: true,
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _submit(),
                      decoration: const InputDecoration(
                        labelText: 'Confirm password',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (_) => _clearSubmitError(),
                      validator: (value) => AuthValidators.confirmPassword(
                        value,
                        _passwordController.text,
                      ),
                    ),
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: isBusy ? null : _submit,
                      child: isBusy
                          ? const SizedBox.square(
                              dimension: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Create account'),
                    ),
                    if (_submitError != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        _submitError!,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ],
                    TextButton(
                      onPressed: () => context.go('/sign-in'),
                      child: const Text('Already have an account? Sign in'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
