/// 订单服务及购物车相关模型
/// 
/// 功能：
/// 1. CartItemSpec: 购物车规格项（规格组名、规格值、加价）
/// 2. CartItem: 购物车项（菜品、数量、单价、已选规格）
/// 3. placeOrder: 下单（扣减积分、创建订单和订单项）
/// 4. fetchOrders: 获取订单列表
/// 5. updateOrderStatus: 更新订单状态
/// 
/// 购物车 Key 生成规则：dishId | specs（如有多规格）

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

  /// 生成 18 位纯数字订单号：日期时间(14 位) + 微秒后 4 位(4 位)
  /// 同一秒内微秒不同即可保证唯一，纯数字、无字母。
  static String _generateOrderNo() {
    final now = DateTime.now();
    final datePart =
        '${now.year}'
        '${now.month.toString().padLeft(2, '0')}'
        '${now.day.toString().padLeft(2, '0')}'
        '${now.hour.toString().padLeft(2, '0')}'
        '${now.minute.toString().padLeft(2, '0')}'
        '${now.second.toString().padLeft(2, '0')}';
    final microTail =
        now.microsecond.toString().padLeft(6, '0').substring(2); // 取后 4 位
    return '$datePart$microTail';
  }

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
          'order_no': _generateOrderNo(), // 18 位纯数字订单号
        })
        .select('id, order_no')
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
        .select(
          'id,order_no,status,total_amount,created_at,updated_at,note,order_items(quantity,price,dishes(name,image_url))',
        )
        .order('created_at', ascending: false);

    return rows.map<OrderSummary>((raw) => OrderSummary.fromJson(raw)).toList();
  }

  /// 获取指定用户下的订单（用于消息提醒：对方下的订单会提醒我，含已删除）
  Future<List<OrderSummary>> fetchPartnerOrders(String partnerId) async {
    final rows = await AppSupabase.client
        .from('orders')
        .select(
          'id,order_no,status,total_amount,created_at,updated_at,note,order_items(quantity,price,dishes(name,image_url))',
        )
        .eq('user_id', partnerId)
        .order('created_at', ascending: false);

    return rows.map<OrderSummary>((raw) => OrderSummary.fromJson(raw)).toList();
  }

  Future<void> updateOrderStatus({
    required String orderId,
    required String status,
  }) async {
    // 更新状态的同时写入变化时间，供消息未读判定。
    // 若数据库尚无 updated_at 列，则降级为仅更新状态（不影响主流程）。
    try {
      await AppSupabase.client.from('orders').update({
        'status': status,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      }).eq('id', orderId);
    } catch (_) {
      await AppSupabase.client
          .from('orders')
          .update({'status': status}).eq('id', orderId);
    }
  }
}

