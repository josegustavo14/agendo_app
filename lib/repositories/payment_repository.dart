import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:agendo/models/payment_model.dart';
import 'package:agendo/services/api_service.dart';

/// Exceção lançada quando o backend responde 409 (já existe cobrança).
/// Mantém a mensagem do servidor — geralmente contém o billingId existente.
class PaymentAlreadyExistsException implements Exception {
  final String message;
  PaymentAlreadyExistsException(this.message);
  @override
  String toString() => message;
}

/// Acesso aos endpoints de pagamento (`/payments/*`) do backend Agendo,
/// que por sua vez integra com a AbacatePay (gateway PIX).
class PaymentRepository {
  final ApiService apiService;

  PaymentRepository({required this.apiService});

  /// Busca a cobrança existente para um agendamento.
  /// Retorna `null` se ainda não há cobrança (404 do backend).
  ///
  /// Este é o endpoint a chamar primeiro na tela de pagamento: como o
  /// backend cria a cobrança automaticamente quando o profissional aprova,
  /// normalmente já existe e o cliente só precisa LER a URL.
  Future<PaymentModel?> getByAppointment(int appointmentId) async {
    final response = await apiService.get('/payments/by-appointment/$appointmentId');

    debugPrint('[PaymentRepository] GET /payments/by-appointment/$appointmentId '
        'status: ${response.statusCode}');

    if (response.statusCode == 200) {
      return PaymentModel.fromJson(jsonDecode(response.body));
    }
    if (response.statusCode == 404) {
      return null; // sem cobrança ainda
    }
    throw Exception(
      'Erro ao buscar cobrança: ${response.statusCode} ${response.body}',
    );
  }

  /// Gera (ou re-tenta gerar) a cobrança PIX de um agendamento.
  ///
  /// O backend deriva valor e cliente do próprio agendamento; o usuário
  /// autenticado precisa ser o cliente daquele agendamento (controlado pelo
  /// JWT no header). Retorna 200 com PaymentModel.
  ///
  /// Em caso de cobrança já existente, o backend devolve 409 e a lançamos
  /// como [PaymentAlreadyExistsException] para a viewmodel tratar de forma
  /// específica (ex: mostrar "já existe — verifique seu e-mail").
  Future<PaymentModel> createBillingForAppointment(int appointmentId) async {
    final response =
        await apiService.post('/payments/billing/appointment/$appointmentId');

    debugPrint('[PaymentRepository] POST /payments/billing/appointment/$appointmentId '
        'status: ${response.statusCode}');
    debugPrint('[PaymentRepository] body: ${response.body}');

    if (response.statusCode == 200) {
      return PaymentModel.fromJson(jsonDecode(response.body));
    }
    if (response.statusCode == 409) {
      throw PaymentAlreadyExistsException(_extractMessage(response.body));
    }
    throw Exception(
      'Erro ao gerar cobrança: ${response.statusCode} ${response.body}',
    );
  }

  /// Lista TODAS as cobranças da conta AbacatePay (uso administrativo).
  ///
  /// O endpoint não é por usuário — útil principalmente para suporte/relatórios.
  Future<List<PaymentModel>> listBillings() async {
    final response = await apiService.get('/payments/billing');

    debugPrint('[PaymentRepository] GET /payments/billing status: ${response.statusCode}');

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      final List<dynamic> data = decoded is Map<String, dynamic>
          ? (decoded['data'] as List<dynamic>? ?? const [])
          : decoded as List<dynamic>;
      return data
          .whereType<Map<String, dynamic>>()
          .map((json) => PaymentModel.fromJson(json))
          .toList();
    }
    throw Exception(
      'Erro ao listar cobranças: ${response.statusCode} ${response.body}',
    );
  }

  String _extractMessage(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) {
        return (decoded['message'] ?? decoded['error'] ?? body).toString();
      }
    } catch (_) {}
    return body;
  }
}
