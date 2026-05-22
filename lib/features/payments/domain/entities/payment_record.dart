import 'package:freezed_annotation/freezed_annotation.dart';

part 'payment_record.freezed.dart';
part 'payment_record.g.dart';

enum PaymentStatus { pendiente, pagado, vencido, exento }

@freezed
class PaymentRecord with _$PaymentRecord {
  const factory PaymentRecord({
    required String userId,
    required PaymentStatus status,
    required DateTime periodEnd,
    required double amount,
    String? method,
    DateTime? periodStart,
    DateTime? paidAt,
  }) = _PaymentRecord;

  factory PaymentRecord.fromJson(Map<String, dynamic> json) =>
      _$PaymentRecordFromJson(json);
}

@freezed
class PaymentHistoryRecord with _$PaymentHistoryRecord {
  const factory PaymentHistoryRecord({
    required String id,
    required double amount,
    required DateTime periodStart,
    required DateTime periodEnd,
    required PaymentStatus status,
    String? method,
    DateTime? paidAt,
  }) = _PaymentHistoryRecord;

  factory PaymentHistoryRecord.fromJson(Map<String, dynamic> json) =>
      _$PaymentHistoryRecordFromJson(json);
}
