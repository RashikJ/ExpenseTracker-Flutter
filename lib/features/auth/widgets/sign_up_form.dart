import 'package:flutter/material.dart';

class SignUpForm extends StatelessWidget {
  const SignUpForm({
    super.key,
    required this.formKey,
    required this.firstNameController,
    required this.lastNameController,
    required this.emailController,
    required this.passwordController,
    required this.isLoading,
    required this.isPasswordHidden,
    required this.onTogglePassword,
    required this.errorMessage,
    required this.onSubmit,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController firstNameController;
  final TextEditingController lastNameController;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final bool isLoading;
  final bool isPasswordHidden;
  final VoidCallback onTogglePassword;
  final String? errorMessage;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Form(
      key: formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: firstNameController,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'First name',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Required';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: lastNameController,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Last name',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Required';
                    }
                    return null;
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              labelText: 'Email',
              prefixIcon: Icon(Icons.email_outlined),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Email is required';
              }
              if (!value.contains('@')) {
                return 'Enter a valid email';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: passwordController,
            obscureText: isPasswordHidden,
            decoration: InputDecoration(
              labelText: 'Password',
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                tooltip: isPasswordHidden ? 'Show password' : 'Hide password',
                onPressed: onTogglePassword,
                icon: Icon(
                  isPasswordHidden
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                ),
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Password is required';
              }
              if (value.length < 6) {
                return 'Minimum 6 characters';
              }
              return null;
            },
          ),
          if (errorMessage != null) ...[
            const SizedBox(height: 12),
            Text(
              errorMessage!,
              style: TextStyle(color: colorScheme.error),
              textAlign: TextAlign.center,
            ),
          ],
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: isLoading ? null : onSubmit,
            style: ElevatedButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
            ),
            child: isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Sign Up'),
          ),
        ],
      ),
    );
  }
}
