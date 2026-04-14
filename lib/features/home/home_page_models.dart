part of 'home_page.dart';

class _CartEntry {
  const _CartEntry({
    required this.dish,
    required this.quantity,
    required this.unitPrice,
    required this.selectedSpecs,
  });

  final Dish dish;
  final int quantity;
  final double unitPrice;
  final List<CartItemSpec> selectedSpecs;

  _CartEntry copyWith({int? quantity}) {
    return _CartEntry(
      dish: dish,
      quantity: quantity ?? this.quantity,
      unitPrice: unitPrice,
      selectedSpecs: selectedSpecs,
    );
  }
}
