import 'package:intl/intl.dart';

class AppFormatters {
  AppFormatters._();

  static final NumberFormat _currencyFormatter = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  static String formatRupiah(dynamic amount) {
    if (amount == null) return 'Rp 0';
    if (amount is num) {
      return _currencyFormatter.format(amount);
    }
    final parsed = num.tryParse(amount.toString());
    if (parsed != null) {
      return _currencyFormatter.format(parsed);
    }
    return 'Rp $amount';
  }

  static String formatDate(dynamic date, {String pattern = 'dd MMM yyyy'}) {
    if (date == null) return '-';
    DateTime? dt;
    if (date is DateTime) {
      dt = date;
    } else if (date is String) {
      dt = DateTime.tryParse(date);
    }
    if (dt == null) return date.toString();
    try {
      return DateFormat(pattern, 'id_ID').format(dt);
    } catch (_) {
      return DateFormat(pattern).format(dt);
    }
  }

  static String formatDateTime(dynamic date) {
    return formatDate(date, pattern: 'dd MMM yyyy, HH:mm');
  }

  static String formatTime(dynamic time) {
    if (time == null) return '-';
    if (time is DateTime) {
      return DateFormat('HH:mm').format(time);
    }
    final raw = time.toString();
    try {
      final t = DateFormat('HH:mm:ss').parse(raw);
      return DateFormat('HH:mm').format(t);
    } catch (_) {
      try {
        final t = DateFormat('HH:mm').parse(raw);
        return DateFormat('HH:mm').format(t);
      } catch (_) {
        return raw;
      }
    }
  }
}
