class OrderDishItem {
  OrderDishItem({
    required this.name,
    required this.quantity,
    required this.unitPrice,
    this.imageUrl,
  });

  final String name;
  final int quantity;
  final double unitPrice;
  final String? imageUrl;

  String get summary => '$name x$quantity · 积分${unitPrice.toStringAsFixed(0)}';
}

class OrderSummary {
  OrderSummary({
    required this.id,
    required this.status,
    required this.totalAmount,
    required this.createdAt,
    required this.items,
    this.note,
  });

  final String id;
  final String status;
  final double totalAmount;
  final DateTime createdAt;
  final List<OrderDishItem> items;
  final String? note;

  factory OrderSummary.fromJson(Map<String, dynamic> json) {
    final orderItems = (json['order_items'] as List<dynamic>? ?? <dynamic>[])
        .map((raw) => raw as Map<String, dynamic>)
        .map((item) {
          final dish = item['dishes'] as Map<String, dynamic>? ?? {};
          return OrderDishItem(
            name: dish['name'] as String? ?? '未知菜品',
            quantity: item['quantity'] as int? ?? 0,
            unitPrice: (item['price'] as num?)?.toDouble() ?? 0,
            imageUrl: dish['image_url'] as String?,
          );
        })
        .toList();

    return OrderSummary(
      id: json['id'] as String,
      status: json['status'] as String? ?? 'unfinished',
      totalAmount: (json['total_amount'] as num?)?.toDouble() ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
      items: orderItems,
      note: json['note'] as String?,
    );
  }
}

