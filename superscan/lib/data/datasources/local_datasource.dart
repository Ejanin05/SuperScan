import 'dart:async';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';
import '../models/purchase_item_model.dart';

class LocalDatasource {
  static const _dbName = 'superscan.db';
  static const _dbVersion = 1;
  static const _table = 'purchase_items';

  Database? _db;

  // Stream controller to broadcast changes
  final _controller = StreamController<List<PurchaseItemModel>>.broadcast();

  Future<Database> get database async {
    _db ??= await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, _dbName);

    return openDatabase(
      path,
      version: _dbVersion,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE $_table (
            id TEXT PRIMARY KEY,
            name TEXT NOT NULL,
            price REAL NOT NULL,
            created_at INTEGER NOT NULL
          )
        ''');
      },
    );
  }

  Stream<List<PurchaseItemModel>> watchItems() {
    // Emit initial value immediately
    getItems().then((items) => _controller.add(items));
    return _controller.stream;
  }

  Future<List<PurchaseItemModel>> getItems() async {
    final db = await database;
    final maps = await db.query(
      _table,
      orderBy: 'created_at DESC',
    );
    return maps.map(PurchaseItemModel.fromMap).toList();
  }

  Future<void> insertItem(PurchaseItemModel item) async {
    final db = await database;
    await db.insert(
      _table,
      item.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    await _notifyListeners();
  }

  Future<void> updateItem(PurchaseItemModel item) async {
    final db = await database;
    await db.update(
      _table,
      item.toMap(),
      where: 'id = ?',
      whereArgs: [item.id],
    );
    await _notifyListeners();
  }

  Future<void> deleteItem(String id) async {
    final db = await database;
    await db.delete(_table, where: 'id = ?', whereArgs: [id]);
    await _notifyListeners();
  }

  Future<void> clearAll() async {
    final db = await database;
    await db.delete(_table);
    await _notifyListeners();
  }

  Future<void> _notifyListeners() async {
    final items = await getItems();
    _controller.add(items);
  }

  Future<void> dispose() async {
    await _controller.close();
    await _db?.close();
  }
}
