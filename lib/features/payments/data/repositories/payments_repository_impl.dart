import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:ctg_app/features/payments/domain/entities/payment_record.dart';
import 'package:ctg_app/features/payments/domain/repositories/payments_repository.dart';

class PaymentsRepositoryImpl implements PaymentsRepository {
  PaymentsRepositoryImpl({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  @override
  Future<PaymentRecord?> getUserPayment(String userId) async {
    final doc = await _db.collection('payments').doc(userId).get();
    if (!doc.exists) return null;

    final data = doc.data()!;
    data['userId'] = userId;
    _normalizeDates(data);
    return PaymentRecord.fromJson(data);
  }

  @override
  Future<List<PaymentHistoryRecord>> getPaymentHistory(
    String userId,
  ) async {
    final snap = await _db
        .collection('payments')
        .doc(userId)
        .collection('records')
        .orderBy('periodEnd', descending: true)
        .limit(24)
        .get();

    return snap.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id;
      _normalizeDates(data);
      return PaymentHistoryRecord.fromJson(data);
    }).toList();
  }

  void _normalizeDates(Map<String, dynamic> data) {
    for (final key in ['periodEnd', 'periodStart', 'paidAt', 'nextDueDate']) {
      if (data[key] is Timestamp) {
        data[key] = (data[key] as Timestamp).toDate().toIso8601String();
      }
    }
    // Map nextDueDate → periodEnd if needed
    if (!data.containsKey('periodEnd') && data.containsKey('nextDueDate')) {
      data['periodEnd'] = data['nextDueDate'];
    }
    // currentStatus → status
    if (!data.containsKey('status') && data.containsKey('currentStatus')) {
      data['status'] = data['currentStatus'];
    }
    data.putIfAbsent('amount', () => 0.0);
    data.putIfAbsent('periodEnd', () => DateTime.now().toIso8601String());
    data.putIfAbsent('status', () => 'pendiente');
  }
}
