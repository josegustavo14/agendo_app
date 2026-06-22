import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:agendo/models/profession_model.dart';
import 'package:agendo/models/professional_model.dart';
import 'package:agendo/repositories/professional_repository.dart';
import 'package:agendo/view/book_appointment_view.dart';

class SelectProfessionalView extends StatefulWidget {
  const SelectProfessionalView({super.key});

  @override
  State<SelectProfessionalView> createState() => _SelectProfessionalViewState();
}

class _SelectProfessionalViewState extends State<SelectProfessionalView> {
  final _searchController = TextEditingController();

  List<ProfessionModel> _professions = [];
  List<ProfessionalModel> _professionals = [];
  int? _selectedProfessionId;
  bool _isLoadingProfessions = true;
  bool _isLoadingProfessionals = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadProfessions();
      _searchProfessionals();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadProfessions() async {
    try {
      final repo = context.read<ProfessionalRepository>();
      final professions = await repo.fetchProfessions();
      if (mounted) {
        setState(() {
        _professions = professions;
        _isLoadingProfessions = false;
      });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingProfessions = false);
    }
  }

  Future<void> _searchProfessionals() async {
    setState(() => _isLoadingProfessionals = true);
    try {
      final repo = context.read<ProfessionalRepository>();
      final professionals = await repo.searchProfessionals(
        name: _searchController.text.trim().isNotEmpty
            ? _searchController.text.trim()
            : null,
        professionId: _selectedProfessionId,
      );
      if (mounted) {
        setState(() {
        _professionals = professionals;
        _isLoadingProfessionals = false;
      });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingProfessionals = false);
    }
  }

  Future<void> _navigateToBook(int index) async {
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => BookAppointmentView(professional: _professionals[index]),
      ),
    );
    if (created == true && mounted) {
      Navigator.of(context).pop(true);
    }
  }

  void _onProfessionTap(int professionId) {
    setState(() {
      _selectedProfessionId =
          _selectedProfessionId == professionId ? null : professionId;
    });
    _searchProfessionals();
  }

  void _onSearch(String _) {
    _searchProfessionals();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: colors.onSurface),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Agendar',
          style: TextStyle(color: colors.onSurface, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Barra de busca
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: TextField(
              controller: _searchController,
              onSubmitted: _onSearch,
              style: TextStyle(color: colors.onSurface),
              decoration: InputDecoration(
                hintText: 'Buscar profissional...',
                hintStyle: TextStyle(color: colors.onSurface.withValues(alpha: 0.4)),
                prefixIcon: Icon(Icons.search, color: colors.onSurface.withValues(alpha: 0.4)),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.clear, color: colors.onSurface.withValues(alpha: 0.4)),
                        onPressed: () {
                          _searchController.clear();
                          _searchProfessionals();
                        },
                      )
                    : null,
                filled: true,
                fillColor: colors.onSurface.withValues(alpha: 0.05),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: colors.primary, width: 2),
                ),
              ),
            ),
          ),

          // Chips de profissão
          if (!_isLoadingProfessions && _professions.isNotEmpty)
            SizedBox(
              height: 48,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 24),
                itemCount: _professions.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final profession = _professions[index];
                  final isSelected = _selectedProfessionId == profession.id;
                  return FilterChip(
                    label: Text(profession.name),
                    selected: isSelected,
                    onSelected: (_) => _onProfessionTap(profession.id),
                    selectedColor: colors.primary,
                    backgroundColor: colors.onSurface.withValues(alpha: 0.05),
                    labelStyle: TextStyle(
                      color: isSelected ? colors.onPrimary : colors.onSurface,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                    checkmarkColor: colors.onPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color: isSelected ? colors.primary : Colors.transparent,
                      ),
                    ),
                  );
                },
              ),
            ),

          const SizedBox(height: 16),

          // Lista de profissionais
          Expanded(
            child: _isLoadingProfessionals
                ? Center(child: CircularProgressIndicator(color: colors.primary))
                : _professionals.isEmpty
                    ? Center(
                        child: Text(
                          'Nenhum profissional encontrado',
                          style: TextStyle(color: colors.onSurface.withValues(alpha: 0.5)),
                        ),
                      )
                    : LayoutBuilder(
                        builder: (context, constraints) {
                          final isWide = constraints.maxWidth >= 800;
                          if (isWide) {
                            return GridView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
                              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: constraints.maxWidth >= 1200 ? 3 : 2,
                                crossAxisSpacing: 16,
                                mainAxisSpacing: 16,
                                // Cards mais cheios em wide pra dar respiro
                                // ao conteúdo e evitar fonte minúscula relativa.
                                childAspectRatio: 3.3,
                              ),
                              itemCount: _professionals.length,
                              itemBuilder: (context, index) => _ProfessionalCard(
                                professional: _professionals[index],
                                onTap: () => _navigateToBook(index),
                              ),
                            );
                          }
                          return ListView.separated(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            itemCount: _professionals.length,
                            separatorBuilder: (_, _) => const SizedBox(height: 12),
                            itemBuilder: (context, index) => _ProfessionalCard(
                              professional: _professionals[index],
                              onTap: () => _navigateToBook(index),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

class _ProfessionalCard extends StatelessWidget {
  final ProfessionalModel professional;
  final VoidCallback onTap;

  const _ProfessionalCard({required this.professional, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    // Em wide o card ocupa colunas grandes da grid; sem escala as fontes
    // mobile (17/13/12) viram letrinha minúscula relativa ao card.
    final isWide = MediaQuery.of(context).size.width >= 800;
    final scale = isWide ? 1.35 : 1.0;

    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: 0,
        color: colors.onSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: EdgeInsets.all(isWide ? 20 : 16),
          child: Row(
            children: [
              // Avatar
              CircleAvatar(
                radius: isWide ? 36 : 28,
                backgroundColor: colors.primary.withValues(alpha: 0.2),
                child: Text(
                  professional.name.isNotEmpty ? professional.name[0].toUpperCase() : '?',
                  style: TextStyle(
                    color: colors.primary,
                    fontSize: 22 * scale,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              SizedBox(width: isWide ? 18 : 14),

              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      professional.name,
                      style: TextStyle(
                        color: colors.surface,
                        fontSize: 17 * scale,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      professional.professionName,
                      style: TextStyle(
                        color: colors.primary,
                        fontSize: 13 * scale,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                    if (professional.bio != null && professional.bio!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        professional.bio!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: colors.surface.withValues(alpha: 0.6),
                          fontSize: 13 * scale,
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // Rating + Price
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.star, size: 16 * scale, color: Colors.amber),
                      const SizedBox(width: 2),
                      Text(
                        professional.ratingAverage.toStringAsFixed(1),
                        style: TextStyle(
                          color: colors.surface,
                          fontWeight: FontWeight.bold,
                          fontSize: 13 * scale,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'R\$ ${professional.hourlyRate.toStringAsFixed(0)}/h',
                    style: TextStyle(
                      color: colors.surface.withValues(alpha: 0.7),
                      fontSize: 12 * scale,
                    ),
                  ),
                ],
              ),

              const SizedBox(width: 4),
              Icon(Icons.chevron_right,
                  size: 24 * (isWide ? 1.2 : 1.0),
                  color: colors.surface.withValues(alpha: 0.4)),
            ],
          ),
        ),
      ),
    );
  }
}
