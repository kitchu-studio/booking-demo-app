import 'package:intl/intl.dart';

// Dates from the API carry a UTC offset; always show them in the device's local time.
// Thai Buddhist year is added by hand (year + 543) so it does not depend on locale data.

String thaiDateLong(DateTime d) {
  final l = d.toLocal();
  return '${DateFormat('EEEE d MMMM', 'th').format(l)} ${l.year + 543}';
}

String thaiDateShort(DateTime d) {
  final l = d.toLocal();
  return '${DateFormat('d MMM', 'th').format(l)} ${l.year + 543}';
}

String weekdayShort(DateTime d) => DateFormat('E', 'th').format(d);

String timeHm(DateTime d) => DateFormat('HH:mm').format(d.toLocal());

/// yyyy-MM-dd, as the slots endpoint expects.
String apiDate(DateTime d) => DateFormat('yyyy-MM-dd').format(d);

String baht(int value) => '฿${NumberFormat('#,##0').format(value)}';

String monthYearThai(DateTime d) =>
    '${DateFormat('MMMM', 'th').format(d)} ${d.year + 543}';

String monthShortThai(DateTime d) => DateFormat('MMM', 'th').format(d.toLocal());

String weekdayShortLocal(DateTime d) => DateFormat('E', 'th').format(d.toLocal());
