import '../entities/purchase_item.dart';

abstract class PurchaseRepository {
  /// Returns a stream of all purchase items, sorted by createdAt desc.
  Stream<List<PurchaseItem>> watchItems();

  /// Returns all items as a one-shot future.
  Future<List<PurchaseItem>> getItems();

  /// Insert a new item. Returns the saved item.
  Future<PurchaseItem> addItem(PurchaseItem item);

  /// Update an existing item.
  Future<void> updateItem(PurchaseItem item);

  /// Delete a single item by id.
  Future<void> deleteItem(String id);

  /// Delete all items (clear current purchase).
  Future<void> clearAllItems();
}
