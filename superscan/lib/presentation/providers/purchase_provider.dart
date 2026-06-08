import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../data/datasources/local_datasource.dart';
import '../../data/datasources/ocr_datasource.dart';
import '../../data/repositories/purchase_repository_impl.dart';
import '../../data/repositories/ocr_repository_impl.dart';
import '../../domain/entities/purchase_item.dart';
import '../../domain/usecases/purchase_usecases.dart';

// ── Infrastructure ───────────────────────────────────────────────────────────

final localDatasourceProvider = Provider<LocalDatasource>((ref) {
  final ds = LocalDatasource();
  ref.onDispose(ds.dispose);
  return ds;
});

final ocrDatasourceProvider = Provider<OcrDatasource>((ref) {
  final ds = OcrDatasource();
  ref.onDispose(ds.dispose);
  return ds;
});

// ── Repositories ─────────────────────────────────────────────────────────────

final purchaseRepositoryProvider = Provider<PurchaseRepositoryImpl>((ref) {
  return PurchaseRepositoryImpl(ref.watch(localDatasourceProvider));
});

final ocrRepositoryProvider = Provider<OcrRepositoryImpl>((ref) {
  return OcrRepositoryImpl(ref.watch(ocrDatasourceProvider));
});

// ── Use Cases ────────────────────────────────────────────────────────────────

final watchItemsUseCaseProvider = Provider((ref) =>
    WatchItemsUseCase(ref.watch(purchaseRepositoryProvider)));

final addItemUseCaseProvider = Provider((ref) =>
    AddItemUseCase(ref.watch(purchaseRepositoryProvider)));

final updateItemUseCaseProvider = Provider((ref) =>
    UpdateItemUseCase(ref.watch(purchaseRepositoryProvider)));

final deleteItemUseCaseProvider = Provider((ref) =>
    DeleteItemUseCase(ref.watch(purchaseRepositoryProvider)));

final clearAllItemsUseCaseProvider = Provider((ref) =>
    ClearAllItemsUseCase(ref.watch(purchaseRepositoryProvider)));

final processImageUseCaseProvider = Provider((ref) =>
    ProcessImageUseCase(ref.watch(ocrRepositoryProvider)));

// ── Purchase State Notifier ──────────────────────────────────────────────────

class PurchaseState {
  final List<PurchaseItem> items;
  final bool isLoading;
  final String? error;

  const PurchaseState({
    this.items = const [],
    this.isLoading = false,
    this.error,
  });

  double get total => items.fold(0, (sum, item) => sum + item.price);
  int get count => items.length;

  PurchaseState copyWith({
    List<PurchaseItem>? items,
    bool? isLoading,
    String? error,
  }) {
    return PurchaseState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class PurchaseNotifier extends StateNotifier<PurchaseState> {
  final WatchItemsUseCase _watchItems;
  final AddItemUseCase _addItem;
  final UpdateItemUseCase _updateItem;
  final DeleteItemUseCase _deleteItem;
  final ClearAllItemsUseCase _clearAll;

  StreamSubscription<List<PurchaseItem>>? _subscription;

  static const _uuid = Uuid();

  PurchaseNotifier({
    required WatchItemsUseCase watchItems,
    required AddItemUseCase addItem,
    required UpdateItemUseCase updateItem,
    required DeleteItemUseCase deleteItem,
    required ClearAllItemsUseCase clearAll,
  })  : _watchItems = watchItems,
        _addItem = addItem,
        _updateItem = updateItem,
        _deleteItem = deleteItem,
        _clearAll = clearAll,
        super(const PurchaseState()) {
    _init();
  }

  void _init() {
    _subscription = _watchItems().listen(
      (items) => state = state.copyWith(items: items, isLoading: false),
      onError: (e) => state = state.copyWith(error: e.toString()),
    );
  }

  Future<void> addItem({required String name, required double price}) async {
    final item = PurchaseItem(
      id: _uuid.v4(),
      name: name,
      price: price,
      createdAt: DateTime.now(),
    );
    await _addItem(item);
  }

  Future<void> updateItem(PurchaseItem item) async {
    await _updateItem(item);
  }

  Future<void> deleteItem(String id) async {
    await _deleteItem(id);
  }

  Future<void> clearAll() async {
    await _clearAll();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}

final purchaseProvider =
    StateNotifierProvider<PurchaseNotifier, PurchaseState>((ref) {
  return PurchaseNotifier(
    watchItems: ref.watch(watchItemsUseCaseProvider),
    addItem: ref.watch(addItemUseCaseProvider),
    updateItem: ref.watch(updateItemUseCaseProvider),
    deleteItem: ref.watch(deleteItemUseCaseProvider),
    clearAll: ref.watch(clearAllItemsUseCaseProvider),
  );
});
