import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:agendo/models/professional_model.dart';
import 'package:agendo/models/service_type_model.dart';
import 'package:agendo/repositories/professional_repository.dart';
import 'package:agendo/repositories/appointment_repository.dart';
import 'package:agendo/models/rating_model.dart';
import 'package:agendo/view_models/auth_view_model.dart';
import 'package:agendo/view_models/rating_view_model.dart';
import 'components/rating_bar_widget.dart';

class BookAppointmentView extends StatefulWidget {
  final ProfessionalModel professional;

  const BookAppointmentView({super.key, required this.professional});

  @override
  State<BookAppointmentView> createState() => _BookAppointmentViewState();
}

class _BookAppointmentViewState extends State<BookAppointmentView> {
  List<ServiceTypeModel> _services = [];
  ServiceTypeModel? _selectedService;
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;

  bool _isLoadingServices = true;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadServices();
      context.read<RatingViewModel>().loadRatings(widget.professional.id);
    });
  }

  Future<void> _loadServices() async {
    try {
      final repo = context.read<ProfessionalRepository>();
      final services = await repo.getProfessionalServices(widget.professional.id);
      if (mounted) {
        setState(() {
        _services = services;
        _isLoadingServices = false;
      });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingServices = false);
    }
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? now.add(const Duration(days: 1)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );
    if (date != null) setState(() => _selectedDate = date);
  }

  Future<void> _pickTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? const TimeOfDay(hour: 9, minute: 0),
    );
    if (time != null) setState(() => _selectedTime = time);
  }

  bool get _canSubmit =>
      _selectedService != null && _selectedDate != null && _selectedTime != null;

  Future<void> _handleSubmit() async {
    if (!_canSubmit) return;

    setState(() => _isSubmitting = true);

    final authUser = context.read<AuthViewModel>().user!;
    final scheduleDate = DateTime(
      _selectedDate!.year,
      _selectedDate!.month,
      _selectedDate!.day,
      _selectedTime!.hour,
      _selectedTime!.minute,
    );

    try {
      final repo = context.read<AppointmentRepository>();
      await repo.createAppointment(
        professionalId: widget.professional.id,
        clientId: authUser.id,
        serviceTypeIds: [_selectedService!.id],
        scheduleDate: scheduleDate,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Agendamento criado com sucesso!')),
      );
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Erro ao criar agendamento'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final pro = widget.professional;

    final isWide = MediaQuery.of(context).size.width >= 900;

    final confirmButton = Padding(
      padding: const EdgeInsets.all(24),
      child: ElevatedButton(
        onPressed: (_canSubmit && !_isSubmitting) ? _handleSubmit : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: colors.primary,
          foregroundColor: colors.onPrimary,
          minimumSize: const Size(double.infinity, 56),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          disabledBackgroundColor: colors.primary.withValues(alpha: 0.3),
        ),
        child: _isSubmitting
            ? SizedBox(height: 24, width: 24, child: CircularProgressIndicator(strokeWidth: 2.5, color: colors.onPrimary))
            : const Text('Confirmar Agendamento', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      ),
    );

    if (isWide) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(icon: Icon(Icons.arrow_back, color: colors.onSurface), onPressed: () => Navigator.of(context).pop()),
          title: Text('Novo Agendamento', style: TextStyle(color: colors.onSurface, fontWeight: FontWeight.bold)),
          centerTitle: false,
        ),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1200),
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Left: professional + services
                  Expanded(
                    flex: 5,
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildProfessionalHeader(colors, pro),
                          const SizedBox(height: 28),
                          Text('Selecione o serviço', style: TextStyle(color: colors.onSurface, fontSize: 18, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 12),
                          _buildServicesList(colors),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 32),
                  // Right: date, time, summary, button
                  Expanded(
                    flex: 4,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text('Data e Horário', style: TextStyle(color: colors.onSurface, fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(child: _buildDateButton(colors)),
                            const SizedBox(width: 12),
                            Expanded(child: _buildTimeButton(colors)),
                          ],
                        ),
                        const SizedBox(height: 28),
                        if (_canSubmit) ...[
                          _buildSummary(colors, pro),
                          const SizedBox(height: 28),
                        ],
                        Expanded(
                          child: SingleChildScrollView(
                            child: _buildRatingsSection(colors),
                          ),
                        ),
                        const SizedBox(height: 16),
                        confirmButton,
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(icon: Icon(Icons.arrow_back, color: colors.onSurface), onPressed: () => Navigator.of(context).pop()),
      ),
      bottomNavigationBar: confirmButton,
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildProfessionalHeader(colors, pro),
            const SizedBox(height: 28),
            Text('Selecione o serviço', style: TextStyle(color: colors.onSurface, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            _buildServicesList(colors),
            const SizedBox(height: 28),
            Text('Data e Horário', style: TextStyle(color: colors.onSurface, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Row(children: [Expanded(child: _buildDateButton(colors)), const SizedBox(width: 12), Expanded(child: _buildTimeButton(colors))]),
            const SizedBox(height: 28),
            if (_canSubmit) ...[
              _buildSummary(colors, pro),
              const SizedBox(height: 28),
            ],
            _buildRatingsSection(colors),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildProfessionalHeader(ColorScheme colors, ProfessionalModel pro) {
    return Card(
      elevation: 0,
      color: colors.onSurface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            CircleAvatar(
              radius: 34,
              backgroundColor: colors.primary.withValues(alpha: 0.2),
              child: Text(
                pro.name[0].toUpperCase(),
                style: TextStyle(
                  color: colors.primary,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    pro.name,
                    style: TextStyle(
                      color: colors.surface,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    pro.professionName,
                    style: TextStyle(
                      color: colors.primary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (pro.bio != null && pro.bio!.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      pro.bio!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: colors.surface.withValues(alpha: 0.6),
                        fontSize: 13,
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
                  Builder(builder: (ctx) {
                    final ratingVm = ctx.watch<RatingViewModel>();
                    final average = ratingVm.averageFor(pro.id);
                    final isLoading = ratingVm.isLoadingFor(pro.id);
                    return Row(
                      children: [
                        if (isLoading)
                          SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                                strokeWidth: 1.5, color: Colors.amber),
                          )
                        else
                          RatingBarWidget(
                              rating: average ?? 0.0, size: 16),
                        const SizedBox(width: 6),
                        Text(
                          average != null
                              ? average.toStringAsFixed(1)
                              : 'Sem avaliações',
                          style: TextStyle(
                            color: colors.surface.withValues(alpha: 0.8),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    );
                  }),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildServicesList(ColorScheme colors) {
    if (_isLoadingServices) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: CircularProgressIndicator(color: colors.primary),
        ),
      );
    }

    if (_services.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          'Nenhum serviço disponível',
          style: TextStyle(color: colors.onSurface.withValues(alpha: 0.5)),
        ),
      );
    }

    return Column(
      children: _services.map((service) {
        final isSelected = _selectedService?.id == service.id;
        return GestureDetector(
          onTap: () => setState(() => _selectedService = service),
          child: Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isSelected
                  ? colors.primary.withValues(alpha: 0.12)
                  : colors.onSurface.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isSelected ? colors.primary : Colors.transparent,
                width: 2,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? colors.primary.withValues(alpha: 0.2)
                        : colors.onSurface.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.design_services,
                    color: isSelected ? colors.primary : colors.onSurface.withValues(alpha: 0.5),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        service.name,
                        style: TextStyle(
                          color: colors.onSurface,
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                      if (service.description != null && service.description!.isNotEmpty)
                        Text(
                          service.description!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: colors.onSurface.withValues(alpha: 0.5),
                            fontSize: 13,
                          ),
                        ),
                    ],
                  ),
                ),
                if (service.price != null)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Text(
                      service.formattedPrice,
                      style: TextStyle(
                        color: isSelected ? colors.primary : colors.onSurface,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                if (isSelected)
                  Icon(Icons.check_circle, color: colors.primary, size: 22),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildDateButton(ColorScheme colors) {
    final hasDate = _selectedDate != null;
    return GestureDetector(
      onTap: _pickDate,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        decoration: BoxDecoration(
          color: hasDate
              ? colors.primary.withValues(alpha: 0.12)
              : colors.onSurface.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: hasDate ? colors.primary : Colors.transparent,
            width: hasDate ? 2 : 0,
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.calendar_today,
              size: 20,
              color: hasDate ? colors.primary : colors.onSurface.withValues(alpha: 0.5),
            ),
            const SizedBox(width: 10),
            Flexible(
              child: Text(
                hasDate
                    ? '${_selectedDate!.day.toString().padLeft(2, '0')}/${_selectedDate!.month.toString().padLeft(2, '0')}/${_selectedDate!.year}'
                    : 'Selecionar data',
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: hasDate ? colors.onSurface : colors.onSurface.withValues(alpha: 0.5),
                  fontWeight: hasDate ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeButton(ColorScheme colors) {
    final hasTime = _selectedTime != null;
    return GestureDetector(
      onTap: _pickTime,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        decoration: BoxDecoration(
          color: hasTime
              ? colors.primary.withValues(alpha: 0.12)
              : colors.onSurface.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: hasTime ? colors.primary : Colors.transparent,
            width: hasTime ? 2 : 0,
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.access_time,
              size: 20,
              color: hasTime ? colors.primary : colors.onSurface.withValues(alpha: 0.5),
            ),
            const SizedBox(width: 10),
            Flexible(
              child: Text(
                hasTime
                    ? '${_selectedTime!.hour.toString().padLeft(2, '0')}:${_selectedTime!.minute.toString().padLeft(2, '0')}'
                    : 'Selecionar horário',
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: hasTime ? colors.onSurface : colors.onSurface.withValues(alpha: 0.5),
                  fontWeight: hasTime ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRatingsSection(ColorScheme colors) {
    final ratingVm = context.watch<RatingViewModel>();
    final ratings = ratingVm.ratingsFor(widget.professional.id);
    final isLoading = ratingVm.isLoadingFor(widget.professional.id);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Avaliações',
          style: TextStyle(
            color: colors.onSurface,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        if (isLoading)
          Center(child: CircularProgressIndicator(color: colors.primary, strokeWidth: 2))
        else if (ratings.isEmpty)
          Text(
            'Nenhuma avaliação ainda',
            style: TextStyle(color: colors.onSurface.withValues(alpha: 0.4)),
          )
        else
          ...ratings.map((r) => _buildRatingCard(colors, r)),
      ],
    );
  }

  Widget _buildRatingCard(ColorScheme colors, RatingModel r) {
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
              CircleAvatar(
                radius: 14,
                backgroundColor: colors.primary.withValues(alpha: 0.15),
                child: Text(
                  r.clientName.isNotEmpty ? r.clientName[0].toUpperCase() : '?',
                  style: TextStyle(
                    color: colors.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  r.clientName,
                  style: TextStyle(
                    color: colors.onSurface,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
              RatingBarWidget(rating: r.score.toDouble(), size: 13),
            ],
          ),
          if (r.comment != null && r.comment!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              r.comment!,
              style: TextStyle(
                color: colors.onSurface.withValues(alpha: 0.75),
                fontSize: 13,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSummary(ColorScheme colors, ProfessionalModel pro) {
    final valueInCents = ((_selectedService!.price ?? 0.0) * 100).round();
    final formattedValue = 'R\$ ${(valueInCents / 100).toStringAsFixed(2).replaceAll('.', ',')}';
    final dateStr =
        '${_selectedDate!.day.toString().padLeft(2, '0')}/${_selectedDate!.month.toString().padLeft(2, '0')}/${_selectedDate!.year}';
    final timeStr =
        '${_selectedTime!.hour.toString().padLeft(2, '0')}:${_selectedTime!.minute.toString().padLeft(2, '0')}';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.primary.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Resumo',
            style: TextStyle(
              color: colors.primary,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          _summaryRow(colors, 'Profissional', pro.name),
          _summaryRow(colors, 'Serviço', _selectedService!.name),
          _summaryRow(colors, 'Data', '$dateStr às $timeStr'),
          _summaryRow(colors, 'Valor', formattedValue),
        ],
      ),
    );
  }

  Widget _summaryRow(ColorScheme colors, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(color: colors.onSurface.withValues(alpha: 0.6), fontSize: 14),
          ),
          Text(
            value,
            style: TextStyle(
              color: colors.onSurface,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}
