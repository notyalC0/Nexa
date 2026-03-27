import 'package:intl/intl.dart';

class CurrencyFormatter {
  static final _formatter = NumberFormat.currency(
    locale: Intl.canonicalizedLocale('pt_BR'),
    symbol: 'R\$',
    decimalDigits: 2,
  );

  static String format(int cents) {
    return _formatter.format(cents / 100);
  }

  static int parse(String formatted) {
    final digits = formatted.replaceAll(RegExp(r'[^\d]'), '');
    return int.tryParse(digits) ?? 0;
  }
}
