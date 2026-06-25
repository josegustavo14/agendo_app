import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/service_type_model.dart';
import '../view_models/manage_professional_profile_view_model.dart';

/// Tela do profissional para configurar:
///   1. profissão (dropdown alimentado por GET /professions)
///   2. bio (livre)
///   3. serviços que oferece (lista com adicionar/remover)
class ManageProfessionalProfileView extends StatefulWidget {
  const ManageProfessionalProfileView({super.key});

  @override
  State<ManageProfessionalProfileView> createState() =>
      _ManageProfessionalProfileViewState();
}

class _ManageProfessionalProfileViewState
    extends State<ManageProfessionalProfileView> {
  final _bioController = TextEditingController();
  int? _selectedProfessionId;
  bool _hydratedFromVm = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final vm = context.read<ManageProfessionalProfileViewModel>();
      await vm.loadAll();
      if (!mounted) return;
      _hydrateFromVm(vm);
    });
  }

  void _hydrateFromVm(ManageProfessionalProfileViewModel vm) {
    if (_hydratedFromVm) return;
    _selectedProfessionId = vm.selectedProfessionId;
    _bioController.text = vm.bio ?? '';
    _hydratedFromVm = true;
    setState(() {});
  }

  @override
  void dispose() {
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    final vm = context.read<ManageProfessionalProfileViewModel>();
    final ok = await vm.saveProfile(
      professionId: _selectedProfessionId,
      bio: _bioController.text.trim(),
    );
    if (!mounted) return;
    _showSnack(ok, ok ? 'Perfil salvo!' : (vm.errorMessage ?? 'Erro ao salvar'));
  }

  void _showSnack(bool ok, String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor:
            ok ? Colors.green : Theme.of(context).colorScheme.error,
      ),
    );
  }

  Future<void> _openCreateServiceSheet() async {
    final vm = context.read<ManageProfessionalProfileViewModel>();
    final result = await showModalBottomSheet<_NewServiceData>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const _NewServiceSheet(),
    );
    if (result == null || !mounted) return;
    final ok = await vm.createService(
      name: result.name,
      price: result.price,
      description: result.description,
    );
    if (!mounted) return;
    _showSnack(ok, ok ? 'Serviço cadastrado!' : (vm.errorMessage ?? 'Erro'));
  }

  Future<void> _confirmDelete(ServiceTypeModel s) async {
    final colors = Theme.of(context).colorScheme;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: colors.surface,
        title: const Text('Remover serviço?'),
        content: Text(
          'Tem certeza que quer remover "${s.name}"?',
          style: TextStyle(color: colors.onSurface.withValues(alpha: 0.7)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: colors.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Remover'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final vm = context.read<ManageProfessionalProfileViewModel>();
    final ok = await vm.deleteService(s.id);
    if (!mounted) return;
    _showSnack(ok, ok ? 'Serviço removido' : (vm.errorMessage ?? 'Erro'));
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final vm = context.watch<ManageProfessionalProfileViewModel>();

    // Re-hidrata quando o load termina
    if (!_hydratedFromVm && !vm.isLoading && vm.me != null) {
      _hydrateFromVm(vm);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Perfil profissional'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      floatingActionButton: vm.isLoading
          ? null
          : FloatingActionButton.extended(
              onPressed: _openCreateServiceSheet,
              backgroundColor: colors.primary,
              foregroundColor: colors.onPrimary,
              icon: const Icon(Icons.add),
              label: const Text('Novo serviço'),
            ),
      body: SafeArea(
        child: vm.isLoading
            ? Center(child: CircularProgressIndicator(color: colors.primary))
            : RefreshIndicator(
                onRefresh: vm.loadAll,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(24, 12, 24, 96),
                  children: [
                    _buildProfessionSection(colors, vm),
                    const SizedBox(height: 24),
                    _buildBioSection(colors),
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerRight,
                      child: FilledButton.icon(
                        onPressed: vm.isSavingProfile ? null : _saveProfile,
                        icon: vm.isSavingProfile
                            ? SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: colors.onPrimary,
                                ),
                              )
                            : const Icon(Icons.save),
                        label: const Text('Salvar perfil'),
                      ),
                    ),
                    const SizedBox(height: 32),
                    _buildServicesHeader(colors, vm.services.length),
                    const SizedBox(height: 12),
                    if (vm.services.isEmpty)
                      _emptyServicesPlaceholder(colors)
                    else
                      ...vm.services.map((s) => _buildServiceCard(colors, s)),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildProfessionSection(
      ColorScheme colors, ManageProfessionalProfileViewModel vm) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Profissão',
          style: TextStyle(
            color: colors.onSurface,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        if (vm.professions.isEmpty)
          Text(
            'Nenhuma profissão disponível ainda.',
            style: TextStyle(color: colors.onSurface.withValues(alpha: 0.5)),
          )
        else
          DropdownButtonFormField<int>(
            initialValue: _selectedProfessionId,
            decoration: InputDecoration(
              filled: true,
              fillColor: colors.onSurface.withValues(alpha: 0.05),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
            items: vm.professions
                .map((p) => DropdownMenuItem(value: p.id, child: Text(p.name)))
                .toList(),
            onChanged: (id) => setState(() => _selectedProfessionId = id),
          ),
      ],
    );
  }

  Widget _buildBioSection(ColorScheme colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Bio',
          style: TextStyle(
            color: colors.onSurface,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _bioController,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: 'Conte um pouco sobre você (opcional)',
            filled: true,
            fillColor: colors.onSurface.withValues(alpha: 0.05),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildServicesHeader(ColorScheme colors, int count) {
    return Row(
      children: [
        Text(
          'Serviços',
          style: TextStyle(
            color: colors.onSurface,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: colors.primary,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '$count',
            style: TextStyle(
              color: colors.onPrimary,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _emptyServicesPlaceholder(ColorScheme colors) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.onSurface.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(Icons.design_services_outlined,
              color: colors.onSurface.withValues(alpha: 0.4)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Nenhum serviço cadastrado. Toque em "Novo serviço" para começar.',
              style:
                  TextStyle(color: colors.onSurface.withValues(alpha: 0.6)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServiceCard(ColorScheme colors, ServiceTypeModel s) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.onSurface.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: colors.primary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.design_services, color: colors.primary),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  s.name,
                  style: TextStyle(
                    color: colors.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (s.description != null && s.description!.isNotEmpty)
                  Text(
                    s.description!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: colors.onSurface.withValues(alpha: 0.5),
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            s.formattedPrice,
            style: TextStyle(
              color: colors.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
          IconButton(
            onPressed: () => _confirmDelete(s),
            icon: Icon(Icons.delete_outline,
                color: colors.error.withValues(alpha: 0.8)),
            tooltip: 'Remover',
          ),
        ],
      ),
    );
  }
}

class _NewServiceData {
  final String name;
  final double price;
  final String? description;
  _NewServiceData({required this.name, required this.price, this.description});
}

class _NewServiceSheet extends StatefulWidget {
  const _NewServiceSheet();

  @override
  State<_NewServiceSheet> createState() => _NewServiceSheetState();
}

class _NewServiceSheetState extends State<_NewServiceSheet> {
  final _nameCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _nameCtrl.dispose();
    _priceCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final priceStr = _priceCtrl.text.replaceAll(',', '.').trim();
    final price = double.tryParse(priceStr) ?? 0;
    Navigator.pop(
      context,
      _NewServiceData(
        name: _nameCtrl.text.trim(),
        price: price,
        description:
            _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final insets = MediaQuery.of(context).viewInsets;
    return Padding(
      padding: EdgeInsets.fromLTRB(24, 24, 24, 24 + insets.bottom),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Novo serviço',
              style: TextStyle(
                color: colors.onSurface,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _nameCtrl,
              decoration: const InputDecoration(labelText: 'Nome *'),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Obrigatório' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _priceCtrl,
              decoration: const InputDecoration(
                labelText: 'Preço (R\$) *',
                hintText: 'Ex: 80,00',
              ),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Obrigatório';
                final n = double.tryParse(v.replaceAll(',', '.'));
                if (n == null || n <= 0) return 'Preço inválido';
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _descCtrl,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Descrição (opcional)',
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _submit,
                icon: const Icon(Icons.check),
                label: const Text('Cadastrar'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
