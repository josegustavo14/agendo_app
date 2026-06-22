/// Representa uma cobrança PIX gerada na AbacatePay e persistida no backend.
///
/// Espelha o DTO BillingResponse do backend: o JSON vem aninhado em `data`
/// porque a AbacatePay devolve `{ "data": {...}, "error": null }`.
class PaymentModel {
  final String id;
  final String paymentUrl;
  final String status; // PENDING | PAID | EXPIRED | CANCELLED | REFUNDED | FAILED
  final int amountInCents;
  final bool devMode;
  final List<String> methods;
  final String? frequency;

  PaymentModel({
    required this.id,
    required this.paymentUrl,
    required this.status,
    required this.amountInCents,
    this.devMode = false,
    this.methods = const [],
    this.frequency,
  });

  /// Aceita três formas de payload:
  ///  - envelope da AbacatePay: `{ "data": { id, url, ... } }` (id é string "bill_xxx")
  ///  - AbacatePay plano: `{ id, url, ... }`
  ///  - PaymentSummaryResponse do nosso backend: `{ id (Long), billingId, paymentUrl, status, amountInCents, appointmentId }`
  ///
  /// `id` do PaymentModel é sempre a referência do gateway (string),
  /// preferindo `billingId` quando presente e caindo pra `id` da AbacatePay.
  factory PaymentModel.fromJson(Map<String, dynamic> json) {
    final root = json['data'] is Map<String, dynamic>
        ? json['data'] as Map<String, dynamic>
        : json;

    final billingId = root['billingId'] ?? root['id'] ?? '';

    return PaymentModel(
      id: billingId.toString(),
      paymentUrl: (root['url'] ?? root['paymentUrl'] ?? '').toString(),
      status: (root['status'] ?? 'PENDING').toString(),
      amountInCents: (root['amount'] ?? root['amountInCents'] ?? 0) as int,
      devMode: (root['devMode'] ?? false) as bool,
      methods: (root['methods'] as List?)?.map((e) => e.toString()).toList() ?? const [],
      frequency: root['frequency']?.toString(),
    );
  }

  bool get isPending => status == 'PENDING';
  bool get isPaid => status == 'PAID';
  bool get isFailed => status == 'FAILED';
  bool get isExpired => status == 'EXPIRED';
  bool get isCancelled => status == 'CANCELLED';
  bool get isRefunded => status == 'REFUNDED';

  double get amount => amountInCents / 100.0;

  String get formattedAmount =>
      'R\$ ${amount.toStringAsFixed(2).replaceAll('.', ',')}';
}
