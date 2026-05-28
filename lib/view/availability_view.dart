import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/day_schedule_model.dart';
import '../repositories/availability_repository.dart';

class AvailabilityView extends StatefulWidget {
  const AvailabilityView({super.key});

  @override
  State<AvailabilityView> createState() => _AvailabilityViewState();
}

class _AvailabilityViewState extends State<AvailabilityView> {
  bool _isLoading = true;
  bool _isSaving = false;

  // State per day: enabled, startTime, endTime, slotDuration
  final Map<String, bool> _enabled = {};
  final Map<String, TimeOfDay> _startTimes = {};
  final Map<String, TimeOfDay> _endTimes = {};
  final Map<String, int> _durations = {};

  static const List<int> _durationOptions = [30, 60, 90, 120];

  @override
  void initState() {
    super.initState();
    for (final day in DayScheduleModel.orderedDays) {
      _enabled[day] = false;
      _startTimes[day] = const TimeOfDay(hour: 9, minute: 0);
      _endTimes[day] = const TimeOfDay(hour: 18, minute: 0);
      _durations[day] = 60;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    try {
      final schedule = await context.read<AvailabilityRepository>().getWeeklySchedule();
      for (final d in schedule) {
        _enabled[d.dayOfWeek] = true;
        _startTimes[d.dayOfWeek] = _parseTime(d.startTime);
        _endTimes[d.dayOfWeek] = _parseTime(d.endTime);
        _durations[d.dayOfWeek] = d.slotDurationMinutes;
      }
    } catch (_) {}
    if (mounted) setState(() => _isLoading = false);
  }

  TimeOfDay _parseTime(String t) {
    final parts = t.split(':');
    return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
  }

  String _fmtTime(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  Future<void> _pickTime(String day, bool isStart) async {
    final initial = isStart ? _startTimes[day]! : _endTimes[day]!;
    final picked = await showTimePicker(context: context, initialTime: initial);
    if (picked == null || !mounted) return;
    setState(() {
      if (isStart) {
        _startTimes[day] = picked;
      } else {
        _endTimes[day] = picked;
      }
    });
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);
    try {
      final schedule = DayScheduleModel.orderedDays
          .where((d) => _enabled[d] == true)
          .map((d) => DayScheduleModel(
                dayOfWeek: d,
                startTime: _fmtTime(_startTimes[d]!),
                endTime: _fmtTime(_endTimes[d]!),
                slotDurationMinutes: _durations[d]!,
              ))
          .toList();

      await context.read<AvailabilityRepository>().saveWeeklySchedule(schedule);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Horários salvos com sucesso!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Erro ao salvar horários'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    if (_isLoading) {
      return Center(child: CircularProgressIndicator(color: colors.primary));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 4),
          child: Text(
            'Minha Disponibilidade',
            style: TextStyle(
              color: colors.onSurface,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
          child: Text(
            'Configure os dias e horários em que você atende.',
            style: TextStyle(color: colors.onSurface.withValues(alpha: 0.5), fontSize: 13),
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            children: [
              ...DayScheduleModel.orderedDays.map((day) => _buildDayCard(colors, day)),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colors.primary,
                    foregroundColor: colors.onPrimary,
                    minimumSize: const Size(double.infinity, 52),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    disabledBackgroundColor: colors.primary.withValues(alpha: 0.3),
                  ),
                  child: _isSaving
                      ? SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: colors.onPrimary),
                        )
                      : const Text('Salvar horários', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDayCard(ColorScheme colors, String day) {
    final isOn = _enabled[day]!;
    final label = DayScheduleModel.dayLabels[day]!;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isOn
            ? colors.primary.withValues(alpha: 0.07)
            : colors.onSurface.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isOn ? colors.primary.withValues(alpha: 0.3) : Colors.transparent,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                label,
                style: TextStyle(
                  color: colors.onSurface,
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
              const Spacer(),
              Switch(
                value: isOn,
                onChanged: (v) => setState(() => _enabled[day] = v),
                activeThumbColor: colors.primary,
              ),
            ],
          ),
          if (isOn) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _timeButton(
                    colors,
                    label: 'Início',
                    time: _startTimes[day]!,
                    onTap: () => _pickTime(day, true),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _timeButton(
                    colors,
                    label: 'Fim',
                    time: _endTimes[day]!,
                    onTap: () => _pickTime(day, false),
                  ),
                ),
                const SizedBox(width: 10),
                _durationPicker(colors, day),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _timeButton(ColorScheme colors, {required String label, required TimeOfDay time, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        decoration: BoxDecoration(
          color: colors.onSurface.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(color: colors.onSurface.withValues(alpha: 0.5), fontSize: 11)),
            const SizedBox(height: 2),
            Text(
              _fmtTime(time),
              style: TextStyle(color: colors.onSurface, fontWeight: FontWeight.w600, fontSize: 15),
            ),
          ],
        ),
      ),
    );
  }

  Widget _durationPicker(ColorScheme colors, String day) {
    return DropdownButtonHideUnderline(
      child: DropdownButton<int>(
        value: _durations[day],
        dropdownColor: colors.surface,
        style: TextStyle(color: colors.onSurface, fontSize: 13),
        items: _durationOptions
            .map((d) => DropdownMenuItem(
                  value: d,
                  child: Text('${d}min'),
                ))
            .toList(),
        onChanged: (v) {
          if (v != null) setState(() => _durations[day] = v);
        },
      ),
    );
  }
}
