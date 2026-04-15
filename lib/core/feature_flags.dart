/// 应用功能开关配置
/// 
/// 功能：集中管理应用的特性开关
/// 当前开关：
/// - showPointsAdjustSettings：是否在"我的"页面显示"加减积分设置"入口

class AppFeatureFlags {
  AppFeatureFlags._();

  /// 我的页面是否展示“加减积分设置”入口。
  /// true: 显示，false: 隐藏。
  static const bool showPointsAdjustSettings = true;
}
