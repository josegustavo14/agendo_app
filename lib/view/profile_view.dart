import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../view_models/profile_view_model.dart';
import '../view_models/auth_view_model.dart';
import '../models/user_model.dart';
import 'login_view.dart';

class ProfileView extends StatefulWidget {
  const ProfileView({super.key});

  @override
  State<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProfileViewModel>().loadProfile();
    });
  }

  Future<void> _handleLogout() async {
    await context.read<AuthViewModel>().logout();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginView()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final vm = context.watch<ProfileViewModel>();

    if (vm.isLoading) {
      return Center(child: CircularProgressIndicator(color: colors.primary));
    }

    if (vm.errorMessage != null || vm.profile == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              vm.errorMessage ?? 'Erro ao carregar perfil',
              style: TextStyle(color: colors.onSurface),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => vm.loadProfile(),
              child: const Text('Tentar novamente'),
            ),
          ],
        ),
      );
    }

    final user = vm.profile!;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(colors, user),
              const SizedBox(height: 28),
              _buildInfoSection(colors, user),
              if (user.professionalProfile != null) ...[
                const SizedBox(height: 20),
                _buildProfessionalSection(colors, user.professionalProfile!),
              ],
              if (user.clientProfile != null) ...[
                const SizedBox(height: 20),
                _buildClientSection(colors, user.clientProfile!),
              ],
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _handleLogout,
                  icon: const Icon(Icons.logout),
                  label: const Text('Sair da conta'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: colors.error,
                    side: BorderSide(color: colors.error),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
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

  Widget _buildHeader(ColorScheme colors, UserModel user) {
    return Row(
      children: [
        CircleAvatar(
          radius: 40,
          backgroundColor: colors.primary.withValues(alpha: 0.15),
          child: Text(
            user.name[0].toUpperCase(),
            style: TextStyle(
              color: colors.primary,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                user.name,
                style: TextStyle(
                  color: colors.onSurface,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: colors.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  user.role == 'PROFESSIONAL' ? 'Profissional' : 'Cliente',
                  style: TextStyle(
                    color: colors.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoSection(ColorScheme colors, UserModel user) {
    return _card(
      colors,
      title: 'Informações pessoais',
      children: [
        _infoRow(colors, Icons.email_outlined, 'Email', user.email),
        if (user.phone != null)
          _infoRow(colors, Icons.phone_outlined, 'Telefone', user.phone!),
      ],
    );
  }

  Widget _buildProfessionalSection(ColorScheme colors, ProfessionalProfile profile) {
    return _card(
      colors,
      title: 'Perfil profissional',
      children: [
        if (profile.professionName != null)
          _infoRow(colors, Icons.work_outline, 'Profissão', profile.professionName!),
        if (profile.bio != null && profile.bio!.isNotEmpty)
          _infoRow(colors, Icons.info_outline, 'Bio', profile.bio!),
        _infoRow(
          colors,
          profile.isAvailable == true ? Icons.check_circle_outline : Icons.cancel_outlined,
          'Disponibilidade',
          profile.isAvailable == true ? 'Disponível' : 'Indisponível',
          valueColor: profile.isAvailable == true ? Colors.green : colors.error,
        ),
      ],
    );
  }

  Widget _buildClientSection(ColorScheme colors, ClientProfile profile) {
    return _card(
      colors,
      title: 'Perfil cliente',
      children: [
        if (profile.taxId != null)
          _infoRow(colors, Icons.badge_outlined, 'CPF/CNPJ', profile.taxId!),
        if (profile.preferredPaymentMethod != null)
          _infoRow(colors, Icons.payment_outlined, 'Pagamento preferido', profile.preferredPaymentMethod!),
      ],
    );
  }

  Widget _card(ColorScheme colors, {required String title, required List<Widget> children}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: colors.onSurface.withValues(alpha: 0.5),
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.1,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colors.onSurface.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: children,
          ),
        ),
      ],
    );
  }

  Widget _infoRow(ColorScheme colors, IconData icon, String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: colors.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: colors.onSurface.withValues(alpha: 0.5),
                    fontSize: 12,
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    color: valueColor ?? colors.onSurface,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
