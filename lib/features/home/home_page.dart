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
import '../../models/activity_task.dart';
import '../../models/dish.dart';
import '../../services/activity_task_service.dart';
import '../activity/notification_page.dart';
import '../activity/order_detail_page.dart';
import '../activity/task_management_page.dart';
import '../activity/task_submit_sheet.dart';
import '../../core/supabase_client.dart';
import '../message/message_list_page.dart';
import '../../services/message_service.dart';
import '../menu/dish_detail_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/order_summary.dart';
import '../../models/recipe_category.dart';
import '../../models/user_profile.dart';
import '../../services/auth_service.dart';
import '../../features/auth/login_page.dart';
import '../../services/menu_service.dart';
import '../../services/order_email_service.dart';
import '../../services/order_service.dart';
import '../../services/points_service.dart';
import '../../services/local_user_storage.dart';
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
  final _taskService = ActivityTaskService();
  final _messageService = MessageService();
  int _messageUnread = 0;
  RealtimeChannel? _messageChannel;

  List<Dish> _dishes = [];
  List<OrderSummary> _orders = [];
  List<RecipeCategory> _recipeCategories = [];
  final Map<String, _CartEntry> _cart = {};
  List<ActivityTask> _tasks = [];
  List<TaskSubmission> _mySubmissions = [];
  bool _loadingTasks = true;

  /// 待我审核的任务提交数量（绑定对象提交的）
  int _pendingReviewCount = 0;

  /// 是否已绑定对象（未绑定时任务无法被审核）
  bool _hasPartner = false;

  /// 消息中心：活动消息未读数（任务提交/审核）
  int _activityUnread = 0;

  /// 消息中心：订单消息未读数（对方下单动态）
  int _orderUnread = 0;

  /// 绑定对象 ID（用于订单消息列表）
  String _partnerId = '';

  /// 绑定对象昵称（用于私聊行展示）
  String _partnerNickname = '';

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
    // 先确保当前用户身份就绪，再加载依赖 userId 的数据
    // （initCurrentUser 是异步的，必须先 await，否则首屏会用 null 的
    //  userId 去查询，导致签到状态/积分为默认值 0/未签到，且异常被静默吞掉）
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    await _authService.initCurrentUser();
    if (!mounted) return;
    _loadMenu();
    _loadOrders();
    _loadRecipeCategories();
    _loadPoints();
    _checkToday();
    _loadMonthCheckins();
    _loadActivityTasks();
    _loadPendingReviews();
    _subscribeMessages();
    _loadMessageUnread();
    _loadMessageCenterUnread();
  }

  @override
  void dispose() {
    _messageChannel?.unsubscribe();
    super.dispose();
  }

  /// 首页订阅「发给我的消息」，用于实时更新「消息」角标
  void _subscribeMessages() {
    final myId = _authService.currentUserId;
    if (myId == null) return;
    _messageChannel?.unsubscribe();
    _messageChannel = AppSupabase.client
        .channel('home_messages:$myId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'messages',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'receiver_id',
            value: myId,
          ),
          callback: (_) {
            if (mounted) setState(() => _messageUnread++);
          },
        )
        .subscribe();
  }

  /// 拉取我收到的未读消息数（用于「消息」角标）
  Future<void> _loadMessageUnread() async {
    final myId = _authService.currentUserId;
    if (myId == null) return;
    try {
      final n = await _messageService.fetchUnreadCount(myId);
      if (mounted) setState(() => _messageUnread = n);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final tabTitles = ['厨房', '订单', '活动', '消息', '我的'];
    // 用 IndexedStack 缓存 4 个 tab：只在首次 build 时各构建一次，
    // 切 tab 时不再重建（避免活动页等每次切回都整页重绘/像刷新）。
    final body = IndexedStack(
      index: _tabIndex,
      children: [
        _buildKitchenTab(),
        _buildOrdersTab(),
        _buildActivitiesTab(),
        _buildMessagesTab(),
        _buildProfileTab(),
      ],
    );

    return Scaffold(
      appBar: AppBar(
        title: Text('${tabTitles[_tabIndex]} · ${widget.profile.nickname}'),
        actions: [
          if (_tabIndex == 1)
            IconButton(
              onPressed: _loadOrders,
              icon: const Icon(Icons.refresh),
            ),
          if (_tabIndex == 4 && AppFeatureFlags.showPointsAdjustSettings)
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
        onDestinationSelected: (index) {
          setState(() {
            _tabIndex = index;
            if (index != 0) {
              _showCartDetail = false;
            }
          });
          // 切到"消息"页刷新各分类未读（消息回执为异步到达）
          if (index == 3) {
            _loadMessageCenterUnread();
            _loadMessageUnread();
          }
          // 切到"我的"页刷新待审核数量（消息回执为异步到达）
          if (index == 4) {
            _loadPendingReviews();
          }
        },
        destinations: [
          NavigationDestination(
              icon: Icon(Icons.soup_kitchen_outlined), label: '厨房'),
          NavigationDestination(
              icon: Icon(Icons.receipt_long_outlined), label: '订单'),
          NavigationDestination(
              icon: Icon(Icons.local_activity_outlined), label: '活动'),
          NavigationDestination(
            icon: Badge.count(
              count: _activityUnread + _orderUnread + _messageUnread,
              isLabelVisible:
                  _activityUnread + _orderUnread + _messageUnread > 0,
              child: const Icon(Icons.chat_bubble_outline),
            ),
            label: '消息',
          ),
          NavigationDestination(icon: Icon(Icons.person_outline), label: '我的'),
        ],
      ),
    );
  }
}
