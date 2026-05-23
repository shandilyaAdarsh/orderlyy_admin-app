// lib/features/orders/domain/entities/menu_product.dart
import 'package:equatable/equatable.dart';
import '../../../../shared/models/money.dart';

class ModifierOption extends Equatable {
  final String id;
  final String name;
  final Money price;

  const ModifierOption({
    required this.id,
    required this.name,
    required this.price,
  });

  @override
  List<Object?> get props => [id, name, price];
}

class MenuProduct extends Equatable {
  final String id;
  final String name;
  final Money price;
  final String category;
  final List<ModifierOption> availableModifiers;

  const MenuProduct({
    required this.id,
    required this.name,
    required this.price,
    required this.category,
    required this.availableModifiers,
  });

  @override
  List<Object?> get props => [id, name, price, category, availableModifiers];
}
