# 御膳房（Flutter）

一个基于 Flutter + Supabase 的家庭点餐与积分管理应用，支持菜品下单、订单流转、每日签到积分、分类与菜单管理，以及管理员积分调整。

## 核心功能

- **厨房点餐**：浏览菜品、选择规格、加入购物车并提交订单
- **订单管理**：按状态筛选订单，支持未完成/已完成/已取消/删除
- **消息与提醒**：聚合订单动态与任务审核结果，分「待我审核 / 我的消息 / 订单」三个标签页，可点击进入详情
- **活动任务**：配置文字 / 图片视频 / 语音三类任务，对方提交后由你审核，通过即加积分
- **订单与任务详情**：从消息列表或首页订单点击进入详情页；任务详情页内可直接「通过 / 不通过」审核
- **活动签到**：每日签到、月度签到展示、积分累计
- **个人中心**：编辑资料、绑定对象、分类管理、菜单管理、设置管理
- **绑定对象**：输入昵称或邮箱绑定另一半，双向下单邮件通知
- **设置管理**：查看注册用户信息，对指定用户加积分/减积分

## UI 风格（可爱甜美）

- 主色调：粉色系 + 奶白背景（柔和、轻盈）
- 视觉元素：高圆角卡片、轻边框、低阴影
- 交互组件：统一按钮高度与输入框样式，提升一致性
- 导航与列表：减少视觉噪音，强化重点信息可读性

## 项目目录说明

```text
lib/
├─ main.dart                        # 程序入口（环境初始化、错误处理、启动图）
├─ app.dart                         # 根组件（主题配置、启动页面路由）
├─ core/
│  ├─ supabase_client.dart          # Supabase 客户端与配置
│  └─ feature_flags.dart            # 功能开关配置
├─ models/                          # 数据模型层
│  ├─ user_profile.dart             # 用户资料模型（昵称、身份、积分、邮箱）
│  ├─ dish.dart                     # 菜品模型（名称、价格、分类、规格）
│  ├─ order_summary.dart            # 订单模型（状态、金额、明细、order_no）
│  ├─ activity_task.dart            # 活动任务模型（TaskType / ActivityTask / TaskSubmission）
│  ├─ recipe.dart                   # 菜谱模型
│  └─ recipe_category.dart          # 菜谱分类模型
├─ services/                        # 业务服务层（Supabase 数据库操作）
│  ├─ auth_service.dart             # 认证服务（资料管理、头像上传、绑定对象）
│  ├─ local_user_storage.dart       # 本地存储服务（用户会话持久化）
│  ├─ menu_service.dart             # 菜单服务（菜品 CRUD、上下架）
│  ├─ order_service.dart            # 订单服务（下单、查询、更新状态、生成订单号）
│  ├─ order_email_service.dart      # 邮件通知服务（QQ SMTP 下单邮件）
│  ├─ activity_task_service.dart    # 活动任务服务（任务与提交记录读写、审核）
│  ├─ points_service.dart           # 积分服务（签到、积分增减）
│  └─ recipe_service.dart           # 菜谱分类服务（分类 CRUD）
└─ features/
   ├─ splash/
   │  └─ splash_screen.dart         # 启动页（展示 Logo，2秒后跳转）
   ├─ auth/
   │  └─ login_page.dart            # 登录页（首次使用填写资料）
   ├─ menu/
   │  ├─ menu_management_page.dart  # 菜单管理页（菜品增删改查、分类选择）
   │  └─ dish_detail_page.dart     # 菜品详情页（查看菜品信息、跳转编辑）
   ├─ activity/                      # 消息与提醒、活动任务
   │  ├─ notification_page.dart      # 消息中心（待我审核 / 我的消息 / 订单）
   │  ├─ task_management_page.dart   # 任务管理页（增删改、启用/停用）
   │  ├─ task_review_card.dart       # 待审核卡片（通过/不通过）
   │  ├─ submission_content.dart     # 提交内容展示（文字/图片/视频/语音，卡片与详情页复用）
   │  ├─ order_detail_page.dart      # 订单详情页
   │  ├─ submission_detail_page.dart # 任务提交详情页（可直接审核）
   │  └─ media_preview_page.dart     # 媒体预览页（图片/视频）
   └─ home/
      ├─ home_page.dart             # 主页入口（状态管理、路由壳）
      ├─ home_page_models.dart      # 主页私有模型（购物车条目）
      ├─ home_page_actions.dart     # 主页业务动作（数据加载、购物车、订单操作）
      ├─ home_page_dialogs.dart      # 主页弹窗（规格选择、分类管理）
      ├─ home_page_tabs.dart         # 主页 Tab 视图（厨房、订单、活动、我的）
      ├─ profile_edit_page.dart     # 个人信息编辑页（头像、昵称、身份、邮箱）
      └─ settings_management_page.dart # 设置管理页（用户列表、积分调整）
```

