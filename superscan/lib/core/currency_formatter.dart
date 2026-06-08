import 'package:intl/intl.dart';

class CurrencyFormatter {
  CurrencyFormatter._();

  static final _format = NumberFormat.currency(
    locale: 'es_AR',
    symbol: '\$',
    decimalDigits: 2,
  );

  static final _formatNoDecimals = NumberFormat.currency(
    locale: 'es_AR',
    symbol: '\$',
    decimalDigits: 0,
  );

  /// Formats a price as Argentine peso: $3.500,00
  static String format(double amount) {
    if (amount == amount.truncateToDouble()) {
      return _formatNoDecimals.format(amount);
    }
    return _format.format(amount);
  }

  /// Short format for large totals: $24.560
  static String formatTotal(double amount) => _formatNoDecimals.format(amount);

  /// Parse user-typed price string to double
  static double? parse(String text) {
    if (text.isEmpty) return null;
    // Remove $ and spaces
    String cleaned = text.replaceAll('\$', '').trim();
    // If European style (last separator is comma with 2 digits)
    if (RegExp(r'[.,]\d{2}$').hasMatch(cleaned)) {
      final lastSep = cleaned[cleaned.length - 3];
      if (lastSep == ',') {
        cleaned = cleaned.replaceAll('.', '').replaceAll(',', '.');
      } else {
        cleaned = cleaned.replaceAll(',', '');
      }
    } else {
      cleaned = cleaned.replaceAll(RegExp(r'[.,]'), '');
    }
    return double.tryParse(cleaned);
  }
}
