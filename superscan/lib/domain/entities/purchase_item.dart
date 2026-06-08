import 'package:equatable/equatable.dart';

class PurchaseItem extends Equatable {
  final String id;
  final String name;
  final double price;
  final DateTime createdAt;

  const PurchaseItem({
    required this.id,
    required this.name,
    required this.price,
    required this.createdAt,
  });

  PurchaseItem copyWith({
    String? id,
    String? name,
    double? price,
    DateTime? createdAt,
  }) {
    return PurchaseItem(
      id: id ?? this.id,
      name: name ?? this.name,
      price: price ?? this.price,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [id, name, price, createdAt];
}
