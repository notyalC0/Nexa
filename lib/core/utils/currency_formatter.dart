import 'package:intl/intl.dart';

class CurrencyFormatter {
  static final _formatter = NumberFormat.currency(
    locale: 'pt-br',
    symbol: 'R\$',
    decimalDigits: 2,
  );

  static String format(int cents) {
    return _formatter.format(cents / 100);
  }
}
