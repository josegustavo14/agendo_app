import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/rating_model.dart';
import '../view_models/rating_view_model.dart';
import '../view_models/auth_view_model.dart';
import 'components/rating_bar_widget.dart';

class RatingsView extends StatefulWidget {
  final int professionalId;
  final String professionalName;
  final bool canSubmit;

  const RatingsView({
    super.key,
    required this.professionalId,
    required this.professionalName,
    this.canSubmit = false,
  });

  @override
  State<RatingsView> createState() => _RatingsViewState();
}

class _RatingsViewState extends State<RatingsView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      debugPrint('[RatingsView] Carregando avaliações para professionalId=${widget.professionalId}');
      context.read<RatingViewModel>().loadRatings(widget.professionalId);
    });
  }

  void _showRatingDialog() {
    showDialog(
      context: context,
      builder: (ctx) => _RatingDialog(
        professionalId: widget.professionalId,
        professionalName: widget.professionalName,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final vm = context.watch<RatingViewModel>();
    final ratings = vm.ratingsFor(widget.professionalId);
    final average = vm.averageFor(widget.professionalId);
    final isLoading = vm.isLoadingFor(widget.professionalId);
    final userRole = context.read<AuthViewModel>().user?.role;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: colors.onSurface),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Avaliações',
          style: TextStyle(color: colors.onSurface, fontWeight: FontWeight.bold),
        ),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator(color: colors.primary))
          : CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        Text(
                          widget.professionalName,
                          style: TextStyle(
                            color: colors.onSurface,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        if (average != null) ...[
                          Text(
                            average.toStringAsFixed(1),
                            style: TextStyle(
                              color: colors.onSurface,
                              fontSize: 48,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          RatingBarWidget(rating: average, size: 28),
                          const SizedBox(height: 4),
                          Text(
                            '${ratings.length} avaliação${ratings.length != 1 ? 'ões' : ''}',
                            style: TextStyle(
                              color: colors.onSurface.withValues(alpha: 0.5),
                              fontSize: 13,
                            ),
                          ),
                        ] else ...[
                          Text(
                            'Sem avaliações ainda',
                            style: TextStyle(
                              color: colors.onSurface.withValues(alpha: 0.5),
                            ),
                          ),
                        ],
                        if (widget.canSubmit && userRole == 'CLIENT') ...[
                          const SizedBox(height: 20),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: _showRatingDialog,
                              icon: const Icon(Icons.star_outline),
                              label: const Text('Avaliar profissional'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: colors.primary,
                                foregroundColor: colors.onPrimary,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                if (ratings.isEmpty)
                  SliverFillRemaining(
                    child: Center(
                      child: Text(
                        'Nenhuma avaliação encontrada',
                        style:
                            TextStyle(color: colors.onSurface.withValues(alpha: 0.4)),
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (ctx, i) => _RatingCard(rating: ratings[i]),
                        childCount: ratings.length,
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
}

class _RatingCard extends StatelessWidget {
  final RatingModel rating;
  const _RatingCard({required this.rating});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.onSurface.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                rating.clientName,
                style: TextStyle(
                  color: colors.onSurface,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              RatingBarWidget(rating: rating.score.toDouble(), size: 14),
            ],
          ),
          if (rating.comment != null && rating.comment!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              rating.comment!,
              style: TextStyle(
                color: colors.onSurface.withValues(alpha: 0.7),
                fontSize: 14,
              ),
            ),
          ],
          const SizedBox(height: 6),
          Text(
            '${rating.createdAt.day.toString().padLeft(2, '0')}/${rating.createdAt.month.toString().padLeft(2, '0')}/${rating.createdAt.year}',
            style: TextStyle(
              color: colors.onSurface.withValues(alpha: 0.4),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _RatingDialog extends StatefulWidget {
  final int professionalId;
  final String professionalName;
  const _RatingDialog({required this.professionalId, required this.professionalName});

  @override
  State<_RatingDialog> createState() => _RatingDialogState();
}

class _RatingDialogState extends State<_RatingDialog> {
  int _score = 0;
  final _commentController = TextEditingController();

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final vm = context.watch<RatingViewModel>();

    return AlertDialog(
      backgroundColor: colors.surface,
      title: Text(
        'Avaliar ${widget.professionalName}',
        style: TextStyle(color: colors.onSurface),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          InteractiveRatingBar(
            value: _score,
            onChanged: (v) => setState(() => _score = v),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _commentController,
            maxLines: 3,
            style: TextStyle(color: colors.onSurface),
            decoration: InputDecoration(
              hintText: 'Comentário (opcional)',
              hintStyle: TextStyle(color: colors.onSurface.withValues(alpha: 0.4)),
              filled: true,
              fillColor: colors.onSurface.withValues(alpha: 0.05),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('Cancelar', style: TextStyle(color: colors.onSurface)),
        ),
        ElevatedButton(
          onPressed: _score == 0 || vm.isSubmitting
              ? null
              : () async {
                  final ok = await context.read<RatingViewModel>().submitRating(
                        professionalId: widget.professionalId,
                        score: _score,
                        comment: _commentController.text.trim(),
                      );
                  if (!context.mounted) return;
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(ok ? 'Avaliação enviada!' : 'Erro ao enviar avaliação'),
                      backgroundColor: ok ? Colors.green : colors.error,
                    ),
                  );
                },
          style: ElevatedButton.styleFrom(
            backgroundColor: colors.primary,
            foregroundColor: colors.onPrimary,
          ),
          child: vm.isSubmitting
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Text('Enviar'),
        ),
      ],
    );
  }
}
