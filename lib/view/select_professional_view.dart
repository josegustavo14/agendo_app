import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:agendo/models/professional_model.dart';
import 'package:agendo/repositories/professional_repository.dart';
import 'package:agendo/view_models/rating_view_model.dart';
import 'package:agendo/view/book_appointment_view.dart';
import 'package:agendo/view/ratings_view.dart';
import 'components/rating_bar_widget.dart';

class SelectProfessionalView extends StatefulWidget {
  final int professionId;
  final String professionName;

  const SelectProfessionalView({
    super.key,
    required this.professionId,
    required this.professionName,
  });

  @override
  State<SelectProfessionalView> createState() => _SelectProfessionalViewState();
}

class _SelectProfessionalViewState extends State<SelectProfessionalView> {
  final _searchController = TextEditingController();
  List<ProfessionalModel> _professionals = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _search());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    setState(() => _isLoading = true);
    try {
      final repo = context.read<ProfessionalRepository>();
      final results = await repo.searchProfessionals(
        name: _searchController.text.trim().isNotEmpty
            ? _searchController.text.trim()
            : null,
        professionId: widget.professionId,
      );
      if (mounted) {
        setState(() { _professionals = results; _isLoading = false; });
        // Load ratings for all professionals in background
        final ratingVm = context.read<RatingViewModel>();
        for (final p in results) {
          ratingVm.loadRatings(p.id);
        }
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _navigateToBook(ProfessionalModel professional) async {
    final created = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => BookAppointmentView(professional: professional),
      ),
    );
    if (created == true && mounted) {
      Navigator.of(context).pop(true);
    }
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
          widget.professionName,
          style:
              TextStyle(color: colors.onSurface, fontWeight: FontWeight.bold),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: TextField(
              controller: _searchController,
              onSubmitted: (_) => _search(),
              style: TextStyle(color: colors.onSurface),
              decoration: InputDecoration(
                hintText: 'Buscar por nome...',
                hintStyle:
                    TextStyle(color: colors.onSurface.withValues(alpha: 0.4)),
                prefixIcon: Icon(Icons.search,
                    color: colors.onSurface.withValues(alpha: 0.4)),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.clear,
                            color: colors.onSurface.withValues(alpha: 0.4)),
                        onPressed: () {
                          _searchController.clear();
                          _search();
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
          Expanded(
            child: _isLoading
                ? Center(
                    child: CircularProgressIndicator(color: colors.primary))
                : _professionals.isEmpty
                    ? Center(
                        child: Text(
                          'Nenhum profissional encontrado',
                          style: TextStyle(
                              color: colors.onSurface.withValues(alpha: 0.5)),
                        ),
                      )
                    : LayoutBuilder(
                        builder: (ctx, constraints) {
                          if (constraints.maxWidth >= 800) {
                            return GridView.builder(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 24, vertical: 8),
                              gridDelegate:
                                  SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount:
                                    constraints.maxWidth >= 1200 ? 3 : 2,
                                crossAxisSpacing: 16,
                                mainAxisSpacing: 16,
                                // Cards mais cheios em wide pra dar respiro
                                // ao conteúdo e evitar fonte minúscula relativa.
                                childAspectRatio: 3.3,
                              ),
                              itemCount: _professionals.length,
                              itemBuilder: (_, i) => _ProfessionalCard(
                                professional: _professionals[i],
                                onTap: () =>
                                    _navigateToBook(_professionals[i]),
                                onRatingsTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => RatingsView(
                                      professionalId: _professionals[i].id,
                                      professionalName: _professionals[i].name,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }
                          return ListView.separated(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 24, vertical: 8),
                            itemCount: _professionals.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(height: 12),
                            itemBuilder: (_, i) => _ProfessionalCard(
                              professional: _professionals[i],
                              onTap: () => _navigateToBook(_professionals[i]),
                              onRatingsTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => RatingsView(
                                    professionalId: _professionals[i].id,
                                    professionalName: _professionals[i].name,
                                  ),
                                ),
                              ),
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
  final VoidCallback onRatingsTap;

  const _ProfessionalCard({
    required this.professional,
    required this.onTap,
    required this.onRatingsTap,
  });

  @override
  Widget build(BuildContext context) {
    return _buildMobileCard(context);
  }

  Widget _buildMobileCard(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final ratingVm = context.watch<RatingViewModel>();
    final average = ratingVm.averageFor(professional.id);
    final isLoadingRating = ratingVm.isLoadingFor(professional.id);
    // Em wide o card ocupa colunas grandes da grid; sem escala as fontes
    // mobile (16/12/11) viram letrinha minúscula relativa ao card.
    final isWide = MediaQuery.of(context).size.width >= 800;
    final scale = isWide ? 1.35 : 1.0;

    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: 0,
        color: colors.onSurface,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: EdgeInsets.all(isWide ? 20 : 16),
          child: Row(
            children: [
              CircleAvatar(
                radius: isWide ? 36 : 28,
                backgroundColor: colors.primary.withValues(alpha: 0.2),
                child: Text(
                  professional.name.isNotEmpty
                      ? professional.name[0].toUpperCase()
                      : '?',
                  style: TextStyle(
                    color: colors.primary,
                    fontSize: 22 * scale,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              SizedBox(width: isWide ? 18 : 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      professional.name,
                      style: TextStyle(
                        color: colors.surface,
                        fontSize: 16 * scale,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (professional.bio != null &&
                        professional.bio!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        professional.bio!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: colors.surface.withValues(alpha: 0.6),
                          fontSize: 12 * scale,
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: onRatingsTap,
                      child: Row(
                        children: [
                          if (isLoadingRating)
                            SizedBox(
                              width: 14 * scale,
                              height: 14 * scale,
                              child: CircularProgressIndicator(
                                strokeWidth: 1.5,
                                color: Colors.amber,
                              ),
                            )
                          else if (average != null)
                            RatingBarWidget(rating: average, size: 14 * scale)
                          else
                            Icon(Icons.star_border,
                                size: 14 * scale, color: Colors.amber),
                          const SizedBox(width: 4),
                          Text(
                            average != null
                                ? average.toStringAsFixed(1)
                                : 'Sem avaliações',
                            style: TextStyle(
                              color: colors.surface.withValues(alpha: 0.7),
                              fontSize: 12 * scale,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '· ver avaliações',
                            style: TextStyle(
                              color: colors.primary,
                              fontSize: 11 * scale,
                              decoration: TextDecoration.underline,
                              decorationColor: colors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
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
