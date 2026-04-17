/// 主页（HomePage）
/// 
/// 功能：应用主页面，包含底部导航栏的四个 Tab
/// - Tab 0 厨房：浏览菜品、加入购物车、下单
/// - Tab 1 订单：查看和管理订单
/// - Tab 2 活动：每日签到、查看积分
/// - Tab 3 我的：个人信息、分类管理、菜单管理、设置管理
/// 
/// 文件结构：
/// - home_page.dart：主页 State 和路由壳
/// - home_page_models.dart：购物车私有模型
/// - home_page_actions.dart：业务动作方法
/// - home_page_dialogs.dart：弹窗组件
/// - home_page_tabs.dart：各 Tab 的 UI 构建

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/feature_flags.dart';
import '../../models/dish.dart';
import '../../models/order_summary.dart';
import '../../models/recipe_category.dart';
import '../../models/user_profile.dart';
import '../../services/auth_service.dart';
import '../../services/menu_service.dart';
import '../../services/order_email_service.dart';
import '../../services/order_service.dart';
import '../../services/points_service.dart';
import '../../services/recipe_service.dart';
import '../menu/menu_management_page.dart';
import 'profile_edit_page.dart';
import 'settings_management_page.dart';

part 'home_page_actions.dart';
part 'home_page_dialogs.dart';
part 'home_page_models.dart';
part 'home_page_tabs.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key, required this.profile});

  final UserProfile profile;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _menuService = MenuService();
  final _orderService = OrderService();
  final _orderEmailService = OrderEmailService();
  final _authService = AuthService();
  final _recipeService = RecipeService();
  final _pointsService = PointsService();

  List<Dish> _dishes = [];
  List<OrderSummary> _orders = [];
  List<RecipeCategory> _recipeCategories = [];
  final Map<String, _CartEntry> _cart = {};

  bool _loadingMenu = true;
  bool _loadingOrders = true;
  bool _placingOrder = false;
  bool _updatingOrder = false;

  int _tabIndex = 0;
  String _selectedCategory = '全部';
  String _orderFilter = '全部';

  int _myPoints = 0;
  bool _loadingPoints = true;
  bool _checkingIn = false;
  bool _checkedInToday = false;
  Set<String> _monthChecked = {};
  bool _expandAll = false;
  bool _showCartDetail = false;

  @override
  void initState() {
    super.initState();
    // 初始化当前用户
    _authService.initCurrentUser();
    _loadMenu();
    _loadOrders();
    _loadRecipeCategories();
    _loadPoints();
    _checkToday();
    _loadMonthCheckins();
  }

  @override
  Widget build(BuildContext context) {
    final tabTitles = ['厨房', '订单', '活动', '我的'];
    final body = [
      _buildKitchenTab(),
      _buildOrdersTab(),
      _buildActivitiesTab(),
      _buildProfileTab(),
    ][_tabIndex];

    return Scaffold(
      appBar: AppBar(
        title: Text('${tabTitles[_tabIndex]} · ${widget.profile.nickname}'),
        actions: [
          if (_tabIndex == 1)
            IconButton(
              onPressed: _loadOrders,
              icon: const Icon(Icons.refresh),
            ),
          if (_tabIndex == 3 && AppFeatureFlags.showPointsAdjustSettings)
            IconButton(
              onPressed: _openSettingsManager,
              icon: const Icon(Icons.settings_suggest_outlined),
            ),
        ],
      ),
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFFFFF4FA), Color(0xFFFFFCFE)],
              ),
            ),
            child: body,
          ),
          if (_tabIndex == 0 && _cartCount > 0 && _showCartDetail)
            _HomePageTabs(this)._buildCartDetailPanel(),
        ],
      ),
      bottomSheet: _buildBottomOrderBar(),
      bottomNavigationBar: NavigationBar(
        elevation: 1,
        selectedIndex: _tabIndex,
        onDestinationSelected: (index) => setState(() {
          _tabIndex = index;
          if (index != 0) {
            _showCartDetail = false;
          }
        }),
        destinations: const [
          NavigationDestination(
              icon: Icon(Icons.soup_kitchen_outlined), label: '厨房'),
          NavigationDestination(
              icon: Icon(Icons.receipt_long_outlined), label: '订单'),
          NavigationDestination(
              icon: Icon(Icons.local_activity_outlined), label: '活动'),
          NavigationDestination(icon: Icon(Icons.person_outline), label: '我的'),
        ],
      ),
    );
  }
}
