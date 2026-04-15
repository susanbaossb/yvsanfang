/// 菜谱模型
/// 
/// 功能：存储菜谱基本信息（名称、描述、分类、创建时间）
/// 注意：菜谱与菜品是两个不同概念，菜谱用于记录做法

class Recipe {
  Recipe({
    required this.id,
    required this.name,
    required this.description,
    required this.categoryName,
    required this.createdAt,
  });

  final String id;
  final String name;
  final String description;
  final String? categoryName;
  final DateTime createdAt;

  factory Recipe.fromJson(Map<String, dynamic> json) {
    final category = json['recipe_categories'] as Map<String, dynamic>?;
    return Recipe(
      id: json['id'] as String,
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      categoryName: category == null ? null : category['name'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}
