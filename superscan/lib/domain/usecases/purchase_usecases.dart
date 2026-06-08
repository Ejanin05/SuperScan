import 'dart:io';
import '../entities/purchase_item.dart';
import '../entities/scan_result.dart';
import '../repositories/purchase_repository.dart';
import '../repositories/ocr_repository.dart';

// ──────────────────────────────────────────
// Purchase use cases
// ──────────────────────────────────────────

class WatchItemsUseCase {
  final PurchaseRepository _repo;
  WatchItemsUseCase(this._repo);

  Stream<List<PurchaseItem>> call() => _repo.watchItems();
}

class AddItemUseCase {
  final PurchaseRepository _repo;
  AddItemUseCase(this._repo);

  Future<PurchaseItem> call(PurchaseItem item) => _repo.addItem(item);
}

class UpdateItemUseCase {
  final PurchaseRepository _repo;
  UpdateItemUseCase(this._repo);

  Future<void> call(PurchaseItem item) => _repo.updateItem(item);
}

class DeleteItemUseCase {
  final PurchaseRepository _repo;
  DeleteItemUseCase(this._repo);

  Future<void> call(String id) => _repo.deleteItem(id);
}

class ClearAllItemsUseCase {
  final PurchaseRepository _repo;
  ClearAllItemsUseCase(this._repo);

  Future<void> call() => _repo.clearAllItems();
}

// ──────────────────────────────────────────
// OCR use case
// ──────────────────────────────────────────

class ProcessImageUseCase {
  final OcrRepository _repo;
  ProcessImageUseCase(this._repo);

  Future<ScanResult> call(File imageFile) => _repo.processImage(imageFile);
}
