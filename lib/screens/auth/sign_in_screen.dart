import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../validators/auth_validators.dart';
import '../../widgets/auth_error_message.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _hasSubmitted = false;
  String? _submitError;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _hasSubmitted = true;
      _submitError = null;
    });
    if (!_formKey.currentState!.validate()) return;
    try {
      await context.read<AuthProvider>().signIn(
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
                    const Icon(Icons.menu_book_rounded, size: 56),
                    const SizedBox(height: 16),
                    Text(
                      'Welcome back',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Sign in to continue to BookShelf.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      autofillHints: const [AutofillHints.email],
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
                      autofillHints: const [AutofillHints.password],
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _submit(),
                      decoration: const InputDecoration(
                        labelText: 'Password',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (_) => _clearSubmitError(),
                      validator: AuthValidators.loginPassword,
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () => context.go('/forgot-password'),
                        child: const Text('Forgot password?'),
                      ),
                    ),
                    const SizedBox(height: 8),
                    FilledButton(
                      onPressed: isBusy ? null : _submit,
                      child: isBusy
                          ? const SizedBox.square(
                              dimension: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Sign in'),
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
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: () => context.go('/sign-up'),
                      child: const Text('Create an account'),
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
