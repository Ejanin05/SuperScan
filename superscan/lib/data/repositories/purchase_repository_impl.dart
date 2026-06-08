import '../../domain/entities/purchase_item.dart';
import '../../domain/repositories/purchase_repository.dart';
import '../datasources/local_datasource.dart';
import '../models/purchase_item_model.dart';

class PurchaseRepositoryImpl implements PurchaseRepository {
  final LocalDatasource _datasource;

  PurchaseRepositoryImpl(this._datasource);

  @override
  Stream<List<PurchaseItem>> watchItems() => _datasource.watchItems();

  @override
  Future<List<PurchaseItem>> getItems() => _datasource.getItems();

  @override
  Future<PurchaseItem> addItem(PurchaseItem item) async {
    final model = PurchaseItemModel.fromEntity(item);
    await _datasource.insertItem(model);
    return item;
  }

  @override
  Future<void> updateItem(PurchaseItem item) async {
    final model = PurchaseItemModel.fromEntity(item);
    await _datasource.updateItem(model);
  }

  @override
  Future<void> deleteItem(String id) => _datasource.deleteItem(id);

  @override
  Future<void> clearAllItems() => _datasource.clearAll();
}
