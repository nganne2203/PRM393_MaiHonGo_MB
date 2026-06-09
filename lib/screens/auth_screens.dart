import 'package:flutter/material.dart';
import '../core/network/api_client.dart';
import '../core/network/auth_api.dart';
import '../theme/tokens.dart';
import '../theme/app_theme.dart';
import '../widgets/app_input.dart';
import '../widgets/primary_button.dart';

class RegisterScreen extends StatefulWidget {
  final VoidCallback onDone;
  final VoidCallback onLogin;
  const RegisterScreen(
      {super.key, required this.onDone, required this.onLogin});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _u = TextEditingController(text: 'sakura_san');
  final _e = TextEditingController(
    text: 'sakura_${DateTime.now().millisecondsSinceEpoch}@sakura.app',
  );
  final _p = TextEditingController(text: 'strongpass');
  final _c = TextEditingController(text: 'strongpass');
  final _authApi = AuthApi();
  bool _loading = false;
  String? _error;

  Future<void> _register() async {
    if (_p.text != _c.text) {
      setState(() => _error = 'Passwords do not match.');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await _authApi.register(
        displayName: _u.text.trim(),
        email: _e.text.trim(),
        password: _p.text,
      );
      widget.onDone();
    } catch (error) {
      setState(() => _error = ApiClient.describeError(error));
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
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                  onPressed: widget.onLogin,
                  child: Text('← Back',
                      style: AppTextStyles.caption
                          .copyWith(fontWeight: FontWeight.w600))),
            ),
            const SizedBox(height: 8),
            Text('Create account',
                style: AppTextStyles.h1.copyWith(fontSize: 26)),
            const SizedBox(height: 4),
            Text('Start your Japanese journey today',
                style: AppTextStyles.caption),
            const SizedBox(height: 28),
            AppInput(
                hint: 'Username',
                icon: Icons.person_outline_rounded,
                controller: _u,
                valid: _u.text.length >= 3),
            const SizedBox(height: 12),
            AppInput(
                hint: 'Email',
                icon: Icons.mail_outline_rounded,
                controller: _e,
                valid: _e.text.contains('@')),
            const SizedBox(height: 12),
            AppInput(
                hint: 'Password',
                icon: Icons.lock_outline_rounded,
                controller: _p,
                obscure: true),
            const SizedBox(height: 12),
            AppInput(
                hint: 'Confirm password',
                icon: Icons.lock_outline_rounded,
                controller: _c,
                obscure: true),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!,
                  style: const TextStyle(
                      color: AppColors.sakura, fontWeight: FontWeight.w700)),
            ],
            const SizedBox(height: 24),
            PrimaryButton(
                label: _loading ? 'Creating...' : 'Create Account',
                onTap: _loading ? () {} : _register),
          ]),
        ),
      ),
    );
  }
}

Widget _socialBtn(Widget child) => Container(
      height: 48,
      decoration: BoxDecoration(
          color: AppColors.inputBg,
          borderRadius: BorderRadius.circular(AppRadius.md)),
      alignment: Alignment.center,
      child: child,
    );

class LoginScreen extends StatefulWidget {
  final VoidCallback onLogin;
  final VoidCallback onRegister;
  const LoginScreen(
      {super.key, required this.onLogin, required this.onRegister});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _email = TextEditingController(text: 'hello@sakura.app');
  final _password = TextEditingController(text: 'strongpass');
  final _authApi = AuthApi();
  bool _loading = false;
  String? _error;

  Future<void> _login() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await _authApi.login(email: _email.text.trim(), password: _password.text);
      widget.onLogin();
    } catch (error) {
      setState(() => _error = ApiClient.describeError(error));
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
                child: Text('桜',
                    style: AppTextStyles.jp(28,
                        color: Colors.white, w: FontWeight.w900)),
              ),
              const SizedBox(height: 24),
              Text('Welcome back 👋',
                  style: AppTextStyles.h1.copyWith(fontSize: 26)),
              const SizedBox(height: 4),
              Text('Sign in to continue learning Japanese',
                  style: AppTextStyles.caption),
              const SizedBox(height: 32),
              AppInput(
                  hint: 'Email address',
                  icon: Icons.mail_outline_rounded,
                  controller: _email),
              const SizedBox(height: 12),
              AppInput(
                  hint: 'Password',
                  icon: Icons.lock_outline_rounded,
                  controller: _password,
                  obscure: true),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {},
                  child: const Text('Forgot password?',
                      style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                          fontSize: 13)),
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 4),
                Text(_error!,
                    style: const TextStyle(
                        color: AppColors.sakura, fontWeight: FontWeight.w700)),
              ],
              const SizedBox(height: 12),
              PrimaryButton(
                  label: _loading ? 'Signing in...' : 'Sign In',
                  onTap: _loading ? () {} : _login),
              const SizedBox(height: 24),
              Row(children: [
                const Expanded(child: Divider(color: AppColors.line)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text('or continue with',
                      style: AppTextStyles.caption.copyWith(fontSize: 12)),
                ),
                const Expanded(child: Divider(color: AppColors.line)),
              ]),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                      child: _socialBtn(const Text('G',
                          style: TextStyle(
                              color: Color(0xFFEA4335),
                              fontWeight: FontWeight.w800,
                              fontSize: 20)))),
                  const SizedBox(width: 12),
                  Expanded(
                      child: _socialBtn(const Icon(Icons.apple,
                          color: AppColors.ink, size: 22))),
                  const SizedBox(width: 12),
                  Expanded(
                      child: _socialBtn(const Text('f',
                          style: TextStyle(
                              color: Color(0xFF1877F2),
                              fontWeight: FontWeight.w800,
                              fontSize: 20)))),
                ],
              ),
              const SizedBox(height: 32),
              Center(
                child: GestureDetector(
                  onTap: widget.onRegister,
                  child: RichText(
                    text: TextSpan(
                      style: AppTextStyles.caption,
                      children: const [
                        TextSpan(text: "Don't have an account? "),
                        TextSpan(
                            text: 'Sign up',
                            style: TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w700)),
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
