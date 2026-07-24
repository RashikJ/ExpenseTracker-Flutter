import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/auth_provider.dart';
import '../widgets/sign_in_form.dart';
import '../widgets/sign_up_form.dart';

class LoginScreen extends HookConsumerWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final firstNameController = useTextEditingController();
    final lastNameController = useTextEditingController();
    final emailController = useTextEditingController();
    final passwordController = useTextEditingController();
    final formKey = useMemoized(() => GlobalKey<FormState>());
    final isLoading = useState(false);
    final isSignUpMode = useState(false);
    final isPasswordHidden = useState(true);
    final errorMessage = useState<String?>(null);

    Future<void> submit() async {
      if (!formKey.currentState!.validate()) return;

      isLoading.value = true;
      errorMessage.value = null;

      try {
        final authRepo = ref.read(authRepositoryProvider);
        if (isSignUpMode.value) {
          await authRepo.signUp(
            emailController.text.trim(),
            passwordController.text.trim(),
            firstName: firstNameController.text.trim(),
            lastName: lastNameController.text.trim(),
          );
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Account created. Check your email to confirm.'),
              ),
            );
          }
        } else {
          await authRepo.signIn(
            emailController.text.trim(),
            passwordController.text.trim(),
          );
          if (context.mounted) {
            context.go('/expenses');
          }
        }
      } catch (e) {
        errorMessage.value = _friendlyError(e);
      } finally {
        isLoading.value = false;
      }
    }

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).colorScheme.surface,
              Theme.of(context).colorScheme.primary.withValues(alpha: 0.05),
              Theme.of(context).colorScheme.surface,
            ],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              const Positioned.fill(child: _LoginBackground()),
              Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: Container(
                      padding: const EdgeInsets.all(22),
                      decoration: BoxDecoration(
                        color: Theme.of(
                          context,
                        ).colorScheme.surface.withValues(alpha: 0.97),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: Theme.of(
                            context,
                          ).colorScheme.outlineVariant.withValues(alpha: 0.22),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.07),
                            blurRadius: 24,
                            offset: const Offset(0, 12),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Container(
                            width: 40,
                            height: 4,
                            margin: const EdgeInsets.only(bottom: 18),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primary,
                              borderRadius: BorderRadius.circular(99),
                            ),
                          ),
                          Text(
                            isSignUpMode.value
                                ? 'Create Account'
                                : 'Welcome Back',
                            style: Theme.of(context).textTheme.headlineSmall
                                ?.copyWith(fontWeight: FontWeight.w700),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            isSignUpMode.value
                                ? 'Set up your account to start tracking expenses.'
                                : 'Sign in to continue managing your budget.',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                                ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 14),
                          _AuthModeToggle(
                            isSignUpMode: isSignUpMode.value,
                            onChanged: isLoading.value
                                ? null
                                : (value) => isSignUpMode.value = value,
                          ),
                          const SizedBox(height: 26),
                          if (isSignUpMode.value)
                            SignUpForm(
                              formKey: formKey,
                              firstNameController: firstNameController,
                              lastNameController: lastNameController,
                              emailController: emailController,
                              passwordController: passwordController,
                              isLoading: isLoading.value,
                              isPasswordHidden: isPasswordHidden.value,
                              onTogglePassword: () {
                                isPasswordHidden.value =
                                    !isPasswordHidden.value;
                              },
                              errorMessage: errorMessage.value,
                              onSubmit: submit,
                            )
                          else
                            SignInForm(
                              formKey: formKey,
                              emailController: emailController,
                              passwordController: passwordController,
                              isLoading: isLoading.value,
                              isPasswordHidden: isPasswordHidden.value,
                              onTogglePassword: () {
                                isPasswordHidden.value =
                                    !isPasswordHidden.value;
                              },
                              errorMessage: errorMessage.value,
                              onSubmit: submit,
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _friendlyError(Object e) {
    final msg = e.toString().toLowerCase();
    if (msg.contains('invalid login credentials')) {
      return 'Incorrect email or password';
    }
    if (msg.contains('already registered')) {
      return 'An account with this email already exists';
    }
    return 'Something went wrong. Please try again.';
  }
}

