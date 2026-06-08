import 'dart:io';
import '../../domain/entities/scan_result.dart';
import '../../domain/repositories/ocr_repository.dart';
import '../datasources/ocr_datasource.dart';

class OcrRepositoryImpl implements OcrRepository {
  final OcrDatasource _datasource;

  OcrRepositoryImpl(this._datasource);

  @override
  Future<ScanResult> processImage(File imageFile) =>
      _datasource.processImage(imageFile);
}
