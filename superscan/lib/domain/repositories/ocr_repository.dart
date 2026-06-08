import 'dart:io';
import '../entities/scan_result.dart';

abstract class OcrRepository {
  /// Process [imageFile] and return a [ScanResult] with detected name and price.
  Future<ScanResult> processImage(File imageFile);
}
