import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/network/api_client.dart';
import '../features/auth/state/auth_state.dart';
import '../theme/app_theme.dart';
import '../theme/tokens.dart';
import '../widgets/app_input.dart';
import '../widgets/primary_button.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  final VoidCallback onDone;
  final VoidCallback onLogin;

  const RegisterScreen({
    super.key,
    required this.onDone,
    required this.onLogin,
  });

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _name = TextEditingController(text: 'Sakura San');
  final _email = TextEditingController(
    text: 'sakura_${DateTime.now().millisecondsSinceEpoch}@sakura.app',
  );
  final _password = TextEditingController(text: 'NewPassword123!');
  final _confirmPassword = TextEditingController(text: 'NewPassword123!');
  bool _loading = false;
  String? _error;

  Future<void> _register() async {
    if (_password.text != _confirmPassword.text) {
      setState(() => _error = 'Passwords do not match.');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await ref.read(authControllerProvider.notifier).register(
            name: _name.text.trim(),
            email: _email.text.trim(),
            password: _password.text,
          );
      if (mounted) widget.onDone();
    } catch (error) {
      if (mounted) setState(() => _error = ApiClient.describeError(error));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  onPressed: widget.onLogin,
                  child: Text(
                    '< Back',
                    style: AppTextStyles.caption.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Create account',
                style: AppTextStyles.h1.copyWith(fontSize: 26),
              ),
              const SizedBox(height: 4),
              Text(
                'Start your Japanese journey today',
                style: AppTextStyles.caption,
              ),
              const SizedBox(height: 28),
              AppInput(
                hint: 'Name',
                icon: Icons.person_outline_rounded,
                controller: _name,
                valid: _name.text.trim().length >= 2,
              ),
              const SizedBox(height: 12),
              AppInput(
                hint: 'Email',
                icon: Icons.mail_outline_rounded,
                controller: _email,
                valid: _email.text.contains('@'),
              ),
              const SizedBox(height: 12),
              AppInput(
                hint: 'Password',
                icon: Icons.lock_outline_rounded,
                controller: _password,
                obscure: true,
              ),
              const SizedBox(height: 12),
              AppInput(
                hint: 'Confirm password',
                icon: Icons.lock_outline_rounded,
                controller: _confirmPassword,
                obscure: true,
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(
                  _error!,
                  style: const TextStyle(
                    color: AppColors.sakura,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
              const SizedBox(height: 24),
              PrimaryButton(
                label: _loading ? 'Creating...' : 'Create Account',
                onTap: _loading ? () {} : _register,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Widget _socialBtn(Widget child, {VoidCallback? onTap}) => GestureDetector(
      onTap: onTap,
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: AppColors.inputBg,
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        alignment: Alignment.center,
        child: child,
      ),
    );

class LoginScreen extends ConsumerStatefulWidget {
  final VoidCallback onLogin;
  final VoidCallback onRegister;
  final VoidCallback onForgotPassword;

  const LoginScreen({
    super.key,
    required this.onLogin,
    required this.onRegister,
    required this.onForgotPassword,
  });

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _email = TextEditingController(text: 'hello@sakura.app');
  final _password = TextEditingController(text: 'NewPassword123!');
  bool _loading = false;
  String? _error;

  Future<void> _login() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await ref.read(authControllerProvider.notifier).login(
            email: _email.text.trim(),
            password: _password.text,
          );
      if (mounted) widget.onLogin();
    } catch (error) {
      if (mounted) setState(() => _error = ApiClient.describeError(error));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _googleLogin() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await ref.read(authControllerProvider.notifier).loginWithGoogle();
      if (mounted) widget.onLogin();
    } catch (error) {
      if (mounted) setState(() => _error = ApiClient.describeError(error));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  gradient: AppGradients.primary,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                alignment: Alignment.center,
                child: Text(
                  'S',
                  style: AppTextStyles.h1.copyWith(
                    color: Colors.white,
                    fontSize: 28,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Welcome back',
                style: AppTextStyles.h1.copyWith(fontSize: 26),
              ),
              const SizedBox(height: 4),
              Text(
                'Sign in to continue learning Japanese',
                style: AppTextStyles.caption,
              ),
              const SizedBox(height: 32),
              AppInput(
                hint: 'Email address',
                icon: Icons.mail_outline_rounded,
                controller: _email,
              ),
              const SizedBox(height: 12),
              AppInput(
                hint: 'Password',
                icon: Icons.lock_outline_rounded,
                controller: _password,
                obscure: true,
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: _loading ? null : widget.onForgotPassword,
                  child: const Text(
                    'Forgot password?',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 4),
                Text(
                  _error!,
                  style: const TextStyle(
                    color: AppColors.sakura,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
              const SizedBox(height: 12),
              PrimaryButton(
                label: _loading ? 'Signing in...' : 'Sign In',
                onTap: _loading ? () {} : _login,
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  const Expanded(child: Divider(color: AppColors.line)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      'or continue with',
                      style: AppTextStyles.caption.copyWith(fontSize: 12),
                    ),
                  ),
                  const Expanded(child: Divider(color: AppColors.line)),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _socialBtn(
                      const Text(
                        'G',
                        style: TextStyle(
                          color: Color(0xFFEA4335),
                          fontWeight: FontWeight.w800,
                          fontSize: 20,
                        ),
                      ),
                      onTap: _loading ? null : _googleLogin,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              Center(
                child: GestureDetector(
                  onTap: _loading ? null : widget.onRegister,
                  child: RichText(
                    text: TextSpan(
                      style: AppTextStyles.caption,
                      children: const [
                        TextSpan(text: "Don't have an account? "),
                        TextSpan(
                          text: 'Sign up',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
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
}

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  final VoidCallback onBack;

  const ForgotPasswordScreen({super.key, required this.onBack});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _email = TextEditingController();
  final _code = TextEditingController();
  final _newPassword = TextEditingController();
  final _confirmPassword = TextEditingController();
  bool _loading = false;
  bool _sent = false;
  String? _error;

  Future<void> _sendCode({bool resend = false}) async {
    final email = _email.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      setState(() => _error = 'Please enter a valid email address.');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final repository = ref.read(authRepositoryProvider);
      if (resend) {
        await repository.resendResetCode(email);
      } else {
        await repository.forgotPassword(email);
      }
      if (mounted) {
        setState(() => _sent = true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('If the email exists, a reset code has been sent.'),
          ),
        );
      }
    } catch (error) {
      if (mounted) setState(() => _error = ApiClient.describeError(error));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _resetPassword() async {
    final email = _email.text.trim();
    final code = _code.text.trim();
    final newPassword = _newPassword.text;

    if (!RegExp(r'^\d{6}$').hasMatch(code)) {
      setState(() => _error = 'Enter the 6-digit reset code.');
      return;
    }
    if (newPassword != _confirmPassword.text) {
      setState(() => _error = 'Passwords do not match.');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await ref.read(authRepositoryProvider).resetPassword(
            email: email,
            code: code,
            newPassword: newPassword,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password reset. Sign in with your new password.'),
        ),
      );
      widget.onBack();
    } catch (error) {
      if (mounted) setState(() => _error = ApiClient.describeError(error));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  onPressed: _loading ? null : widget.onBack,
                  child: Text(
                    '< Back to login',
                    style: AppTextStyles.caption.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.lock_reset_rounded,
                  color: AppColors.primary,
                  size: 28,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Reset password',
                style: AppTextStyles.h1.copyWith(fontSize: 26),
              ),
              const SizedBox(height: 8),
              Text(
                _sent
                    ? 'Enter the code from your email and choose a new password.'
                    : 'Enter your email and we will send a 6-digit reset code if the account exists.',
                style: AppTextStyles.body.copyWith(
                  color: AppColors.mute,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 32),
              AppInput(
                hint: 'Email address',
                icon: Icons.mail_outline_rounded,
                controller: _email,
              ),
              if (_sent) ...[
                const SizedBox(height: 12),
                AppInput(
                  hint: '6-digit code',
                  icon: Icons.pin_outlined,
                  controller: _code,
                ),
                const SizedBox(height: 12),
                AppInput(
                  hint: 'New password',
                  icon: Icons.lock_outline_rounded,
                  controller: _newPassword,
                  obscure: true,
                ),
                const SizedBox(height: 12),
                AppInput(
                  hint: 'Confirm new password',
                  icon: Icons.lock_outline_rounded,
                  controller: _confirmPassword,
                  obscure: true,
                ),
              ],
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(
                  _error!,
                  style: const TextStyle(
                    color: AppColors.sakura,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
              const SizedBox(height: 24),
              PrimaryButton(
                label: _loading
                    ? (_sent ? 'Resetting...' : 'Sending...')
                    : (_sent ? 'Reset Password' : 'Send Reset Code'),
                onTap: _loading
                    ? () {}
                    : (_sent ? _resetPassword : () => _sendCode()),
              ),
              if (_sent) ...[
                const SizedBox(height: 16),
                Center(
                  child: TextButton(
                    onPressed: _loading ? null : () => _sendCode(resend: true),
                    child: Text(
                      'Send a new code',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class ChangePasswordScreen extends ConsumerStatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  ConsumerState<ChangePasswordScreen> createState() =>
      _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends ConsumerState<ChangePasswordScreen> {
  final _currentPassword = TextEditingController();
  final _newPassword = TextEditingController();
  final _confirmPassword = TextEditingController();
  bool _loading = false;
  String? _error;

  Future<void> _changePassword() async {
    if (_newPassword.text != _confirmPassword.text) {
      setState(() => _error = 'Passwords do not match.');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await ref.read(authRepositoryProvider).changePassword(
            currentPassword: _currentPassword.text,
            newPassword: _newPassword.text,
          );
      await ref.read(authControllerProvider.notifier).logout();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password changed. Please sign in again.'),
        ),
      );
      Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);
    } catch (error) {
      if (mounted) setState(() => _error = ApiClient.describeError(error));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  onPressed: _loading ? null : () => Navigator.pop(context),
                  child: Text(
                    '< Back',
                    style: AppTextStyles.caption.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppColors.goldSoft,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.shield_outlined,
                  color: AppColors.gold,
                  size: 28,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Change password',
                style: AppTextStyles.h1.copyWith(fontSize: 26),
              ),
              const SizedBox(height: 8),
              Text(
                'Update your password for this account.',
                style: AppTextStyles.body.copyWith(
                  color: AppColors.mute,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 32),
              AppInput(
                hint: 'Current password',
                icon: Icons.lock_outline_rounded,
                controller: _currentPassword,
                obscure: true,
              ),
              const SizedBox(height: 12),
              AppInput(
                hint: 'New password',
                icon: Icons.lock_outline_rounded,
                controller: _newPassword,
                obscure: true,
              ),
              const SizedBox(height: 12),
              AppInput(
                hint: 'Confirm new password',
                icon: Icons.lock_outline_rounded,
                controller: _confirmPassword,
                obscure: true,
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(
                  _error!,
                  style: const TextStyle(
                    color: AppColors.sakura,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
              const SizedBox(height: 24),
              PrimaryButton(
                label: _loading ? 'Saving...' : 'Change Password',
                onTap: _loading ? () {} : _changePassword,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
