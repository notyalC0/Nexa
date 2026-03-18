import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';

class InputMasks {
  static MaskTextInputFormatter currency() => MaskTextInputFormatter(
        mask: '###.###.###.###,##',
        filter: {'#': RegExp(r'[0-9]')},
        type: MaskAutoCompletionType.lazy,
      );

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
