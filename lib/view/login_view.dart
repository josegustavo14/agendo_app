import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:agendo/view_models/auth_view_model.dart';
import 'package:agendo/view/register_view.dart';
import 'package:agendo/view/bottom_navigation_bar_page.dart';
import 'package:agendo/view/components/color_app.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    final authVm = context.read<AuthViewModel>();
    final success = await authVm.login(
      _emailController.text.trim(),
      _passwordController.text,
    );

    if (!mounted) return;

    if (success) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const BottomNavigationBarPage()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authVm.errorMessage ?? 'Erro ao fazer login'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 800;

    if (isWide) {
      return _DesktopLogin(
        formKey: _formKey,
        emailController: _emailController,
        passwordController: _passwordController,
        obscurePassword: _obscurePassword,
        onTogglePassword: () => setState(() => _obscurePassword = !_obscurePassword),
        onLogin: _handleLogin,
      );
    }

    return _MobileLogin(
      formKey: _formKey,
      emailController: _emailController,
      passwordController: _passwordController,
      obscurePassword: _obscurePassword,
      onTogglePassword: () => setState(() => _obscurePassword = !_obscurePassword),
      onLogin: _handleLogin,
    );
  }
}

// ── Shared form widget ─────────────────────────────────────────────────────────

class _LoginForm extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final bool obscurePassword;
  final VoidCallback onTogglePassword;
  final VoidCallback onLogin;

  const _LoginForm({
    required this.formKey,
    required this.emailController,
    required this.passwordController,
    required this.obscurePassword,
    required this.onTogglePassword,
    required this.onLogin,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final authVm = context.watch<AuthViewModel>();

    return Form(
      key: formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            controller: emailController,
            keyboardType: TextInputType.emailAddress,
            style: TextStyle(color: colors.onSurface),
            decoration: _inputDecoration(colors, label: 'Email', icon: Icons.email_outlined),
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Informe seu email';
              if (!v.contains('@')) return 'Email inválido';
              return null;
            },
          ),
          const SizedBox(height: 20),
          TextFormField(
            controller: passwordController,
            obscureText: obscurePassword,
            style: TextStyle(color: colors.onSurface),
            decoration: _inputDecoration(
              colors,
              label: 'Senha',
              icon: Icons.lock_outline,
              suffixIcon: IconButton(
                icon: Icon(
                  obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                  color: colors.onSurface.withValues(alpha: 0.5),
                ),
                onPressed: onTogglePassword,
              ),
            ),
            validator: (v) {
              if (v == null || v.isEmpty) return 'Informe sua senha';
              return null;
            },
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: authVm.isLoading ? null : onLogin,
            style: ElevatedButton.styleFrom(
              backgroundColor: colors.primary,
              foregroundColor: colors.onPrimary,
              minimumSize: const Size(double.infinity, 56),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              disabledBackgroundColor: colors.primary.withValues(alpha: 0.5),
            ),
            child: authVm.isLoading
                ? SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(strokeWidth: 2.5, color: colors.onPrimary),
                  )
                : const Text('Entrar', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Não tem uma conta? ', style: TextStyle(color: colors.onSurface.withValues(alpha: 0.6))),
              GestureDetector(
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const RegisterView()),
                ),
                child: Text(
                  'Cadastre-se',
                  style: TextStyle(color: colors.primary, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(ColorScheme colors, {required String label, required IconData icon, Widget? suffixIcon}) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: colors.onSurface.withValues(alpha: 0.5)),
      prefixIcon: Icon(icon, color: colors.onSurface.withValues(alpha: 0.5)),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: colors.onSurface.withValues(alpha: 0.05),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: colors.primary, width: 2)),
      errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: colors.error, width: 1)),
      focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: colors.error, width: 2)),
    );
  }
}

// ── Mobile ─────────────────────────────────────────────────────────────────────

class _MobileLogin extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final bool obscurePassword;
  final VoidCallback onTogglePassword;
  final VoidCallback onLogin;

  const _MobileLogin({
    required this.formKey,
    required this.emailController,
    required this.passwordController,
    required this.obscurePassword,
    required this.onTogglePassword,
    required this.onLogin,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.calendar_month_rounded, size: 72, color: colors.primary),
                  const SizedBox(height: 16),
                  Text('Agendo', textAlign: TextAlign.center, style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: colors.primary)),
                  const SizedBox(height: 8),
                  Text('Entre na sua conta', textAlign: TextAlign.center, style: TextStyle(fontSize: 16, color: colors.onSurface.withValues(alpha: 0.6))),
                  const SizedBox(height: 48),
                  _LoginForm(
                    formKey: formKey,
                    emailController: emailController,
                    passwordController: passwordController,
                    obscurePassword: obscurePassword,
                    onTogglePassword: onTogglePassword,
                    onLogin: onLogin,
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

// ── Desktop ────────────────────────────────────────────────────────────────────

class _DesktopLogin extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final bool obscurePassword;
  final VoidCallback onTogglePassword;
  final VoidCallback onLogin;

  const _DesktopLogin({
    required this.formKey,
    required this.emailController,
    required this.passwordController,
    required this.obscurePassword,
    required this.onTogglePassword,
    required this.onLogin,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // Left panel — branding
          Expanded(
            child: _BrandingPanel(),
          ),
          // Right panel — form
          Expanded(
            child: SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 48),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 440),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Bem-vindo de volta',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Entre na sua conta para continuar',
                          style: TextStyle(
                            fontSize: 16,
                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                          ),
                        ),
                        const SizedBox(height: 40),
                        _LoginForm(
                          formKey: formKey,
                          emailController: emailController,
                          passwordController: passwordController,
                          obscurePassword: obscurePassword,
                          onTogglePassword: onTogglePassword,
                          onLogin: onLogin,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Branding Panel (shared between login & register) ──────────────────────────

class _BrandingPanel extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            ColorApp.orangeHighlight,
            ColorApp.orangeHighlight.withValues(alpha: 0.7),
          ],
        ),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(48),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.calendar_month_rounded, size: 96, color: Colors.white),
              const SizedBox(height: 24),
              const Text(
                'Agendo',
                style: TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(height: 16),
              const Text(
                'Agende serviços com os melhores profissionais da sua região.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, color: Colors.white70, height: 1.5),
              ),
              const SizedBox(height: 48),
              _featureItem(Icons.search_rounded, 'Encontre profissionais'),
              const SizedBox(height: 16),
              _featureItem(Icons.calendar_today_rounded, 'Agende no seu horário'),
              const SizedBox(height: 16),
              _featureItem(Icons.star_rounded, 'Avalie e confie'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _featureItem(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
        const SizedBox(width: 12),
        Text(text, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500)),
      ],
    );
  }
}
