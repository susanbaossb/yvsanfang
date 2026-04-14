// ignore_for_file: invalid_use_of_protected_member

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
                  child: const Icon(Icons.favorite_rounded, color: Color(0xFFE85D9A), size: 24),
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
              children: _categories
                  .map(
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
                          onSelected: (_) => setState(() => _selectedCategory = category),
                        ),
                      );
                    },
                  )
                  .toList(),
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
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: SizedBox(
                          width: 58,
                          height: 58,
                          child: dish.imageUrl != null && dish.imageUrl!.isNotEmpty
                              ? Image.network(
                                  dish.imageUrl!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Container(
                                    color: const Color(0xFFFFF0F7),
                                    child: const Icon(Icons.ramen_dining, color: Color(0xFFE85D9A)),
                                  ),
                                )
                              : Container(
                                  color: const Color(0xFFFFF0F7),
                                  child: const Icon(Icons.ramen_dining, color: Color(0xFFE85D9A)),
                                ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(dish.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                            const SizedBox(height: 2),
                            Text(
                              dish.description,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: Color(0xFF5C4A56))
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
                            onPressed: quantity > 0 ? () => _removeDish(dish) : null,
                            icon: const Icon(Icons.remove_circle_outline),
                          ),
                          SizedBox(width: 20, child: Center(child: Text('$quantity'))),
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
              final shortId = order.id.length >= 8 ? order.id.substring(0, 8) : order.id;
              final normalizedStatus = _normalizedOrderStatus(order.status);
              return Card(
                margin: const EdgeInsets.only(bottom: 10),
                child: Padding(
                  padding: const EdgeInsets.all(12),
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
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
                            DateFormat('MM-dd HH:mm').format(order.createdAt.toLocal()),
                            style: const TextStyle(color: Color(0xFF6A5965))
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text('菜品信息：', style: TextStyle(fontWeight: FontWeight.w600)),
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
                                  child: item.imageUrl != null && item.imageUrl!.isNotEmpty
                                      ? Image.network(
                                          item.imageUrl!,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) => Container(
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
                      if (order.note != null && order.note!.trim().isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          '备注：${order.note!.trim()}',
                          style: TextStyle(color: Colors.grey.shade700),
                        ),
                      ],
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          OutlinedButton(
                            onPressed: _updatingOrder || normalizedStatus != 'unfinished'
                                ? null
                                : () => _updateOrderStatus(order, 'completed'),
                            child: const Text('完成订单'),
                          ),
                          OutlinedButton(
                            onPressed: _updatingOrder || normalizedStatus != 'unfinished'
                                ? null
                                : () => _updateOrderStatus(order, 'cancelled'),
                            child: const Text('取消订单'),
                          ),
                          TextButton(
                            onPressed: _updatingOrder
                                ? null
                                : () => _deleteOrder(order),
                            child: const Text('删除订单'),
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
    return FilterChip(
      label: Text(label),
      selected: _orderFilter == key,
      onSelected: (_) => setState(() => _orderFilter = key),
    );
  }


  Widget _buildProfileTab() {
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        Card(
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              child: Text(widget.profile.nickname.isNotEmpty ? widget.profile.nickname.substring(0, 1) : '我'),
            ),
            title: Text(widget.profile.nickname),
            subtitle: Text('身份：${widget.profile.role}'),
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
              subtitle: '厨房动态与提醒',
              onTap: () {},
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickAction({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
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
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Icon(icon, color: const Color(0xFFE85D9A)),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                    ),
                  ],
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
            FilledButton.icon(
              onPressed: _placingOrder ? null : _placeOrder,
              icon: const Icon(Icons.shopping_bag_outlined),
              label: Text(_placingOrder ? '提交中...' : '立即下单'),
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildActivitiesTab() {
    final now = DateTime.now();
    final year = now.year;
    final month = now.month;
    final daysInMonth = DateTime(year, month + 1, 0).day;
    final todayStr = DateTime.utc(now.year, now.month, now.day).toIso8601String().substring(0, 10);

    int signedCount = 0;
    for (int d = 1; d <= daysInMonth; d++) {
      final ds = DateTime.utc(year, month, d).toIso8601String().substring(0, 10);
      if (_monthChecked.contains(ds)) signedCount++;
    }

    final displayCount = _expandAll ? daysInMonth : (daysInMonth < 7 ? daysInMonth : 7);

    final dayCards = <Widget>[];
    for (int d = 1; d <= displayCount; d++) {
      final date = DateTime.utc(year, month, d);
      final ds = date.toIso8601String().substring(0, 10);
      final isSigned = _monthChecked.contains(ds);
      final isToday = ds == todayStr;
      final isPast = date.isBefore(DateTime.utc(now.year, now.month, now.day));
      final reward = d <= 5 ? 10 : (d <= 10 ? 20 : 30);

      final pillText = isSigned ? '已签' : (isPast ? '缺签' : '待签');
      final pillColor = isSigned
          ? const Color(0xFFFFE8BF)
          : (isPast ? const Color(0xFFEEEFF3) : const Color(0xFFFFF3E0));
      final pillTextColor = isSigned ? const Color(0xFF8A5600) : const Color(0xFF5B4E56);

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
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                    decoration: BoxDecoration(
                      color: pillColor,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      pillText,
                      style: TextStyle(fontSize: 9, color: pillTextColor, height: 1.1),
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
                        style: DefaultTextStyle.of(context)
                            .style
                            .copyWith(fontSize: 16, fontWeight: FontWeight.w600),
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
                    onPressed: (_checkingIn || _checkedInToday) ? null : _doCheckIn,
                    style: ButtonStyle(
                      backgroundColor: WidgetStatePropertyAll(
                        (_checkingIn || _checkedInToday) ? Colors.orange.shade200 : null,
                      ),
                    ),
                    child: const Text('签到'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
