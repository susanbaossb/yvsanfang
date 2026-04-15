/// 菜品模型及相关规格模型
/// 
/// 包含三个类：
/// 1. Dish：菜品基本信息
///    - enableMultiSpec: 是否启用多规格选择
///    - specGroups: 规格组列表（如：口味、温度、配料）
/// 2. DishSpecGroup：规格组（必选/可选、最小/最大选择数）
/// 3. DishSpecValue：规格选项（名称、加价）

class Dish {
  Dish({
    required this.id,
    required this.name,
    required this.price,
    required this.description,
    required this.category,
    required this.available,
    this.imageUrl,
    this.rating = 5,
    this.enableMultiSpec = false,
    this.specGroups = const [],
  });

  final String id;
  final String name;
  final double price;
  final String description;
  final String category;
  final bool available;
  final String? imageUrl;
  final int rating;
  final bool enableMultiSpec;
  final List<DishSpecGroup> specGroups;

  factory Dish.fromJson(Map<String, dynamic> json) {
    final rawSpecs = json['specs_json'];
    final specs = rawSpecs is List
        ? rawSpecs
            .whereType<Map>()
            .map((item) => DishSpecGroup.fromJson(item.cast<String, dynamic>()))
            .toList()
        : <DishSpecGroup>[];

    return Dish(
      id: json['id'] as String,
      name: json['name'] as String? ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0,
      description: json['description'] as String? ?? '',
      category: json['category'] as String? ?? '未分类',
      available: json['available'] as bool? ?? false,
      imageUrl: json['image_url'] as String?,
      rating: (json['rating'] as num?)?.toInt() ?? 5,
      enableMultiSpec: json['enable_multi_spec'] as bool? ?? false,
      specGroups: specs,
    );
  }
}

class DishSpecGroup {
  DishSpecGroup({
    required this.name,
    required this.minSelect,
    required this.maxSelect,
    required this.values,
  });

  final String name;
  final int minSelect;
  final int maxSelect;
  final List<DishSpecValue> values;

  factory DishSpecGroup.fromJson(Map<String, dynamic> json) {
    final rawValues = json['values'];
    final parsedValues = rawValues is List
        ? rawValues
            .whereType<Map>()
            .map((item) => DishSpecValue.fromJson(item.cast<String, dynamic>()))
            .toList()
        : <DishSpecValue>[];

    return DishSpecGroup(
      name: json['name'] as String? ?? '',
      minSelect: (json['min_select'] as num?)?.toInt() ?? 0,
      maxSelect: (json['max_select'] as num?)?.toInt() ?? 0,
      values: parsedValues,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'min_select': minSelect,
      'max_select': maxSelect,
      'values': values.map((item) => item.toJson()).toList(),
    };
  }
}

class DishSpecValue {
  DishSpecValue({required this.name, required this.price});

  final String name;
  final double price;

  factory DishSpecValue.fromJson(Map<String, dynamic> json) {
    return DishSpecValue(
      name: json['name'] as String? ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'price': price,
    };
  }
}