## 技术栈

- **Flutter** (Material 3) - UI 框架
- **Supabase** - 后端即服务（数据库、存储、认证）
- **intl** - 时间格式化
- **mailer** - SMTP 邮件发送
- **image_picker** - 图片选择

## 数据库表结构

### profiles（用户资料表）
| 字段 | 类型 | 说明 |
|------|------|------|
| id | uuid | 主键（本地 UUID） |
| nickname | text | 昵称 |
| role | text | 身份角色 |
| points | integer | 积分余额 |
| avatar_url | text | 头像 URL |
| email | text | 绑定邮箱 |
| partner_id | text | 绑定对象 ID |
| partner_nickname | text | 绑定对象昵称 |

### dishes（菜品表）
| 字段 | 类型 | 说明 |
|------|------|------|
| id | uuid | 主键 |
| name | text | 菜品名称 |
| description | text | 描述 |
| category | text | 分类 |
| price | numeric | 价格 |
| rating | integer | 评分 1-5 |
| available | boolean | 是否上架 |
| enable_multi_spec | boolean | 是否启用多规格 |
| specs_json | jsonb | 规格配置 JSON |
| image_url | text | 图片 URL |
| deleted | boolean | 软删除标记 |

### orders（订单表）
| 字段 | 类型 | 说明 |
|------|------|------|
| id | uuid | 主键 |
| user_id | uuid | 下单用户 |
| status | text | 状态（unfinished/completed/cancelled/deleted） |
| total_amount | numeric | 积分总额 |
| note | text | 备注 |
| order_no | text | 18 位纯数字订单号（新订单由客户端生成；历史订单为 NULL） |
| created_at | timestamp | 创建时间 |
| updated_at | timestamp | 状态变更时间（更新状态时写入，用于消息时间判定） |

### order_items（订单明细表）
| 字段 | 类型 | 说明 |
|------|------|------|
| id | uuid | 主键 |
| order_id | uuid | 订单 ID |
| dish_id | uuid | 菜品 ID |
| quantity | integer | 数量 |
| price | numeric | 单价 |

### activity_tasks（活动任务配置表）
| 字段 | 类型 | 说明 |
|------|------|------|
| id | uuid | 主键 |
| title | text | 任务标题 |
| description | text | 任务描述 |
| points | integer | 完成后奖励积分 |
| type | text | 类型（text / media / audio） |
| enabled | boolean | 是否启用 |
| sort_order | integer | 排序顺序 |
| deleted | boolean | 软删除标记 |
| created_at | timestamptz | 创建时间 |

### activity_task_submissions（任务提交记录表）
| 字段 | 类型 | 说明 |
|------|------|------|
| id | uuid | 主键 |
| task_id | uuid | 关联任务 ID |
| user_id | uuid | 提交用户 ID（本地 UUID，不关联 auth.users） |
| nickname | text | 提交时冗余的昵称 |
| task_title | text | 提交时冗余的任务标题 |
| task_points | integer | 提交时冗余的任务积分 |
| task_type | text | 提交时冗余的任务类型 |
| content | text | 文字描述内容 |
| media_url | text | 图片 / 视频 / 语音地址 |
| status | text | 审核状态（pending / approved / rejected） |
| reject_reason | text | 驳回原因 |
| created_at | timestamptz | 提交时间 |
| reviewed_at | timestamptz | 审核时间 |

> 媒体文件存储于 Supabase Storage 桶 `activity-media`（公开桶，单文件上限 50MB）。

### daily_checkins（每日签到表）
| 字段 | 类型 | 说明 |
|------|------|------|
| id | uuid | 主键 |
| user_id | uuid | 用户 ID |
| date | date | 签到日期 |

### recipe_categories（菜谱分类表）
| 字段 | 类型 | 说明 |
|------|------|------|
| id | uuid | 主键 |
| name | text | 分类名称 |
| sort_order | integer | 排序顺序 |
| created_at | timestamp | 创建时间 |

> ⚠️ **RLS 注意事项**：`dishes`、`recipe_categories`、`activity_tasks`、`activity_task_submissions` 表需要**禁用 RLS**（或配置宽松的公开策略），否则会导致菜品更新、分类查询、活动任务读写失败：
> ```sql
> ALTER TABLE dishes DISABLE ROW LEVEL SECURITY;
> ALTER TABLE recipe_categories DISABLE ROW LEVEL SECURITY;
> ALTER TABLE activity_tasks DISABLE ROW LEVEL SECURITY;
> ALTER TABLE activity_task_submissions DISABLE ROW LEVEL SECURITY;
> ```

## 积分规则

| 日期范围 | 签到奖励 |
|----------|----------|
| 每月 1-7 日 | +1 积分 |
| 每月 8-12 日 | +2 积分 |
| 每月 13-30 日 | +3 积分 |

