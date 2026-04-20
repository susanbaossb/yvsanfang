/// 菜品详情页面
///
/// 功能：
/// - 显示菜品图片、名称、描述、分类、推荐星级、价格
/// - 显示多规格内容
/// - 支持修改操作
///
/// 使用场景：从菜品列表点击进入

import 'package:flutter/material.dart';

import '../../models/dish.dart';
import 'menu_management_page.dart';

class DishDetailPage extends StatefulWidget {
  final Dish dish;

  const DishDetailPage({super.key, required this.dish});

  @override
  State<DishDetailPage> createState() => _DishDetailPageState();
}

class _DishDetailPageState extends State<DishDetailPage> {
  @override
  Widget build(BuildContext context) {
    final dish = widget.dish;

    return Scaffold(
      backgroundColor: const Color(0xFFFFF5F8),
      appBar: AppBar(
        title: const Text('菜品详情'),
        backgroundColor: const Color(0xFFE85D9A),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          // 上半部分：图片占位一半
          Expanded(
            flex: 1,
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                ),
                child: dish.imageUrl != null && dish.imageUrl!.isNotEmpty
                    ? Image.network(
                        dish.imageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _buildPlaceholder(),
                      )
                    : _buildPlaceholder(),
              ),
            ),
          ),

          // 下半部分：菜品信息
          Expanded(
            flex: 1,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 菜品名称
                  Text(
                    dish.name,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF333333),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 菜品描述
                  const Text(
                    '菜品描述',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF333333),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    dish.description.isNotEmpty
                        ? dish.description
                        : '暂无描述',
                    style: TextStyle(
                      fontSize: 14,
                      color: dish.description.isNotEmpty
                          ? const Color(0xFF666666)
                          : Colors.grey,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 分类标签
                  Row(
                    children: [
                      const Icon(
                        Icons.category_outlined,
                        size: 18,
                        color: Color(0xFF666666),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE85D9A).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          dish.category,
                          style: const TextStyle(
                            color: Color(0xFFE85D9A),
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // 推荐星级
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[200]!),
                    ),
                    child: Row(
                      children: [
                        const Text(
                          '推荐指数：',
                          style: TextStyle(
                            fontSize: 14,
                            color: Color(0xFF666666),
                          ),
                        ),
                        ...List.generate(5, (index) {
                          return Icon(
                            index < dish.rating
                                ? Icons.star
                                : Icons.star_border,
                            color: const Color(0xFFFFC107),
                            size: 20,
                          );
                        }),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 价格
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[200]!),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          '基础价格',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF333333),
                          ),
                        ),
                        Text(
                          '¥${dish.price.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFE85D9A),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // 多规格内容
                  if (dish.enableMultiSpec && dish.specGroups.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[200]!),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(
                                Icons.list_alt,
                                color: Color(0xFFE85D9A),
                                size: 20,
                              ),
                              SizedBox(width: 8),
                              Text(
                                '规格选项',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF333333),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          ...dish.specGroups.map((group) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        group.name,
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFF333333),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        group.minSelect == group.maxSelect
                                            ? '（必选）'
                                            : '（可选 ${group.minSelect}-${group.maxSelect} 项）',
                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: Color(0xFF999999),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: group.values.map((spec) {
                                      return Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFFFF5F8),
                                          borderRadius:
                                              BorderRadius.circular(16),
                                          border: Border.all(
                                            color: const Color(0xFFFFCFE2),
                                          ),
                                        ),
                                        child: Text(
                                          spec.price > 0
                                              ? '${spec.name} (+¥${spec.price.toStringAsFixed(2)})'
                                              : spec.name,
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: Color(0xFF666666),
                                          ),
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                ],
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 24),

                  // 修改按钮
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (_) => MenuManagementPage(editDish: dish),
                          ),
                        );
                      },
                      icon: const Icon(Icons.edit),
                      label: const Text('修改菜品'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFE85D9A),
                        side: const BorderSide(
                          color: Color(0xFFE85D9A),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      color: Colors.grey[200],
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.fastfood_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 8),
            Text(
              '暂无图片',
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
