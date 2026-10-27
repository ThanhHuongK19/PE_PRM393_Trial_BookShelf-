import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../validators/auth_validators.dart';
import '../../widgets/auth_error_message.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  String? _successMessage;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _successMessage = null);
    try {
      await context
          .read<AuthProvider>()
          .sendPasswordResetEmail(_emailController.text);
      if (mounted) {
        setState(() {
          _successMessage =
              'If an account exists for that email, a reset link will be sent.';
        });
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(authErrorMessage(error))));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isBusy = context.watch<AuthProvider>().isBusy;
    return Scaffold(
      appBar: AppBar(title: const Text('Reset password')),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('Forgot your password?',
                        style: Theme.of(context).textTheme.headlineMedium),
                    const SizedBox(height: 8),
                    const Text('Enter your email and we will send a reset link.'),
                    const SizedBox(height: 24),
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      autofillHints: const [AutofillHints.email],
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        border: OutlineInputBorder(),
                      ),
                      validator: AuthValidators.email,
                    ),
                    if (_successMessage != null) ...[
                      const SizedBox(height: 16),
                      Text(_successMessage!,
                          style: TextStyle(
                              color: Theme.of(context).colorScheme.primary)),
                    ],
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: isBusy ? null : _submit,
                      child: isBusy
                          ? const SizedBox.square(
                              dimension: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Send reset link'),
                    ),
                    TextButton(
                      onPressed: () => context.go('/sign-in'),
                      child: const Text('Back to sign in'),
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
