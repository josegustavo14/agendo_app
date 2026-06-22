import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/profession_model.dart';
import '../repositories/professional_repository.dart';
import 'select_professional_view.dart';

class SelectProfessionView extends StatefulWidget {
  const SelectProfessionView({super.key});

  @override
  State<SelectProfessionView> createState() => _SelectProfessionViewState();
}

class _SelectProfessionViewState extends State<SelectProfessionView> {
  List<ProfessionModel> _professions = [];
  bool _isLoading = true;

  static const _icons = <String, IconData>{
    'Eletricista': Icons.bolt,
    'Desenvolvedor': Icons.code,
    'Encanador': Icons.plumbing,
    'Designer': Icons.palette,
    'Personal Trainer': Icons.fitness_center,
    'Pintor': Icons.format_paint,
    'Marceneiro': Icons.handyman,
    'Fotógrafo': Icons.camera_alt,
  };

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _loadProfessions());
  }

  Future<void> _loadProfessions() async {
    try {
      final professions =
          await context.read<ProfessionalRepository>().fetchProfessions();
      if (mounted) setState(() { _professions = professions; _isLoading = false; });
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isWide = MediaQuery.of(context).size.width >= 600;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Navigator.of(context).canPop()
            ? IconButton(
                icon: Icon(Icons.arrow_back, color: colors.onSurface),
                onPressed: () => Navigator.of(context).pop(),
              )
            : null,
        title: Text(
          'Qual serviço você precisa?',
          style:
              TextStyle(color: colors.onSurface, fontWeight: FontWeight.bold),
        ),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: colors.primary))
          : _professions.isEmpty
              ? Center(
                  child: Text(
                    'Nenhuma profissão encontrada',
                    style: TextStyle(
                        color: colors.onSurface.withValues(alpha: 0.5)),
                  ),
                )
              : GridView.builder(
                  padding: const EdgeInsets.all(24),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: isWide ? 4 : 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 1.1,
                  ),
                  itemCount: _professions.length,
                  itemBuilder: (ctx, i) {
                    final p = _professions[i];
                    return _ProfessionCard(
                      profession: p,
                      icon: _icons[p.name] ?? Icons.work_outline,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => SelectProfessionalView(
                            professionId: p.id,
                            professionName: p.name,
                          ),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}

class _ProfessionCard extends StatelessWidget {
  final ProfessionModel profession;
  final IconData icon;
  final VoidCallback onTap;

  const _ProfessionCard({
    required this.profession,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: colors.onSurface.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colors.onSurface.withValues(alpha: 0.08)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: colors.primary.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: colors.primary, size: 28),
            ),
            const SizedBox(height: 10),
            Text(
              profession.name,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: colors.onSurface,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
