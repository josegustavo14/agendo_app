import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:agendo/models/user_model.dart';
import 'package:agendo/models/service_type_model.dart';
import 'package:agendo/view_models/auth_view_model.dart';
import 'package:agendo/view_models/create_appointment_view_model.dart';
import 'package:agendo/repositories/appointment_repository.dart';
import 'package:agendo/repositories/user_repository.dart';
import 'package:agendo/repositories/service_type_repository.dart';

class CreateAppointmentView extends StatefulWidget {
  const CreateAppointmentView({super.key});

  @override
  State<CreateAppointmentView> createState() => _CreateAppointmentViewState();
}

class _CreateAppointmentViewState extends State<CreateAppointmentView> {
  late final CreateAppointmentViewModel _viewModel;
  final _formKey = GlobalKey<FormState>();
  final _valueController = TextEditingController();

  UserModel? _selectedUser;
  ServiceTypeModel? _selectedService;
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;

  @override
  void initState() {
    super.initState();
    _viewModel = CreateAppointmentViewModel(
      appointmentRepository: context.read<AppointmentRepository>(),
      userRepository: context.read<UserRepository>(),
      serviceTypeRepository: context.read<ServiceTypeRepository>(),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userRole = context.read<AuthViewModel>().user?.role ?? 'CLIENT';
      _viewModel.loadFormData(userRole);
    });
  }

  @override
  void dispose() {
    _valueController.dispose();
    _viewModel.dispose();
    super.dispose();
  }

  String get _userRole =>
      context.read<AuthViewModel>().user?.role ?? 'CLIENT';

  bool get _isProfessional => _userRole == 'PROFESSIONAL';

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? now.add(const Duration(days: 1)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme,
          ),
          child: child!,
        );
      },
    );
    if (date != null) {
      setState(() => _selectedDate = date);
    }
  }

  Future<void> _pickTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? const TimeOfDay(hour: 9, minute: 0),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme,
          ),
          child: child!,
        );
      },
    );
    if (time != null) {
      setState(() => _selectedTime = time);
    }
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedUser == null || _selectedService == null ||
        _selectedDate == null || _selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Preencha todos os campos'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }

    final authUser = context.read<AuthViewModel>().user!;

    final scheduleDate = DateTime(
      _selectedDate!.year,
      _selectedDate!.month,
      _selectedDate!.day,
      _selectedTime!.hour,
      _selectedTime!.minute,
    );

    final success = await _viewModel.createAppointment(
      professionalId: _isProfessional ? authUser.id : _selectedUser!.id,
      clientId: _isProfessional ? _selectedUser!.id : authUser.id,
      serviceTypeIds: [_selectedService!.id],
      scheduleDate: scheduleDate,
    );

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Agendamento criado com sucesso!')),
      );
      Navigator.of(context).pop(true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_viewModel.errorMessage ?? 'Erro ao criar agendamento'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
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
          'Novo Agendamento',
          style: TextStyle(color: colors.onSurface, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: ListenableBuilder(
        listenable: _viewModel,
        builder: (context, _) {
          if (_viewModel.isLoadingData) {
            return Center(
              child: CircularProgressIndicator(color: colors.primary),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Selecionar pessoa
                  Text(
                    _isProfessional ? 'Cliente' : 'Profissional',
                    style: TextStyle(
                      color: colors.onSurface.withValues(alpha: 0.7),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildUserDropdown(colors),
                  const SizedBox(height: 20),

                  // Selecionar serviço
                  Text(
                    'Tipo de Serviço',
                    style: TextStyle(
                      color: colors.onSurface.withValues(alpha: 0.7),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildServiceDropdown(colors),
                  const SizedBox(height: 20),

                  // Valor
                  Text(
                    'Valor (R\$)',
                    style: TextStyle(
                      color: colors.onSurface.withValues(alpha: 0.7),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _valueController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    style: TextStyle(color: colors.onSurface),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[\d,.]')),
                    ],
                    decoration: _inputDecoration(colors, hint: '150,00'),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Informe o valor';
                      }
                      final parsed = double.tryParse(
                        value.replaceAll(',', '.'),
                      );
                      if (parsed == null || parsed <= 0) {
                        return 'Valor inválido';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),

                  // Data e Hora
                  Text(
                    'Data e Horário',
                    style: TextStyle(
                      color: colors.onSurface.withValues(alpha: 0.7),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(child: _buildDateButton(colors)),
                      const SizedBox(width: 12),
                      Expanded(child: _buildTimeButton(colors)),
                    ],
                  ),
                  const SizedBox(height: 40),

                  // Botão Criar
                  ElevatedButton(
                    onPressed: _viewModel.isSubmitting ? null : _handleSubmit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colors.primary,
                      foregroundColor: colors.onPrimary,
                      minimumSize: const Size(double.infinity, 56),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      disabledBackgroundColor: colors.primary.withValues(alpha: 0.5),
                    ),
                    child: _viewModel.isSubmitting
                        ? SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: colors.onPrimary,
                            ),
                          )
                        : const Text(
                            'Criar Agendamento',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildUserDropdown(ColorScheme colors) {
    final users = _isProfessional ? _viewModel.clients : _viewModel.professionals;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: colors.onSurface.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<UserModel>(
          value: _selectedUser,
          isExpanded: true,
          hint: Text(
            _isProfessional ? 'Selecione o cliente' : 'Selecione o profissional',
            style: TextStyle(color: colors.onSurface.withValues(alpha: 0.5)),
          ),
          dropdownColor: colors.surface,
          style: TextStyle(color: colors.onSurface),
          icon: Icon(Icons.keyboard_arrow_down, color: colors.onSurface.withValues(alpha: 0.5)),
          items: users.map((user) {
            return DropdownMenuItem(
              value: user,
              child: Text(user.name),
            );
          }).toList(),
          onChanged: (value) => setState(() => _selectedUser = value),
        ),
      ),
    );
  }

  Widget _buildServiceDropdown(ColorScheme colors) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: colors.onSurface.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<ServiceTypeModel>(
          value: _selectedService,
          isExpanded: true,
          hint: Text(
            'Selecione o serviço',
            style: TextStyle(color: colors.onSurface.withValues(alpha: 0.5)),
          ),
          dropdownColor: colors.surface,
          style: TextStyle(color: colors.onSurface),
          icon: Icon(Icons.keyboard_arrow_down, color: colors.onSurface.withValues(alpha: 0.5)),
          items: _viewModel.serviceTypes.map((service) {
            return DropdownMenuItem(
              value: service,
              child: Text(service.name),
            );
          }).toList(),
          onChanged: (value) => setState(() => _selectedService = value),
        ),
      ),
    );
  }

  Widget _buildDateButton(ColorScheme colors) {
    return GestureDetector(
      onTap: _pickDate,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        decoration: BoxDecoration(
          color: colors.onSurface.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_today, size: 20, color: colors.onSurface.withValues(alpha: 0.5)),
            const SizedBox(width: 8),
            Text(
              _selectedDate != null
                  ? '${_selectedDate!.day.toString().padLeft(2, '0')}/${_selectedDate!.month.toString().padLeft(2, '0')}/${_selectedDate!.year}'
                  : 'Data',
              style: TextStyle(
                color: _selectedDate != null
                    ? colors.onSurface
                    : colors.onSurface.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeButton(ColorScheme colors) {
    return GestureDetector(
      onTap: _pickTime,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        decoration: BoxDecoration(
          color: colors.onSurface.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(Icons.access_time, size: 20, color: colors.onSurface.withValues(alpha: 0.5)),
            const SizedBox(width: 8),
            Text(
              _selectedTime != null
                  ? '${_selectedTime!.hour.toString().padLeft(2, '0')}:${_selectedTime!.minute.toString().padLeft(2, '0')}'
                  : 'Horário',
              style: TextStyle(
                color: _selectedTime != null
                    ? colors.onSurface
                    : colors.onSurface.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(ColorScheme colors, {required String hint}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: colors.onSurface.withValues(alpha: 0.5)),
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
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: colors.error, width: 1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: colors.error, width: 2),
      ),
    );
  }
}
