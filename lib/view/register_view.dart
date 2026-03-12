import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:agendo/view_models/auth_view_model.dart';
import 'package:agendo/view/bottom_navigation_bar_page.dart';
import 'package:agendo/view/components/color_app.dart';

class RegisterView extends StatefulWidget {
  const RegisterView({super.key});

  @override
  State<RegisterView> createState() => _RegisterViewState();
}

class _RegisterViewState extends State<RegisterView> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  String _selectedRole = 'CLIENT';

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    final authVm = context.read<AuthViewModel>();
    final success = await authVm.register(
      name: _nameController.text.trim(),
      email: _emailController.text.trim(),
      phone: _phoneController.text.trim(),
      password: _passwordController.text,
      role: _selectedRole,
    );

    if (!mounted) return;

    if (success) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const BottomNavigationBarPage()),
        (route) => false,
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authVm.errorMessage ?? 'Erro ao criar conta'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 800;
    final colors = Theme.of(context).colorScheme;
    final authVm = context.watch<AuthViewModel>();

    final formContent = _RegisterForm(
      formKey: _formKey,
      nameController: _nameController,
      emailController: _emailController,
      phoneController: _phoneController,
      passwordController: _passwordController,
      obscurePassword: _obscurePassword,
      selectedRole: _selectedRole,
      isLoading: authVm.isLoading,
      onTogglePassword: () => setState(() => _obscurePassword = !_obscurePassword),
      onRoleChanged: (role) => setState(() => _selectedRole = role),
      onRegister: _handleRegister,
    );

    if (isWide) {
      return Scaffold(
        body: Row(
          children: [
            Expanded(child: _BrandingPanel()),
            Expanded(
              child: SafeArea(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 32),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 440),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        IconButton(
                          icon: Icon(Icons.arrow_back, color: colors.onSurface),
                          onPressed: () => Navigator.of(context).pop(),
                          alignment: Alignment.centerLeft,
                          padding: EdgeInsets.zero,
                        ),
                        const SizedBox(height: 16),
                        Text('Criar Conta', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: colors.primary)),
                        const SizedBox(height: 8),
                        Text('Preencha seus dados para começar', style: TextStyle(fontSize: 16, color: colors.onSurface.withValues(alpha: 0.6))),
                        const SizedBox(height: 32),
                        formContent,
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: colors.onSurface),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Criar Conta', textAlign: TextAlign.center, style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: colors.primary)),
                  const SizedBox(height: 8),
                  Text('Preencha seus dados para começar', textAlign: TextAlign.center, style: TextStyle(fontSize: 16, color: colors.onSurface.withValues(alpha: 0.6))),
                  const SizedBox(height: 36),
                  formContent,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RegisterForm extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController nameController;
  final TextEditingController emailController;
  final TextEditingController phoneController;
  final TextEditingController passwordController;
  final bool obscurePassword;
  final String selectedRole;
  final bool isLoading;
  final VoidCallback onTogglePassword;
  final ValueChanged<String> onRoleChanged;
  final VoidCallback onRegister;

  const _RegisterForm({
    required this.formKey,
    required this.nameController,
    required this.emailController,
    required this.phoneController,
    required this.passwordController,
    required this.obscurePassword,
    required this.selectedRole,
    required this.isLoading,
    required this.onTogglePassword,
    required this.onRoleChanged,
    required this.onRegister,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            controller: nameController,
            style: TextStyle(color: colors.onSurface),
            decoration: _inputDecoration(colors, label: 'Nome completo', icon: Icons.person_outline),
            validator: (v) => (v == null || v.trim().isEmpty) ? 'Informe seu nome' : null,
          ),
          const SizedBox(height: 16),
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
          const SizedBox(height: 16),
          TextFormField(
            controller: phoneController,
            keyboardType: TextInputType.phone,
            style: TextStyle(color: colors.onSurface),
            decoration: _inputDecoration(colors, label: 'Telefone', icon: Icons.phone_outlined),
            validator: (v) => (v == null || v.trim().isEmpty) ? 'Informe seu telefone' : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: passwordController,
            obscureText: obscurePassword,
            style: TextStyle(color: colors.onSurface),
            decoration: _inputDecoration(
              colors,
              label: 'Senha',
              icon: Icons.lock_outline,
              suffixIcon: IconButton(
                icon: Icon(obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: colors.onSurface.withValues(alpha: 0.5)),
                onPressed: onTogglePassword,
              ),
            ),
            validator: (v) {
              if (v == null || v.isEmpty) return 'Informe sua senha';
              if (v.length < 6) return 'Mínimo de 6 caracteres';
              return null;
            },
          ),
          const SizedBox(height: 20),
          Text('Eu sou:', style: TextStyle(color: colors.onSurface.withValues(alpha: 0.7), fontSize: 14)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: _RoleButton(colors: colors, label: 'Cliente', value: 'CLIENT', icon: Icons.person, selectedRole: selectedRole, onChanged: onRoleChanged)),
              const SizedBox(width: 12),
              Expanded(child: _RoleButton(colors: colors, label: 'Profissional', value: 'PROFESSIONAL', icon: Icons.work, selectedRole: selectedRole, onChanged: onRoleChanged)),
            ],
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: isLoading ? null : onRegister,
            style: ElevatedButton.styleFrom(
              backgroundColor: colors.primary,
              foregroundColor: colors.onPrimary,
              minimumSize: const Size(double.infinity, 56),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              disabledBackgroundColor: colors.primary.withValues(alpha: 0.5),
            ),
            child: isLoading
                ? SizedBox(height: 24, width: 24, child: CircularProgressIndicator(strokeWidth: 2.5, color: colors.onPrimary))
                : const Text('Cadastrar', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 24),
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

class _RoleButton extends StatelessWidget {
  final ColorScheme colors;
  final String label;
  final String value;
  final IconData icon;
  final String selectedRole;
  final ValueChanged<String> onChanged;

  const _RoleButton({required this.colors, required this.label, required this.value, required this.icon, required this.selectedRole, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final isSelected = selectedRole == value;
    return GestureDetector(
      onTap: () => onChanged(value),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? colors.primary.withValues(alpha: 0.15) : colors.onSurface.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isSelected ? colors.primary : Colors.transparent, width: 2),
        ),
        child: Column(
          children: [
            Icon(icon, color: isSelected ? colors.primary : colors.onSurface.withValues(alpha: 0.5)),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(color: isSelected ? colors.primary : colors.onSurface.withValues(alpha: 0.7), fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
          ],
        ),
      ),
    );
  }
}

class _BrandingPanel extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [ColorApp.orangeHighlight, ColorApp.orangeHighlight.withValues(alpha: 0.7)],
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
              const Text('Agendo', style: TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: Colors.white)),
              const SizedBox(height: 16),
              const Text(
                'Crie sua conta e comece a agendar serviços hoje mesmo.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, color: Colors.white70, height: 1.5),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
