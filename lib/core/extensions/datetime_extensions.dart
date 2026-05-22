import 'package:intl/intl.dart';

extension DateTimeFormatting on DateTime {
  String get dayMonth => DateFormat('d MMM', 'es').format(this);
  String get dayMonthYear => DateFormat('d MMM yyyy', 'es').format(this);
  String get hourMinute => DateFormat('HH:mm').format(this);
  String get monthYearMono => DateFormat('MMMM yyyy', 'es').format(this).toUpperCase();
  String get dayShort => DateFormat('d', 'es').format(this);
  String get monthShort => DateFormat('MMM', 'es').format(this).toUpperCase();
  String get weekdayShort => DateFormat('EEE', 'es').format(this).toUpperCase();
  String get isoDate => DateFormat('yyyy-MM-dd').format(this);

  bool get isToday {
    final now = DateTime.now();
    return year == now.year && month == now.month && day == now.day;
  }

  bool get isTomorrow {
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    return year == tomorrow.year && month == tomorrow.month && day == tomorrow.day;
  }

  bool get isPast => isBefore(DateTime.now());
}
