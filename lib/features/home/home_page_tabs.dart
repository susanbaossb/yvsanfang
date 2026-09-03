// ignore_for_file: invalid_use_of_protected_member

/// 主页 Tab 视图扩展
/// 
/// 功能：
/// - _buildKitchenTab：厨房 Tab（菜品列表、分类筛选、购物车栏）
/// - _buildOrdersTab：订单 Tab（订单列表、状态筛选、操作按钮）
/// - _buildActivitiesTab：活动 Tab（签到日历、积分展示、活动任务列表）
/// - _buildProfileTab：我的 Tab（个人信息入口、快捷功能）
/// - _buildBottomOrderBar：底部购物车栏
/// - _buildCartDetailPanel：购物车详情弹层

part of 'home_page.dart';

extension _HomePageTabs on _HomePageState {
  Widget _buildKitchenTab() {
    if (_loadingMenu) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_dishes.isEmpty) {
      return RefreshIndicator(
        onRefresh: _loadMenu,
        child: ListView(
          children: const [
            SizedBox(height: 160),
            Center(child: Text('暂无菜品，请先在数据库添加菜单')),
          ],
        ),
      );
    }

    final dishes = _filteredDishes;
    return RefreshIndicator(
      onRefresh: _loadMenu,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 100),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFFFDDED), Color(0xFFFFF3F9)],
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.favorite_rounded,
                      color: Color(0xFFE85D9A), size: 24),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '欢迎回来，${widget.profile.nickname}',
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF9A2D68),
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text('今日甜蜜菜单已上新，快来挑喜欢的吧'),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _categories.map(
                (category) {
                  final isSelected = _selectedCategory == category;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      showCheckmark: false,
                      label: Text(
                        category,
                        style: TextStyle(
                          color: isSelected
                              ? Colors.white
                              : const Color(0xFF6A4D5D),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      selected: isSelected,
                      selectedColor: const Color(0xFFE85D9A),
                      backgroundColor: Colors.white,
                      side: BorderSide(
                        color: isSelected
                            ? const Color(0xFFE85D9A)
                            : const Color(0xFFFFCFE2),
                      ),
                      onSelected: (_) =>
                          setState(() => _selectedCategory = category),
                    ),
                  );
                },
              ).toList(),
            ),
          ),
          const SizedBox(height: 12),
          if (dishes.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 40),
              child: Center(child: Text('该分类暂无菜品')),
            )
          else
            ...dishes.map((dish) {
              final quantity = _dishQuantity(dish.id);
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => DishDetailPage(dish: dish),
                            ),
                          );
                        },
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: SizedBox(
                            width: 58,
                            height: 58,
                            child:
                                dish.imageUrl != null && dish.imageUrl!.isNotEmpty
                                    ? Image.network(
                                        dish.imageUrl!,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) => Container(
                                          color: const Color(0xFFFFF0F7),
                                          child: const Icon(Icons.ramen_dining,
                                              color: Color(0xFFE85D9A)),
                                        ),
                                      )
                                    : Container(
                                        color: const Color(0xFFFFF0F7),
                                        child: const Icon(Icons.ramen_dining,
                                            color: Color(0xFFE85D9A)),
                                      ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(dish.name,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600)),
                            const SizedBox(height: 2),
                            Text(
                              '★' * dish.rating.clamp(0, 5),
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFFFFD66E),
                                shadows: [
                                  Shadow(
                                    color: Color(0xFFB98B1D),
                                    offset: Offset(0, 1),
                                    blurRadius: 1.6,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              dish.enableMultiSpec
                                  ? '¥${dish.price.toStringAsFixed(2)} 起'
                                  : '¥${dish.price.toStringAsFixed(2)}',
                              style: const TextStyle(
                                color: Color(0xFFE85D9A),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Row(
                        children: [
                          IconButton(
                            onPressed:
                                quantity > 0 ? () => _removeDish(dish) : null,
                            icon: const Icon(Icons.remove_circle_outline),
                          ),
                          SizedBox(
                              width: 20,
                              child: Center(child: Text('$quantity'))),
                          IconButton(
                            onPressed: () => _addDish(dish),
                            icon: const Icon(Icons.add_circle),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildOrdersTab() {
    if (_loadingOrders) {
      return const Center(child: CircularProgressIndicator());
    }

    final orders = _filteredOrders;
    return RefreshIndicator(
      onRefresh: _loadOrders,
      child: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          Wrap(
            spacing: 8,
            children: [
              _buildOrderFilterChip('全部', '全部'),
              _buildOrderFilterChip('unfinished', '未完成'),
              _buildOrderFilterChip('completed', '已完成'),
              _buildOrderFilterChip('cancelled', '已取消'),
            ],
          ),
          const SizedBox(height: 10),
          if (orders.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 140),
              child: Center(child: Text('当前筛选条件下暂无订单')),
            )
          else
            ...orders.map((order) {
              final shortId = order.orderNumber.length >= 8
                  ? order.orderNumber.substring(0, 8)
                  : order.orderNumber;
              final normalizedStatus = _normalizedOrderStatus(order.status);
              return Card(
                margin: const EdgeInsets.only(bottom: 10),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => OrderDetailPage(order: order),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                      Text(
                        '订单 #$shortId · 积分${order.totalAmount.toStringAsFixed(0)}',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: _statusBgColor(normalizedStatus),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              _statusText(order.status),
                              style: TextStyle(
                                color: _statusFgColor(normalizedStatus),
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                              DateFormat('MM-dd HH:mm')
                                  .format(order.createdAt.toLocal()),
                              style: const TextStyle(color: Color(0xFF6A5965))),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text('菜品信息：',
                          style: TextStyle(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 4),
                      ...order.items.map(
                        (item) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: SizedBox(
                                  width: 42,
                                  height: 42,
                                  child: item.imageUrl != null &&
                                          item.imageUrl!.isNotEmpty
                                      ? Image.network(
                                          item.imageUrl!,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) =>
                                              Container(
                                            color: const Color(0xFFFFF0F7),
                                            child: const Icon(
                                              Icons.ramen_dining,
                                              color: Color(0xFFE85D9A),
                                              size: 20,
                                            ),
                                          ),
                                        )
                                      : Container(
                                          color: const Color(0xFFFFF0F7),
                                          child: const Icon(
                                            Icons.ramen_dining,
                                            color: Color(0xFFE85D9A),
                                            size: 20,
                                          ),
                                        ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(child: Text(item.summary)),
                            ],
                          ),
                        ),
                      ),
                      if (order.note != null &&
                          order.note!.trim().isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          '备注：${order.note!.trim()}',
                          style: TextStyle(color: Colors.grey.shade700),
                        ),
                      ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _OrderActionButton(
                            label: '完成订单',
                            icon: Icons.check_circle_outline,
                            foreground: const Color(0xFF237A57),
                            background: const Color(0xFFE8F8F0),
                            disabledForeground: const Color(0xFFB8C9C0),
                            disabledBackground: const Color(0xFFF0F4F2),
                            onPressed: _updatingOrder ||
                                    normalizedStatus != 'unfinished'
                                ? null
                                : () => _updateOrderStatus(order, 'completed'),
                          ),
                          _OrderActionButton(
                            label: '取消订单',
                            icon: Icons.block_outlined,
                            foreground: const Color(0xFFB0651A),
                            background: const Color(0xFFFFF1E0),
                            disabledForeground: const Color(0xFFCFB9A4),
                            disabledBackground: const Color(0xFFF7F1EA),
                            onPressed: _updatingOrder ||
                                    normalizedStatus != 'unfinished'
                                ? null
                                : () => _updateOrderStatus(order, 'cancelled'),
                          ),
                          _OrderActionButton(
                            label: '删除订单',
                            icon: Icons.delete_outline,
                            foreground: const Color(0xFFC24561),
                            background: const Color(0xFFFFEFF2),
                            disabledForeground: const Color(0xFFCFB1B9),
                            disabledBackground: const Color(0xFFF6EEF0),
                            onPressed: _updatingOrder
                                ? null
                                : () => _deleteOrder(order),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }

  Color _statusBgColor(String status) {
    switch (status) {
      case 'unfinished':
        return const Color(0xFFFFEAF4);
      case 'completed':
        return const Color(0xFFE8F8F0);
      case 'cancelled':
        return const Color(0xFFFFEFF2);
      default:
        return const Color(0xFFF4F4F6);
    }
  }

  Color _statusFgColor(String status) {
    switch (status) {
      case 'unfinished':
        return const Color(0xFFB2457B);
      case 'completed':
        return const Color(0xFF237A57);
      case 'cancelled':
        return const Color(0xFFC24561);
      default:
        return Colors.black54;
    }
  }

  Widget _buildOrderFilterChip(String key, String label) {
    final isSelected = _orderFilter == key;
    return FilterChip(
      showCheckmark: false,
      label: Text(
        label,
        style: TextStyle(
          color: isSelected ? Colors.white : const Color(0xFF6A4D5D),
          fontWeight: FontWeight.w700,
        ),
      ),
      selectedColor: const Color(0xFFE85D9A),
      backgroundColor: Colors.white,
      side: BorderSide(
        color: isSelected ? const Color(0xFFE85D9A) : const Color(0xFFFFCFE2),
      ),
      selected: isSelected,
      onSelected: (_) => setState(() => _orderFilter = key),
    );
  }

  Widget _buildMessagesTab() {
    return MessageListPage(
      userId: widget.profile.id,
      activityUnread: _activityUnread,
      orderUnread: _orderUnread,
      chatUnread: _messageUnread,
      hasPartner: _hasPartner,
      partnerNickname: _partnerNickname,
      partnerId: _partnerId,
      onActivitySeen: _onActivityMessagesSeen,
      onOrderSeen: _onOrderMessagesSeen,
      onChatRead: () => setState(() => _messageUnread = 0),
      onGoBind: () => setState(() => _tabIndex = 4),
    );
  }

  Widget _buildProfileTab() {
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        Card(
          child: InkWell(
            onTap: _openProfileEdit,
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: const Color(0xFFFFF0F7),
                    backgroundImage: widget.profile.avatarUrl != null
                        ? NetworkImage(widget.profile.avatarUrl!)
                        : null,
                    child: widget.profile.avatarUrl == null
                        ? Text(
                            widget.profile.nickname.isNotEmpty
                                ? widget.profile.nickname.substring(0, 1)
                                : '我',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFFE85D9A),
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.profile.nickname,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '身份：${widget.profile.role}',
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: Colors.grey),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 2.1,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
          children: [
            _buildQuickAction(
              icon: Icons.category_outlined,
              title: '分类管理',
              subtitle: '新增/删除菜品分类',
              onTap: _showCategoryManager,
            ),
            _buildQuickAction(
              icon: Icons.receipt_long,
              title: '全部订单',
              subtitle: '查看历史订单',
              onTap: () => setState(() => _tabIndex = 1),
            ),
            _buildQuickAction(
              icon: Icons.restaurant_menu,
              title: '菜单管理',
              subtitle: '新增/编辑/上下架',
              onTap: _openMenuManager,
            ),
            _buildQuickAction(
              icon: Icons.notifications_none,
              title: '消息通知',
              subtitle: '对象的任务提醒与审核',
              badge: _pendingReviewCount,
              onTap: _openNotifications,
            ),
            _buildQuickAction(
              icon: Icons.task_alt,
              title: '活动任务',
              subtitle: '配置任务、审核与积分',
              onTap: _openTaskManager,
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildLogoutButton(),
      ],
    );
  }

  Widget _buildLogoutButton() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: _confirmLogout,
        icon: const Icon(Icons.logout, size: 18),
        label: const Text('退出账号'),
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFFE85D9A),
          side: const BorderSide(color: Color(0xFFFFB3D1)),
          padding: const EdgeInsets.symmetric(vertical: 13),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Future<void> _confirmLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('退出账号'),
        content: const Text('退出后将回到登录页，可用其他账号登录测试。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFFE85D9A),
            ),
            child: const Text('退出'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    await _authService.logout();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => const LoginPage()),
      (_) => false,
    );
  }

  Widget _buildQuickAction({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    int badge = 0,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Ink(
        decoration: BoxDecoration(
          color: const Color(0xFFFFFFFF),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFFFE1EE)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF0F7),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: const Color(0xFFE85D9A), size: 21),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF3A2A35),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style:
                          TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
              if (badge > 0)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE85D9A),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    badge > 99 ? '99+' : '$badge',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget? _buildBottomOrderBar() {
    if (_tabIndex != 0 || _cartCount == 0) return null;
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
        decoration: BoxDecoration(
          color: Colors.white,
          border: const Border(top: BorderSide(color: Color(0xFFFFE1EE))),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFFA5CA).withValues(alpha: 0.16),
              blurRadius: 14,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Row(
          children: [
            InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: _toggleCartDetailPanel,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF0F7),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFFFD3E6)),
                      ),
                      child: const Icon(
                        Icons.shopping_cart_outlined,
                        color: Color(0xFFE85D9A),
                      ),
                    ),
                    Positioned(
                      right: -4,
                      top: -4,
                      child: Container(
                        constraints:
                            const BoxConstraints(minWidth: 18, minHeight: 18),
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        alignment: Alignment.center,
                        decoration: const BoxDecoration(
                          color: Color(0xFFE85D9A),
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          '$_cartCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$_cartCount 份美味已选',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  Text(
                    '合计 积分${_cartTotal.toStringAsFixed(0)}',
                    style: TextStyle(color: Colors.grey.shade700),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            FilledButton.icon(
              onPressed: _placingOrder ? null : _placeOrder,
              style: FilledButton.styleFrom(minimumSize: const Size(0, 48)),
              icon: const Icon(Icons.shopping_bag_outlined),
              label: Text(_placingOrder ? '提交中...' : '立即下单'),
            ),
          ],
        ),
      ),
    );
  }

  double _bottomOrderBarReservedHeight(BuildContext context) {
    final safeBottom = MediaQuery.of(context).padding.bottom;
    const orderBarBaseHeight = 72.0;
    return orderBarBaseHeight + safeBottom;
  }

  void _toggleCartDetailPanel() {
    setState(() {
      _showCartDetail = !_showCartDetail;
    });
  }

  Widget _buildCartDetailPanel() {
    final entries = _cart.entries.toList();
    final screenHeight = MediaQuery.of(context).size.height;
    final reservedHeight = _bottomOrderBarReservedHeight(context) + 1;
    final availableHeight = screenHeight - reservedHeight - 16;

    const headerHeight = 130.0;
    const itemHeight = 96.0;
    const maxVisibleItems = 2.5;
    final visibleItems =
        entries.length < maxVisibleItems ? entries.length : maxVisibleItems;
    final preferredHeight = headerHeight + visibleItems * itemHeight;
    final panelHeight =
        preferredHeight > availableHeight ? availableHeight : preferredHeight;

    return Positioned.fill(
      child: Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _toggleCartDetailPanel,
              child: const SizedBox.expand(),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: reservedHeight,
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                height: panelHeight,
                margin: const EdgeInsets.symmetric(horizontal: 0),
                decoration: const BoxDecoration(
                  color: Color(0xFFFFFCFE),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                  boxShadow: [
                    BoxShadow(
                      color: Color(0x22000000),
                      blurRadius: 12,
                      offset: Offset(0, -2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    const SizedBox(height: 8),
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFCFE2),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                      child: Row(
                        children: [
                          const Icon(Icons.shopping_cart_outlined,
                              color: Color(0xFFE85D9A)),
                          const SizedBox(width: 8),
                          const Text(
                            '购物车详情',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w700),
                          ),
                          const Spacer(),
                          Text(
                            '共$_cartCount份',
                            style: const TextStyle(
                              color: Color(0xFF6A5965),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 4),
                          TextButton.icon(
                            onPressed: _cart.isEmpty
                                ? null
                                : () {
                                    setState(() {
                                      _cart.clear();
                                      _showCartDetail = false;
                                    });
                                  },
                            style: TextButton.styleFrom(
                              foregroundColor: const Color(0xFFCF3D5E),
                              visualDensity: VisualDensity.compact,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 4),
                            ),
                            icon: const Icon(Icons.delete_outline_rounded,
                                size: 18),
                            label: const Text('清空购物车'),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    Expanded(
                      child: entries.isEmpty
                          ? const Center(child: Text('购物车空空的，先去选菜吧'))
                          : ListView.separated(
                              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                              itemCount: entries.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 8),
                              itemBuilder: (_, index) {
                                final cartKey = entries[index].key;
                                final entry = entries[index].value;
                                final dish = entry.dish;
                                final safeRating =
                                    dish.rating.clamp(0, 5).toInt();
                                final specText = entry.selectedSpecs
                                    .map((spec) =>
                                        '${spec.groupName}:${spec.valueName}')
                                    .join('，');

                                return Card(
                                  child: Padding(
                                    padding: const EdgeInsets.all(10),
                                    child: Row(
                                      children: [
                                        ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(10),
                                          child: SizedBox(
                                            width: 52,
                                            height: 52,
                                            child: dish.imageUrl != null &&
                                                    dish.imageUrl!.isNotEmpty
                                                ? Image.network(
                                                    dish.imageUrl!,
                                                    fit: BoxFit.cover,
                                                    errorBuilder:
                                                        (_, __, ___) =>
                                                            Container(
                                                      color: const Color(
                                                          0xFFFFF0F7),
                                                      child: const Icon(
                                                        Icons.fastfood_outlined,
                                                        color:
                                                            Color(0xFFE85D9A),
                                                      ),
                                                    ),
                                                  )
                                                : Container(
                                                    color:
                                                        const Color(0xFFFFF0F7),
                                                    child: const Icon(
                                                      Icons.fastfood_outlined,
                                                      color: Color(0xFFE85D9A),
                                                    ),
                                                  ),
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Text(
                                                dish.name,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(
                                                    fontWeight:
                                                        FontWeight.w700),
                                              ),
                                              const SizedBox(height: 2),
                                              RichText(
                                                text: TextSpan(
                                                  children: [
                                                    const TextSpan(
                                                      text: '推荐星级：',
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                        color:
                                                            Color(0xFF8A7B85),
                                                      ),
                                                    ),
                                                    TextSpan(
                                                      text: '★' * safeRating,
                                                      style: const TextStyle(
                                                        fontSize: 13,
                                                        fontWeight:
                                                            FontWeight.w700,
                                                        color:
                                                            Color(0xFFFFD66E),
                                                        shadows: [
                                                          Shadow(
                                                            color: Color(
                                                                0xFFB98B1D),
                                                            offset:
                                                                Offset(0, 1),
                                                            blurRadius: 1.6,
                                                          ),
                                                          Shadow(
                                                            color: Color(
                                                                0xFFFFF5C2),
                                                            offset:
                                                                Offset(0, -0.6),
                                                            blurRadius: 0.8,
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                '价钱：¥${(entry.unitPrice * entry.quantity).toStringAsFixed(2)}',
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.w700,
                                                  color: Color(0xFFE85D9A),
                                                ),
                                              ),
                                              if (specText.isNotEmpty)
                                                Container(
                                                  margin: const EdgeInsets.only(
                                                      top: 2),
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                    horizontal: 8,
                                                    vertical: 3,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color:
                                                        const Color(0xFFFFF0F7),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            8),
                                                    border: Border.all(
                                                        color: const Color(
                                                            0xFFFFD2E5)),
                                                  ),
                                                  child: Text(
                                                    '规格：$specText',
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    style: const TextStyle(
                                                      fontSize: 12,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      color: Color(0xFF9A2D68),
                                                    ),
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            IconButton(
                                              visualDensity:
                                                  VisualDensity.compact,
                                              onPressed: () {
                                                _removeCartKey(cartKey);
                                                if (_cart.isEmpty) {
                                                  setState(() {
                                                    _showCartDetail = false;
                                                  });
                                                }
                                              },
                                              icon: const Icon(
                                                  Icons.remove_circle_outline),
                                            ),
                                            SizedBox(
                                              width: 22,
                                              child: Center(
                                                child: Text(
                                                  '${entry.quantity}',
                                                  style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.w700),
                                                ),
                                              ),
                                            ),
                                            IconButton(
                                              visualDensity:
                                                  VisualDensity.compact,
                                              onPressed: () {
                                                setState(() {
                                                  _cart[cartKey] =
                                                      entry.copyWith(
                                                          quantity:
                                                              entry.quantity +
                                                                  1);
                                                });
                                              },
                                              icon:
                                                  const Icon(Icons.add_circle),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivitiesTab() {
    final now = DateTime.now();
    final year = now.year;
    final month = now.month;
    final daysInMonth = DateTime(year, month + 1, 0).day;
    final todayStr = DateTime.utc(now.year, now.month, now.day)
        .toIso8601String()
        .substring(0, 10);

    int signedCount = 0;
    for (int d = 1; d <= daysInMonth; d++) {
      final ds =
          DateTime.utc(year, month, d).toIso8601String().substring(0, 10);
      if (_monthChecked.contains(ds)) signedCount++;
    }

    final displayCount =
        _expandAll ? daysInMonth : (daysInMonth < 7 ? daysInMonth : 7);

    final dayCards = <Widget>[];
    for (int d = 1; d <= displayCount; d++) {
      final date = DateTime.utc(year, month, d);
      final ds = date.toIso8601String().substring(0, 10);
      final isSigned = _monthChecked.contains(ds);
      final isToday = ds == todayStr;
      final isPast = date.isBefore(DateTime.utc(now.year, now.month, now.day));
      final reward = d <= 7 ? 1 : (d <= 12 ? 2 : 3);

      final pillText = isSigned ? '已签' : (isPast ? '缺签' : '待签');
      final pillColor = isSigned
          ? const Color(0xFFFFE8BF)
          : (isPast ? const Color(0xFFEEEFF3) : const Color(0xFFFFF3E0));
      final pillTextColor =
          isSigned ? const Color(0xFF8A5600) : const Color(0xFF5B4E56);

      dayCards.add(
        Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 9),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '+${reward.toString()}',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            height: 1.1,
                          ),
                        ),
                        const SizedBox(width: 2),
                        const Icon(
                          Icons.monetization_on_outlined,
                          size: 14,
                          color: Color(0xFFFFB000),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                    decoration: BoxDecoration(
                      color: pillColor,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      pillText,
                      style: TextStyle(
                          fontSize: 9, color: pillTextColor, height: 1.1),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 7),
            Text(
              isToday ? '今天' : '第$d天',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 9, height: 1.1),
            ),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    RichText(
                      text: TextSpan(
                        style: DefaultTextStyle.of(context).style.copyWith(
                            fontSize: 16, fontWeight: FontWeight.w600),
                        children: [
                          const TextSpan(text: '本月已签到 '),
                          TextSpan(
                            text: '$signedCount',
                            style: const TextStyle(color: Color(0xFFFF9900)),
                          ),
                          const TextSpan(text: ' 天'),
                        ],
                      ),
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        const Text('拥有： '),
                        Text(
                          _loadingPoints ? '…' : _myPoints.toString(),
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 7,
                    crossAxisSpacing: 6,
                    mainAxisSpacing: 6,
                    childAspectRatio: 0.6,
                  ),
                  itemCount: dayCards.length,
                  itemBuilder: (_, i) => dayCards[i],
                ),
                const SizedBox(height: 8),
                Center(
                  child: IconButton(
                    icon: Icon(
                      _expandAll ? Icons.expand_less : Icons.expand_more,
                      color: Colors.grey.shade600,
                    ),
                    onPressed: () => setState(() => _expandAll = !_expandAll),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed:
                        (_checkingIn || _checkedInToday) ? null : _doCheckIn,
                    style: ButtonStyle(
                      backgroundColor: WidgetStatePropertyAll(
                        (_checkingIn || _checkedInToday)
                            ? Colors.orange.shade200
                            : null,
                      ),
                    ),
                    child: const Text('签到'),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        _buildTasksSection(),
      ],
    );
  }

  /// 活动任务列表（展示在签到卡片下方）
  Widget _buildTasksSection() {
    if (_loadingTasks) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    final doneCount = _tasks
        .where((task) => _submissionForTask(task.id)?.isApproved ?? false)
        .length;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.task_alt_rounded,
                    size: 18, color: Color(0xFFE85D9A)),
                const SizedBox(width: 6),
                const Text(
                  '活动任务',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF3A2A35),
                  ),
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF0F7),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '已完成 $doneCount/${_tasks.length}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFE58A00),
                    ),
                  ),
                ),
              ],
            ),
            if (_tasks.isNotEmpty && !_hasPartner) ...[
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF7FB),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFFFE1EE)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline,
                        size: 16, color: Colors.grey.shade600),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        '在个人主页绑定对象后，TA 才能收到你的任务提醒并审核',
                        style: TextStyle(
                            fontSize: 12, color: Colors.grey.shade700),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 10),
            if (_tasks.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Center(
                  child: Text(
                    '还没有配置任务哦～',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ),
              )
            else
              ..._tasks.map(_buildTaskTile),
          ],
        ),
      ),
    );
  }

  Widget _buildTaskTile(ActivityTask task) {
    final submission = _submissionForTask(task.id);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFCFE),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFFE1EE)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFFFFF0F7),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              task.type.icon,
              size: 20,
              color: const Color(0xFFE85D9A),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task.title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (task.description.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    task.description,
                    style:
                        TextStyle(fontSize: 12, color: Colors.grey.shade700),
                  ),
                ],
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.monetization_on_outlined,
                        size: 14, color: Color(0xFFFFB000)),
                    const SizedBox(width: 2),
                    Text(
                      '+${task.points}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFFFF9900),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      task.type.label,
                      style:
                          TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
                  ],
                ),
                if (submission != null && submission.isRejected) ...[
                  const SizedBox(height: 4),
                  Text(
                    '驳回原因：${(submission.rejectReason?.isNotEmpty ?? false) ? submission.rejectReason : '未填写'}',
                    style: const TextStyle(fontSize: 12, color: Colors.redAccent),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          _buildTaskAction(task, submission),
        ],
      ),
    );
  }

  Widget _buildTaskAction(ActivityTask task, TaskSubmission? submission) {
    if (submission == null || submission.isRejected) {
      return FilledButton(
        onPressed: () => _submitTask(task),
        style: FilledButton.styleFrom(
          minimumSize: const Size(72, 34),
          padding: const EdgeInsets.symmetric(horizontal: 10),
          textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        child: Text(submission == null ? '去完成' : '继续完成'),
      );
    }

    if (submission.isPending) {
      return const _TaskStatusPill(
        text: '待审核',
        background: Color(0xFFFFF3E0),
        foreground: Color(0xFFE58A00),
        icon: Icons.hourglass_top_rounded,
      );
    }

    return const _TaskStatusPill(
      text: '已完成',
      background: Color(0xFFE8F5E9),
      foreground: Color(0xFF2E7D32),
      icon: Icons.check_circle,
    );
  }
}

/// 任务状态胶囊：自绘避免 M3 主题下 Chip 文字色被吃掉
class _TaskStatusPill extends StatelessWidget {
  const _TaskStatusPill({
    required this.text,
    required this.background,
    required this.foreground,
    this.icon,
  });

  final String text;
  final Color background;
  final Color foreground;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 32,
      constraints: const BoxConstraints(minWidth: 72),
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: foreground),
            const SizedBox(width: 4),
          ],
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: foreground,
            ),
          ),
        ],
      ),
    );
  }
}

/// 订单卡片下方三按钮的统一封装：图标 + 文字、圆角、独立配色、禁用态自动淡化。
class _OrderActionButton extends StatelessWidget {
  const _OrderActionButton({
    required this.label,
    required this.icon,
    required this.foreground,
    required this.background,
    required this.disabledForeground,
    required this.disabledBackground,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final Color foreground;
  final Color background;
  final Color disabledForeground;
  final Color disabledBackground;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    final fg = enabled ? foreground : disabledForeground;
    final bg = enabled ? background : disabledBackground;
    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: fg),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: fg,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
