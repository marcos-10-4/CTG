import 'package:ctg_app/features/payments/domain/entities/payment_record.dart';

abstract interface class PaymentsRepository {
  Future<PaymentRecord?> getUserPayment(String userId);
  Future<List<PaymentHistoryRecord>> getPaymentHistory(String userId);
}
