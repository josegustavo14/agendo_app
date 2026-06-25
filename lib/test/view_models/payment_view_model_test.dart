import 'package:agendo/models/payment_model.dart';
import 'package:agendo/repositories/payment_repository.dart';
import 'package:agendo/view_models/payment_view_model.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockPaymentRepository extends Mock implements PaymentRepository {}

PaymentModel _payment({
  String id = 'bill_1',
  String status = 'PENDING',
  int amount = 5000,
}) =>
    PaymentModel(
      id: id,
      paymentUrl: 'https://abacatepay.com/pay/$id',
      status: status,
      amountInCents: amount,
    );

void main() {
  late MockPaymentRepository repository;
  late PaymentViewModel viewModel;

  setUp(() {
    repository = MockPaymentRepository();
    viewModel = PaymentViewModel(repository: repository);
  });

  group('PaymentViewModel', () {
    test('starts in idle state with no payment', () {
      expect(viewModel.state, PaymentRequestState.idle);
      expect(viewModel.currentPayment, isNull);
      expect(viewModel.errorMessage, isNull);
      expect(viewModel.paymentByAppointment, isEmpty);
      expect(viewModel.isLoading, isFalse);
      expect(viewModel.hasError, isFalse);
    });

    test('startBilling notifies listeners on loading and on completion',
        () async {
      when(() => repository.createBillingForAppointment(1))
          .thenAnswer((_) async => _payment());

      var notifications = 0;
      viewModel.addListener(() => notifications++);

      await viewModel.startBilling(1);

      // Pelo menos uma notificação de "loading" e uma de "ready".
      expect(notifications, greaterThanOrEqualTo(2));
    });

    test('startBilling generic failure transitions to error', () async {
      when(() => repository.createBillingForAppointment(1))
          .thenThrow(Exception('boom'));

      final ok = await viewModel.startBilling(1);

      expect(ok, isFalse);
      expect(viewModel.state, PaymentRequestState.error);
      expect(viewModel.hasError, isTrue);
      expect(viewModel.errorMessage, 'Erro ao gerar cobrança');
    });

    test('loadBillings populates list on success', () async {
      final list = [_payment(id: 'a'), _payment(id: 'b')];
      when(() => repository.listBillings()).thenAnswer((_) async => list);

      await viewModel.loadBillings();

      expect(viewModel.billings, list);
      expect(viewModel.isLoadingBillings, isFalse);
    });

    test('loadBillings resets to empty list on failure', () async {
      when(() => repository.listBillings()).thenThrow(Exception('boom'));

      await viewModel.loadBillings();

      expect(viewModel.billings, isEmpty);
      expect(viewModel.isLoadingBillings, isFalse);
    });
  });

  group('PaymentModel', () {
    test('parses both wrapped and flat AbacatePay responses', () {
      final wrapped = PaymentModel.fromJson({
        'data': {
          'id': 'bill_1',
          'url': 'https://x/pay/1',
          'status': 'PAID',
          'amount': 12345,
          'methods': ['PIX'],
        }
      });
      final flat = PaymentModel.fromJson({
        'id': 'bill_2',
        'paymentUrl': 'https://x/pay/2',
        'status': 'PENDING',
        'amountInCents': 999,
      });

      expect(wrapped.id, 'bill_1');
      expect(wrapped.isPaid, isTrue);
      expect(wrapped.amount, closeTo(123.45, 1e-6));
      expect(wrapped.methods, ['PIX']);

      expect(flat.id, 'bill_2');
      expect(flat.paymentUrl, 'https://x/pay/2');
      expect(flat.amountInCents, 999);
    });

    test('formattedAmount formats centavos correctly', () {
      final p = PaymentModel(
        id: 'x',
        paymentUrl: 'u',
        status: 'PENDING',
        amountInCents: 8050,
      );
      expect(p.formattedAmount, r'R$ 80,50');
    });
  });
}
