/// 菜谱分类模型
/// 
/// 功能：存储菜谱分类信息（名称、排序顺序、创建时间）
/// 用于在厨房 Tab 中按分类筛选菜品

class RecipeCategory {
  RecipeCategory({
    required this.id,
    required this.name,
    required this.sortOrder,
    required this.createdAt,
  });

  final String id;
  final String name;
  final int sortOrder;
  final DateTime createdAt;

  factory RecipeCategory.fromJson(Map<String, dynamic> json) {
    return RecipeCategory(
      id: json['id'] as String,
      name: json['name'] as String? ?? '',
      sortOrder: (json['sort_order'] as num?)?.toInt() ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}