下单时使用积分支付，1 价格单位 = 1 积分。

## 邮件通知配置

在根目录 `.env` 中配置下单通知邮箱：

```env
QQ_EMAIL_ACCOUNT=你的QQ邮箱
QQ_EMAIL_AUTH_CODE=邮箱授权码
QQ_SMTP_HOST=smtp.qq.com
QQ_SMTP_PORT=465
```

说明：
- `QQ_EMAIL_ACCOUNT` / `QQ_EMAIL_AUTH_CODE`：用于发送邮件，需在 QQ 邮箱开启 SMTP 并获取授权码
- **发送规则**：下单后优先发送给**绑定对象**的邮箱；如果没有绑定对象或绑定对象未设置邮箱，则不发送邮件

## 运行项目

```bash
# 安装依赖
flutter pub get

# 运行开发版本
flutter run

# 构建 APK
flutter build apk

# 构建 release 版本
flutter run --release
```

## 开发说明

### 文件注释规范
每个 Dart 文件开头包含三段式注释：
- **功能说明**：文件的核心用途
- **字段/方法说明**：重要字段和方法的作用
- **使用场景**：何时会被调用

### 状态管理
主页使用 StatefulWidget 管理状态，扩展方法按功能分组：
- `home_page_actions.dart`：业务动作和数据加载
- `home_page_dialogs.dart`：弹窗组件
- `home_page_tabs.dart`：各 Tab 的 UI 构建

### Supabase 初始化
在 `main.dart` 中，Supabase 初始化在启动图显示后后台执行，不阻塞 UI 渲染。

### 表单处理注意事项
菜品编辑表单使用 `StatefulBuilder` + `showModalBottomSheet`，需要注意：
- 表单值使用 `_DishFormData` 类封装（而非基本类型），避免 Dart 闭包捕获问题
- `onChanged` 回调通过 `setBottomState` 触发 UI 更新，同时修改 `formData` 对象属性
- 这样做是因为基本类型在闭包中被捕获为值拷贝，不会影响外层变量

### 本地登录系统
项目使用**本地 UUID** 作为用户标识，而非 Supabase Auth：
- 用户 ID 由本地 `uuid` 包生成，通过 `local_user_storage.dart` 的 `flutter_secure_storage` 持久化存储
- 登录即注册，首次输入昵称即创建本地账户
- RLS（行级安全策略）在相关表上已禁用，以支持本地 UUID 登录模式
- 进入主页前需调用 `AuthService.initCurrentUser()` 从本地存储恢复用户状态

## 版本信息

- **应用名称**：御膳房
- **当前版本**：1.0.3
- **开发团队**：susanbao

## 更新日志

### v1.0.3 (2026-09-03)
- 新增：消息中心 `notification_page.dart`（待我审核 / 我的消息 / 订单 三个标签页）
- 新增：活动任务系统「任务管理页 + 待审核卡片 + 提交内容展示（文字/图片/视频/语音）」
- 新增：订单详情页 `order_detail_page.dart` 与任务提交详情页 `submission_detail_page.dart`（详情页内可直接通过/驳回审核）
- 新增：消息列表卡片点击跳转详情页；任务详情页复用审核能力
- 新增：18 位纯数字订单号 `order_no`（新订单由客户端生成，历史订单保持原 UUID 不动）
- 优化：消息列表「我的消息」与「订单」卡片显示时间（今天 HH:mm / M月d日 HH:mm）
- 数据库：新增 `orders.order_no` 列、`activity_tasks` / `activity_task_submissions` 表、`activity-media` 存储桶（迁移见 `supabase/`）
- 文档：补充核心功能、目录结构、数据库表结构与 RLS 注意事项

### v1.0.2 (2026-04-20)
- 新增：菜品详情页 `dish_detail_page.dart`（展示菜品图片、名称、描述、分类、星级、价格、规格选项）
- 新增：厨房 Tab 菜品图片点击跳转详情页
- 优化：菜品编辑表单使用 `_DishFormData` 类解决 `StatefulBuilder` 闭包捕获问题
- 优化：详情页布局调整（去除上下架显示，调整信息展示顺序）
- 修复：从详情页跳转编辑后分类选择不生效的问题
- 文档：添加 RLS 注意事项说明

### v1.0.1 (2026-04-17)
- 新增：绑定对象功能（双向绑定，下单邮件通知给绑定对象）
- 新增：`profiles` 表 `partner_id` 和 `partner_nickname` 字段
- 优化：下单邮件优先发送给绑定对象邮箱
- 优化：邮件发送失败不影响下单流程
- 修复：`AuthService` 初始化问题（需在页面中调用 `initCurrentUser()`）
- 修复：本地 UUID 登录与 Supabase RLS 兼容性问题
- 移除：极光推送（已停用）
