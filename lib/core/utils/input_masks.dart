import 'package:flutter/services.dart';

class _CurrencyTextInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');

    if (digits.isEmpty) {
      return const TextEditingValue(
        text: '',
        selection: TextSelection.collapsed(offset: 0),
      );
    }

    final cents = int.tryParse(digits) ?? 0;
    final formatted = InputMasks.centsToCurrencyText(cents);

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

class InputMasks {
  static TextInputFormatter currency() => _CurrencyTextInputFormatter();

  static int currencyToCents(String maskedValue) {
    final digits = maskedValue.replaceAll(RegExp(r'[^0-9]'), '');
    return int.tryParse(digits) ?? 0;
  }

  static String centsToCurrencyText(int cents) {
    final digits = cents.abs().toString().padLeft(3, '0');
    final integerPart = digits.substring(0, digits.length - 2);
    final decimalPart = digits.substring(digits.length - 2);
    final withGrouping = integerPart.replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (match) => '.',
    );
    final value = '$withGrouping,$decimalPart';
    return cents < 0 ? '-$value' : value;
  }
}
