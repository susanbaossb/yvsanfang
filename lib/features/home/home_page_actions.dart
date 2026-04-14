// ignore_for_file: invalid_use_of_protected_member

part of 'home_page.dart';


extension _HomePageActions on _HomePageState {
  Future<void> _loadMenu() async {
    setState(() => _loadingMenu = true);
    try {
      final dishes = await _menuService.fetchAvailableDishes();
      if (!mounted) return;
      setState(() => _dishes = dishes);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('菜单加载失败：$e')),
      );
    } finally {
      if (mounted) {
        setState(() => _loadingMenu = false);
      }
    }
  }

  Future<void> _loadOrders() async {
    setState(() => _loadingOrders = true);
    try {
      final orders = await _orderService.fetchOrders();
      if (!mounted) return;
      setState(() => _orders = orders);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('订单加载失败：$e')),
      );
    } finally {
      if (mounted) {
        setState(() => _loadingOrders = false);
      }
    }
  }

  Future<void> _loadRecipeCategories() async {
    try {
      final categories = await _recipeService.fetchCategories();
      if (!mounted) return;
      setState(() => _recipeCategories = categories);
    } catch (_) {}
  }

  Future<void> _loadPoints() async {
    setState(() => _loadingPoints = true);
    try {
      final points = await _pointsService.fetchMyPoints(_authService.currentUserId);
      if (!mounted) return;
      setState(() => _myPoints = points);
    } catch (_) {
    } finally {
      if (mounted) setState(() => _loadingPoints = false);
    }
  }

  Future<void> _checkToday() async {
    try {
      final checked = await _pointsService.isCheckedInToday(_authService.currentUserId);
      if (!mounted) return;
      setState(() => _checkedInToday = checked);
    } catch (_) {}
  }

  int _rewardForDay(int day) {
    if (day <= 5) return 10;
    if (day <= 10) return 20;
    return 30;
  }

  Future<void> _loadMonthCheckins() async {
    try {
      final now = DateTime.now().toUtc();
      final set = await _pointsService.fetchMonthCheckins(
        _authService.currentUserId,
        now.year,
        now.month,
      );
      if (!mounted) return;
      setState(() => _monthChecked = set);
    } catch (_) {}
  }

  Future<void> _doCheckIn() async {
    setState(() => _checkingIn = true);
    try {
      final nowUtc = DateTime.now().toUtc();
      final reward = _rewardForDay(nowUtc.day);
      await _pointsService.dailyCheckIn(_authService.currentUserId);
      await _loadPoints();
      await _checkToday();
      await _loadMonthCheckins();
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('签到成功，积分+$reward')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('签到失败：$e')));
    } finally {
      if (mounted) setState(() => _checkingIn = false);
    }
  }

  Future<void> _addDish(Dish dish) async {
    if (!dish.enableMultiSpec || dish.specGroups.isEmpty) {
      _addCartEntry(
        dish: dish,
        selectedSpecs: const [],
        unitPrice: dish.price,
      );
      return;
    }

    final selectedSpecs = await _showSpecSelector(dish);
    if (!mounted || selectedSpecs == null) return;

    final unitPrice =
        dish.price + selectedSpecs.fold<double>(0, (sum, item) => sum + item.priceAdjustment);
    _addCartEntry(
      dish: dish,
      selectedSpecs: selectedSpecs,
      unitPrice: unitPrice,
    );
  }

  void _addCartEntry({
    required Dish dish,
    required List<CartItemSpec> selectedSpecs,
    required double unitPrice,
  }) {
    final key = _buildCartKey(dish.id, selectedSpecs);
    setState(() {
      final current = _cart[key];
      if (current == null) {
        _cart[key] = _CartEntry(
          dish: dish,
          quantity: 1,
          unitPrice: unitPrice,
          selectedSpecs: selectedSpecs,
        );
      } else {
        _cart[key] = current.copyWith(quantity: current.quantity + 1);
      }
    });
  }

  void _removeDish(Dish dish) {
    final candidateKeys = _cart.entries
        .where((entry) => entry.value.dish.id == dish.id)
        .map((entry) => entry.key)
        .toList();
    if (candidateKeys.isEmpty) return;

    candidateKeys.sort((a, b) => _cart[b]!.quantity.compareTo(_cart[a]!.quantity));
    _removeCartKey(candidateKeys.first);
  }

  void _removeCartKey(String key) {
    final entry = _cart[key];
    if (entry == null) return;

    setState(() {
      if (entry.quantity <= 1) {
        _cart.remove(key);
      } else {
        _cart[key] = entry.copyWith(quantity: entry.quantity - 1);
      }
    });
  }

  String _buildCartKey(String dishId, List<CartItemSpec> selectedSpecs) {
    if (selectedSpecs.isEmpty) return dishId;
    final specPart = selectedSpecs
        .map((item) => '${item.groupName}:${item.valueName}')
        .join('|');
    return '$dishId|$specPart';
  }

  int _dishQuantity(String dishId) {
    return _cart.values
        .where((entry) => entry.dish.id == dishId)
        .fold<int>(0, (sum, entry) => sum + entry.quantity);
  }

  List<CartItem> get _cartItems {
    return _cart.values
        .map(
          (entry) => CartItem(
            dish: entry.dish,
            quantity: entry.quantity,
            unitPrice: entry.unitPrice,
            selectedSpecs: entry.selectedSpecs,
          ),
        )
        .toList();
  }

  double get _cartTotal => _cartItems.fold<double>(0, (sum, item) => sum + item.subtotal);

  int get _cartCount => _cart.values.fold<int>(0, (sum, entry) => sum + entry.quantity);

  List<String> get _categories {
    final dishCategories = _dishes.map((e) => e.category.trim()).where((e) => e.isNotEmpty);
    final recipeCategoryNames = _recipeCategories.map((e) => e.name);
    return ['全部', ...{...dishCategories, ...recipeCategoryNames}];
  }

  List<Dish> get _filteredDishes {
    if (_selectedCategory == '全部') return _dishes;
    return _dishes.where((dish) => dish.category == _selectedCategory).toList();
  }

  String _normalizedOrderStatus(String raw) {
    switch (raw) {
      case 'pending':
      case 'cooking':
      case 'unfinished':
        return 'unfinished';
      case 'done':
      case 'completed':
        return 'completed';
      case 'cancelled':
      case 'canceled':
        return 'cancelled';
      case 'deleted':
        return 'deleted';
      default:
        return raw;
    }
  }

  List<OrderSummary> get _filteredOrders {
    final visibleOrders =
        _orders.where((order) => _normalizedOrderStatus(order.status) != 'deleted');
    if (_orderFilter == '全部') {
      return visibleOrders.toList();
    }
    return visibleOrders
        .where((order) => _normalizedOrderStatus(order.status) == _orderFilter)
        .toList();
  }


  Future<void> _placeOrder() async {
    if (_cartItems.isEmpty) return;

    String noteText = '';
    final note = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('提交订单'),
        content: TextField(
          maxLines: 3,
          onChanged: (value) => noteText = value,
          decoration: const InputDecoration(
            hintText: '备注（如少辣、不要葱）',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, noteText.trim()),
            child: const Text('确认下单'),
          ),
        ],
      ),
    );

    if (note == null) return;

    setState(() => _placingOrder = true);
    try {
      final userId = _authService.currentUserId;
      final cartSnapshot = List<CartItem>.from(_cartItems);
      final totalPoints = _cartTotal.round();
      final finalNote = note.isEmpty ? null : note;

      final orderId = await _orderService.placeOrder(
        userId: userId,
        items: cartSnapshot,
        note: finalNote,
      );

      String? mailError;
      try {
        await _orderEmailService.sendOrderEmail(
          orderId: orderId,
          userId: userId,
          nickname: widget.profile.nickname,
          items: cartSnapshot,
          totalPoints: totalPoints,
          note: finalNote,
        );
      } catch (e) {
        mailError = e.toString();
      }

      if (!mounted) return;
      setState(_cart.clear);
      await _loadOrders();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            mailError == null
                ? '下单成功，邮件已发送！'
                : '下单成功，但邮件发送失败：$mailError',
          ),
        ),
      );
    } catch (e) {

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('下单失败：$e')),
      );
    } finally {
      if (mounted) {
        setState(() => _placingOrder = false);
      }
    }
  }

  Future<void> _updateOrderStatus(OrderSummary order, String status) async {
    setState(() => _updatingOrder = true);
    try {
      await _orderService.updateOrderStatus(orderId: order.id, status: status);
      await _loadOrders();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('订单已更新为：${_statusText(status)}')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('订单更新失败：$e')),
      );
    } finally {
      if (mounted) {
        setState(() => _updatingOrder = false);
      }
    }
  }

  Future<void> _deleteOrder(OrderSummary order) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('删除订单'),
        content: const Text('删除后该订单将不再显示，确定继续吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('删除'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    await _updateOrderStatus(order, 'deleted');
  }


  Future<void> _openMenuManager() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const MenuManagementPage()),
    );
    if (!mounted) return;
    await _loadMenu();
  }

  Future<void> _openSettingsManager() async {
    if (!AppFeatureFlags.showPointsAdjustSettings) {
      return;
    }
    await Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const SettingsManagementPage()),
    );
    if (!mounted) return;
    await _loadPoints();
  }


  String _statusText(String raw) {
    switch (_normalizedOrderStatus(raw)) {
      case 'unfinished':
        return '未完成';
      case 'completed':
        return '已完成';
      case 'cancelled':
        return '已取消';
      case 'deleted':
        return '已删除';
      default:
        return raw;
    }
  }
}