class _LoginBackground extends StatelessWidget {
  const _LoginBackground();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Stack(
      children: [
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  colorScheme.surface,
                  colorScheme.primary.withValues(alpha: 0.03),
                  colorScheme.surface,
                ],
              ),
            ),
          ),
        ),
        Positioned.fill(
          child: CustomPaint(
            painter: _SubtleGridPainter(
              lineColor: colorScheme.outlineVariant.withValues(alpha: 0.12),
            ),
          ),
        ),
        Positioned(
          top: -120,
          right: -100,
          child: Container(
            width: 280,
            height: 280,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  colorScheme.primary.withValues(alpha: 0.14),
                  colorScheme.primary.withValues(alpha: 0.0),
                ],
              ),
            ),
          ),
        ),
        Positioned(
          bottom: -140,
          left: -100,
          child: Container(
            width: 320,
            height: 320,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(48),
              gradient: RadialGradient(
                colors: [
                  colorScheme.secondary.withValues(alpha: 0.12),
                  colorScheme.secondary.withValues(alpha: 0.0),
                ],
              ),
            ),
          ),
        ),
        Positioned(
          top: 88,
          left: 24,
          right: 24,
          child: Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  colorScheme.outlineVariant.withValues(alpha: 0.35),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
        Positioned(
          top: 150,
          right: 18,
          child: Container(
            width: 128,
            height: 128,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color: colorScheme.primary.withValues(alpha: 0.10),
              ),
              color: colorScheme.surface.withValues(alpha: 0.10),
            ),
          ),
        ),
        Positioned(
          left: 24,
          top: 178,
          child: Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              color: colorScheme.primary.withValues(alpha: 0.05),
              border: Border.all(
                color: colorScheme.outlineVariant.withValues(alpha: 0.12),
              ),
            ),
          ),
        ),
        Positioned(
          right: 34,
          bottom: 140,
          child: Transform.rotate(
            angle: 0.15,
            child: Container(
              width: 64,
              height: 22,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(999),
                color: colorScheme.primary.withValues(alpha: 0.06),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _SubtleGridPainter extends CustomPainter {
  _SubtleGridPainter({required this.lineColor});

  final Color lineColor;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = lineColor
      ..strokeWidth = 1;

    const spacing = 36.0;

    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }

    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _SubtleGridPainter oldDelegate) {
    return oldDelegate.lineColor != lineColor;
  }
}

class _AuthModeToggle extends StatelessWidget {
  const _AuthModeToggle({required this.isSignUpMode, required this.onChanged});

  final bool isSignUpMode;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      height: 48,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.6),
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final segmentWidth = constraints.maxWidth / 2;

          return Stack(
            children: [
              AnimatedAlign(
                alignment: isSignUpMode
                    ? Alignment.centerRight
                    : Alignment.centerLeft,
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                child: Container(
                  width: segmentWidth - 3,
                  decoration: BoxDecoration(
                    color: colorScheme.primary,
                    borderRadius: BorderRadius.circular(11),
                    boxShadow: [
                      BoxShadow(
                        color: colorScheme.primary.withValues(alpha: 0.12),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                ),
              ),
              Row(
                children: [
                  Expanded(
                    child: _ToggleSegment(
                      label: 'Sign In',
                      selected: !isSignUpMode,
                      onTap: onChanged == null ? null : () => onChanged!(false),
                    ),
                  ),
                  Expanded(
                    child: _ToggleSegment(
                      label: 'Sign Up',
                      selected: isSignUpMode,
                      onTap: onChanged == null ? null : () => onChanged!(true),
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ToggleSegment extends StatelessWidget {
  const _ToggleSegment({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(11),
        onTap: onTap,
        child: Center(
          child: AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            style: Theme.of(context).textTheme.labelLarge!.copyWith(
              color: selected
                  ? colorScheme.onPrimary
                  : colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
            child: Text(label),
          ),
        ),
      ),
    );
  }
}
