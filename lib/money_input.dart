import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

final _wonFormat = NumberFormat.decimalPattern('ko');

int? parseWon(String value) => int.tryParse(value.replaceAll(',', '').trim());

String formatWon(int value) => _wonFormat.format(value);

class WonInputFormatter extends TextInputFormatter {
  const WonInputFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) return newValue;
    if (!RegExp(r'^[\d,]+$').hasMatch(newValue.text)) return oldValue;
    final digits = newValue.text.replaceAll(',', '');
    final value = int.tryParse(digits);
    if (value == null) return oldValue;
    final formatted = formatWon(value);
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
