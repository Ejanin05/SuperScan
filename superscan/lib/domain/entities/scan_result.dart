class ScanResult {
  final String? detectedName;
  final double? detectedPrice;
  final String rawText;

  const ScanResult({
    this.detectedName,
    this.detectedPrice,
    required this.rawText,
  });

  bool get hasName => detectedName != null && detectedName!.isNotEmpty;
  bool get hasPrice => detectedPrice != null && detectedPrice! > 0;
}
