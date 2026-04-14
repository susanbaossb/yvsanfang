# 御膳房（Flutter）

一个基于 Flutter + Supabase 的家庭点餐与积分管理应用，支持菜品下单、订单流转、每日签到积分、分类与菜单管理，以及管理员积分调整。

## 核心功能

- 厨房点餐：浏览菜品、选择规格、加入购物车并提交订单
- 订单管理：按状态筛选订单，支持未完成/已完成/已取消/删除
- 活动签到：每日签到、月度签到展示、积分累计
- 我的页面：分类管理、菜单管理、设置管理入口
- 设置管理：查看注册用户信息，对指定用户加积分/减积分

## UI 风格（可爱甜美）

- 主色调：粉色系 + 奶白背景（柔和、轻盈）
- 视觉元素：高圆角卡片、轻边框、低阴影
- 交互组件：统一按钮高度与输入框样式，提升一致性
- 导航与列表：减少视觉噪音，强化重点信息可读性


## 项目目录说明

```text
lib/
├─ app.dart                      # 根组件与应用入口壳
├─ main.dart                     # 程序启动与初始化
├─ core/
│  └─ supabase_client.dart       # Supabase 客户端与配置
├─ models/                       # 数据模型
│  ├─ dish.dart                  # 菜品/规格/购物车项模型
│  ├─ order_summary.dart         # 订单摘要模型
│  ├─ recipe.dart                # 菜谱模型
│  ├─ recipe_category.dart       # 菜谱分类模型
│  └─ user_profile.dart          # 用户资料模型（含积分）
├─ services/                     # 业务服务层（Supabase 读写）
│  ├─ auth_service.dart          # 匿名登录、资料读取与保存
│  ├─ menu_service.dart          # 菜单相关接口
│  ├─ order_service.dart         # 订单相关接口
│  ├─ order_email_service.dart   # 下单邮件通知（SMTP）
│  ├─ points_service.dart        # 积分/签到/积分调整接口
│  └─ recipe_service.dart        # 分类与菜谱接口
└─ features/
   ├─ auth/
   │  └─ login_page.dart         # 登录与首次资料填写
   ├─ menu/
   │  └─ menu_management_page.dart # 菜单管理页面
   └─ home/
      ├─ home_page.dart          # Home 主页面（状态与路由壳）
      ├─ home_page_actions.dart  # Home 业务动作与数据处理
      ├─ home_page_dialogs.dart  # Home 弹窗（规格选择/分类管理）
      ├─ home_page_tabs.dart     # Home 各 Tab 视图构建
      ├─ home_page_models.dart   # Home 私有模型
      └─ settings_management_page.dart # 设置管理页（用户与积分）
```

## 技术栈

- Flutter (Material 3)
- Supabase
- `intl`（时间格式化）
- `mailer`（SMTP 邮件发送）

## 邮件通知配置

在根目录 `.env` 中配置下单通知邮箱：

```env
ORDER_NOTIFY_EMAIL=1951345484@qq.com
QQ_EMAIL_ACCOUNT=
QQ_EMAIL_AUTH_CODE=
QQ_SMTP_HOST=smtp.qq.com
QQ_SMTP_PORT=465
```

说明：
- `ORDER_NOTIFY_EMAIL`：接收订单通知的邮箱（可改成任意地址）
- `QQ_EMAIL_ACCOUNT` / `QQ_EMAIL_AUTH_CODE`：用于发送邮件，需在 QQ 邮箱开启 SMTP 并获取授权码
