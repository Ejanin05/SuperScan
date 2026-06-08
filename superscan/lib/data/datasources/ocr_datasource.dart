import 'dart:io';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import '../../domain/entities/scan_result.dart';

class OcrDatasource {
  final _recognizer = TextRecognizer(script: TextRecognitionScript.latin);

  Future<ScanResult> processImage(File imageFile) async {
    final inputImage = InputImage.fromFile(imageFile);
    final recognized = await _recognizer.processImage(inputImage);
    final rawText = recognized.text;

    final parsed = _parseOcrText(rawText);
    return parsed;
  }

  ScanResult _parseOcrText(String rawText) {
    final lines = rawText
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();

    double? bestPrice;
    String? bestName;

    // ── Price detection ──────────────────────────────────────────────────────
    // Patterns (in priority order):
    //  1. $3.500 / $3500 / $3.500,99 / $2.499,99
    //  2. 2 x $6000 → price = 6000
    //  3. Bare number that looks like a price (last resort)

    final pricePatterns = [
      // Explicit $ sign: $3.500,99  $3500  $3.500
      RegExp(r'\$\s*([\d]{1,3}(?:[.,][\d]{3})*(?:[.,]\d{1,2})?|\d+(?:[.,]\d{1,2})?)'),
      // N x $PRICE  or  Nx$PRICE
      RegExp(r'\d+\s*[xX]\s*\$\s*([\d]{1,3}(?:[.,][\d]{3})*(?:[.,]\d{1,2})?|\d+)'),
      // Bare large number (≥100) as last resort
      RegExp(r'\b(\d{3,7}(?:[.,]\d{2})?)\b'),
    ];

    final allLines = lines.join('\n');

    for (final pattern in pricePatterns) {
      final match = pattern.firstMatch(allLines);
      if (match != null) {
        final raw = match.group(1)!;
        final parsed = _parseNumber(raw);
        if (parsed != null && parsed > 0) {
          bestPrice = parsed;
          break;
        }
      }
    }

    // ── Name detection ───────────────────────────────────────────────────────
    // Strategy: find the line with the most "product-like" text.
    // A product line:
    //   - Is mostly uppercase letters/numbers
    //   - Does NOT start with promotional keywords
    //   - Is not a pure number
    //   - Prefers lines before the price line

    const skipWords = {
      'promoción', 'promocion', 'oferta', 'descuento', 'precio',
      'total', 'subtotal', 'iva', 'impuesto', 'caja', 'efectivo',
      'tarjeta', 'crédito', 'débito', 'credito', 'debito',
    };

    for (final line in lines) {
      final lower = line.toLowerCase();
      // Skip lines that are only numbers / prices
      if (RegExp(r'^[\d\s\$.,xX%]+$').hasMatch(line)) continue;
      // Skip known non-product words
      if (skipWords.any((w) => lower.startsWith(w))) continue;
      // Skip very short lines
      if (line.length < 3) continue;

      // Remove the price portion from the line to get the name
      String candidate = line;
      candidate = candidate.replaceAll(RegExp(r'\$\s*[\d.,]+'), '').trim();
      candidate = candidate.replaceAll(RegExp(r'\d+\s*[xX]\s*\$\s*[\d.,]+'), '').trim();
      candidate = candidate.replaceAll(RegExp(r'\s{2,}'), ' ').trim();

      if (candidate.length >= 3) {
        // Title-case it
        bestName = _toTitleCase(candidate);
        break;
      }
    }

    return ScanResult(
      detectedName: bestName,
      detectedPrice: bestPrice,
      rawText: rawText,
    );
  }

  /// Parses "3.500,99", "3500", "3,500.99", "3500.00" → double
  double? _parseNumber(String raw) {
    if (raw.isEmpty) return null;

    // Determine if last separator is decimal: "3.500,99" → comma is decimal
    String normalized = raw;

    // Pattern: ends with ,XX or .XX (2 decimal digits) → decimal separator
    if (RegExp(r'[.,]\d{2}$').hasMatch(raw)) {
      final lastSep = raw[raw.length - 3];
      if (lastSep == ',') {
        // European: 3.500,99 → remove dots, replace comma with dot
        normalized = raw.replaceAll('.', '').replaceAll(',', '.');
      } else {
        // US: 3,500.99 → remove commas
        normalized = raw.replaceAll(',', '');
      }
    } else {
      // No decimal part → strip all separators
      normalized = raw.replaceAll(RegExp(r'[.,]'), '');
    }

    return double.tryParse(normalized);
  }

  String _toTitleCase(String text) {
    return text
        .toLowerCase()
        .split(' ')
        .map((w) => w.isEmpty ? '' : '${w[0].toUpperCase()}${w.substring(1)}')
        .join(' ');
  }

  Future<void> dispose() async {
    await _recognizer.close();
  }
}
