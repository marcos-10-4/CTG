import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:ctg_app/features/payments/data/repositories/payments_repository_impl.dart';
import 'package:ctg_app/features/payments/domain/entities/payment_record.dart';
import 'package:ctg_app/features/payments/domain/repositories/payments_repository.dart';

part 'payments_notifier.g.dart';

@riverpod
PaymentsRepository paymentsRepository(PaymentsRepositoryRef ref) {
  return PaymentsRepositoryImpl();
}

@riverpod
Future<PaymentRecord?> userPayment(UserPaymentRef ref, String userId) {
  return ref.watch(paymentsRepositoryProvider).getUserPayment(userId);
}

@riverpod
Future<List<PaymentHistoryRecord>> paymentHistory(PaymentHistoryRef ref, String userId) {
  return ref.watch(paymentsRepositoryProvider).getPaymentHistory(userId);
}
