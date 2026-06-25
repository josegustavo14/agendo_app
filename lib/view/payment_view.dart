import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/appointment_model.dart';
import '../models/payment_model.dart';
import '../view_models/payment_view_model.dart';

/// Tela de pagamento (PIX via AbacatePay) para um agendamento.
///
/// Esta tela só faz sentido para o **cliente**, e a partir do momento em que
/// o agendamento foi APROVADO (a cobrança é criada automaticamente no backend
/// pelo PaymentOnApprovalListener; este endpoint serve para obter a URL).
class PaymentView extends StatefulWidget {
  final AppointmentModel appointment;

  const PaymentView({super.key, required this.appointment});

  @override
  State<PaymentView> createState() => _PaymentViewState();
}

class _PaymentViewState extends State<PaymentView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final vm = context.read<PaymentViewModel>();
      final cached = vm.paymentFor(widget.appointment.id);
      if (cached == null) {
        vm.startBilling(widget.appointment.id);
      }
    });
  }

  @override
  void dispose() {
    // não limpa o cache (paymentByAppointment) — só o estado transiente
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) return;
    });
    super.dispose();
  }

  Future<void> _openPaymentUrl(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não foi possível abrir o link de pagamento')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final vm = context.watch<PaymentViewModel>();
    final cached = vm.paymentFor(widget.appointment.id);
    final payment = cached ??
        (vm.lastAppointmentId == widget.appointment.id ? vm.currentPayment : null);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pagamento'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildAppointmentSummary(colors),
              const SizedBox(height: 24),
              if (vm.isLoading)
                Expanded(
                  child: Center(
                    child: CircularProgressIndicator(color: colors.primary),
                  ),
                )
              else if (vm.state == PaymentRequestState.alreadyExists && payment == null)
                _buildAlreadyExistsMessage(colors, vm)
              else if (payment != null)
                Expanded(child: _buildPaymentReady(colors, payment))
              else if (vm.hasError)
                _buildError(colors, vm)
              else
                const SizedBox.shrink(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppointmentSummary(ColorScheme colors) {
    final a = widget.appointment;
    return Container(
      width: double.infinity,
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
            a.professionalName,
            style: TextStyle(
              color: colors.onSurface,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            a.servicesLabel,
            style: TextStyle(
              color: colors.onSurface.withValues(alpha: 0.7),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Total a pagar',
                  style: TextStyle(color: colors.onSurface.withValues(alpha: 0.6))),
              Text(
                a.formattedValue,
                style: TextStyle(
                  color: colors.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentReady(ColorScheme colors, PaymentModel payment) {
    final (statusLabel, statusColor) = switch (payment.status) {
      'PAID' => ('Pago ✓', Colors.green),
      'PENDING' => ('Aguardando pagamento', Colors.amber),
      'EXPIRED' => ('Cobrança expirada', Colors.grey),
      'CANCELLED' => ('Cancelada', Colors.grey),
      'FAILED' => ('Falhou', colors.error),
      'REFUNDED' => ('Estornada', Colors.blue),
      _ => (payment.status, colors.onSurface),
    };
    final showPayButton = payment.isPending;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Icon(
          payment.isPaid ? Icons.check_circle : Icons.qr_code_2,
          size: 96,
          color: payment.isPaid ? Colors.green : colors.primary,
        ),
        const SizedBox(height: 16),
        Text(
          payment.isPaid ? 'Pagamento confirmado' : 'Cobrança PIX gerada',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: colors.onSurface,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          statusLabel,
          textAlign: TextAlign.center,
          style: TextStyle(color: statusColor, fontWeight: FontWeight.w600),
        ),
        const Spacer(),
        if (showPayButton)
          ElevatedButton.icon(
            onPressed: () => _openPaymentUrl(payment.paymentUrl),
            icon: const Icon(Icons.open_in_new),
            label: const Text('Abrir página de pagamento'),
            style: ElevatedButton.styleFrom(
              backgroundColor: colors.primary,
              foregroundColor: colors.onPrimary,
              minimumSize: const Size(double.infinity, 56),
              shape:
                  RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
          ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: () => context
              .read<PaymentViewModel>()
              .refreshStatus(widget.appointment.id),
          icon: const Icon(Icons.refresh),
          label: const Text('Atualizar status'),
        ),
        const SizedBox(height: 12),
        Text(
          'Após o pagamento, o status é atualizado pelo webhook da AbacatePay. '
          'Toque em "Atualizar status" se já pagou.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: colors.onSurface.withValues(alpha: 0.5),
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildAlreadyExistsMessage(ColorScheme colors, PaymentViewModel vm) {
    return Expanded(
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.info_outline, size: 64, color: colors.primary),
            const SizedBox(height: 16),
            Text(
              'Cobrança já existe para este agendamento',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: colors.onSurface,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                vm.errorMessage ?? '',
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: colors.onSurface.withValues(alpha: 0.6), fontSize: 13),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildError(ColorScheme colors, PaymentViewModel vm) {
    return Expanded(
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 64, color: colors.error),
            const SizedBox(height: 16),
            Text(
              vm.errorMessage ?? 'Erro ao gerar cobrança',
              textAlign: TextAlign.center,
              style: TextStyle(color: colors.onSurface),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () => vm.startBilling(widget.appointment.id),
              icon: const Icon(Icons.refresh),
              label: const Text('Tentar novamente'),
            ),
          ],
        ),
      ),
    );
  }
}
