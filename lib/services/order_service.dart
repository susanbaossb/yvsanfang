import '../core/supabase_client.dart';
import '../models/dish.dart';
import '../models/order_summary.dart';
import 'points_service.dart';

class CartItemSpec {
  CartItemSpec({
    required this.groupName,
    required this.valueName,
    required this.priceAdjustment,
  });

  final String groupName;
  final String valueName;
  final double priceAdjustment;
}

class CartItem {
  CartItem({
    required this.dish,
    required this.quantity,
    required this.unitPrice,
    this.selectedSpecs = const [],
  });

  final Dish dish;
  final int quantity;
  final double unitPrice;
  final List<CartItemSpec> selectedSpecs;

  double get subtotal => unitPrice * quantity;

  String get specSummary =>
      selectedSpecs.map((item) => '${item.groupName}:${item.valueName}').join('、');
}

class OrderService {
  final _pointsService = PointsService();

  Future<String> placeOrder({
    required String userId,
    required List<CartItem> items,
    String? note,
  }) async {
    if (items.isEmpty) {
      throw Exception('请先选择菜品');
    }

    final total = items.fold<double>(0, (sum, item) => sum + item.subtotal);
    final pointsNeeded = total.round(); // 假设 1 价格单位 = 1 积分，四舍五入

    // 先扣减积分（不足将抛错）
    await _pointsService.deductPoints(userId, pointsNeeded);

    final normalizedNote = note?.trim();
    final specLines = items
        .where((item) => item.selectedSpecs.isNotEmpty)
        .map((item) => '${item.dish.name}（${item.specSummary}）x${item.quantity}')
        .toList();

    String? finalNote;
    if ((normalizedNote?.isNotEmpty ?? false) && specLines.isNotEmpty) {
      finalNote = '$normalizedNote\n规格：\n${specLines.join('\n')}';
    } else if (normalizedNote?.isNotEmpty ?? false) {
      finalNote = normalizedNote;
    } else if (specLines.isNotEmpty) {
      finalNote = '规格：\n${specLines.join('\n')}';
    }

    final order = await AppSupabase.client
        .from('orders')
        .insert({
          'user_id': userId,
          'status': 'unfinished',
          'total_amount': pointsNeeded, // 使用积分数作为总额
          'note': finalNote,
        })
        .select('id')
        .single();

    final orderId = order['id'] as String;

    final orderItems = items
        .map((item) => {
              'order_id': orderId,
              'dish_id': item.dish.id,
              'quantity': item.quantity,
              'price': item.unitPrice, // 单项价格仍保留原价（用于回溯）
            })
        .toList();

    await AppSupabase.client.from('order_items').insert(orderItems);
    return orderId;
  }


  Future<List<OrderSummary>> fetchOrders() async {
    final rows = await AppSupabase.client
        .from('orders')
        .select('id,status,total_amount,created_at,note,order_items(quantity,price,dishes(name,image_url))')
        .order('created_at', ascending: false);

    return rows.map<OrderSummary>((raw) => OrderSummary.fromJson(raw)).toList();
  }

  Future<void> updateOrderStatus({
    required String orderId,
    required String status,
  }) async {
    await AppSupabase.client
        .from('orders')
        .update({'status': status}).eq('id', orderId);
  }
}

