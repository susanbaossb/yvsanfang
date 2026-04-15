/// 菜单管理页面
/// 
/// 功能：
/// 1. 查看所有菜品列表（支持分类筛选）
/// 2. 新增菜品（名称、描述、分类、价格、图片、评分）
/// 3. 编辑已有菜品
/// 4. 菜品上下架管理
/// 5. 删除菜品（软删除）
/// 6. 支持多规格配置（口味、温度、配料等）
/// 
/// 入口：在"我的"页面点击"菜单管理"快捷入口

import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../models/dish.dart';
import '../../models/recipe_category.dart';
import '../../services/auth_service.dart';
import '../../services/menu_service.dart';
import '../../services/recipe_service.dart';


class MenuManagementPage extends StatefulWidget {
  const MenuManagementPage({super.key});

  @override
  State<MenuManagementPage> createState() => _MenuManagementPageState();
}

class _MenuManagementPageState extends State<MenuManagementPage> {
  final MenuService _menuService = MenuService();
  final RecipeService _recipeService = RecipeService();
  final AuthService _authService = AuthService();
  final ImagePicker _picker = ImagePicker();

  List<Dish> _dishes = [];
  List<RecipeCategory> _categories = [];
  bool _loading = true;

  final Set<String> _updatingIds = <String>{};
  String _filter = '全部';

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    await Future.wait([
      _loadDishes(),
      _loadCategories(),
    ]);
  }


  Future<void> _loadDishes() async {
    setState(() => _loading = true);
    try {
      final dishes = await _menuService.fetchDishes();
      if (!mounted) return;
      setState(() => _dishes = dishes);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('菜单加载失败：$e')),
      );
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _loadCategories() async {
    try {
      final categories = await _recipeService.fetchCategories();
      if (!mounted) return;
      setState(() => _categories = categories);
    } catch (_) {}
  }


  List<Dish> get _filteredDishes {
    switch (_filter) {
      case '上架':
        return _dishes.where((dish) => dish.available).toList();
      case '下架':
        return _dishes.where((dish) => !dish.available).toList();
      default:
        return _dishes;
    }
  }

  Future<void> _showDishEditor({Dish? dish}) async {
    String name = dish?.name ?? '';
    String description = dish?.description ?? '';
    String category = dish?.category ?? '';
    int rating = dish?.rating ?? 5;
    String priceInput = dish != null ? dish.price.toStringAsFixed(2) : '';
    bool available = dish?.available ?? true;
    bool enableMultiSpec = dish?.enableMultiSpec ?? false;

    final List<_SpecGroupDraft> specGroups = (dish?.specGroups ?? [])
        .map(_SpecGroupDraft.fromSpecGroup)
        .toList();
    final categoryOptions = _categories
        .map((item) => item.name)
        .where((name) => name.trim().isNotEmpty)
        .toSet()
        .toList();
    if (category.isNotEmpty && !categoryOptions.contains(category)) {
      categoryOptions.add(category);
    }

    String? currentImageUrl = dish?.imageUrl;

    Uint8List? pickedImageBytes;

    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setBottomState) {
          return Padding(
            padding: EdgeInsets.fromLTRB(
              16,
              16,
              16,
              16 + MediaQuery.of(context).viewInsets.bottom,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    dish == null ? '新增菜品' : '编辑菜品',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: () async {
                      final file = await _picker.pickImage(
                        source: ImageSource.gallery,
                        imageQuality: 80,
                        maxWidth: 1280,
                      );
                      if (file == null) return;
                      final bytes = await file.readAsBytes();
                      setBottomState(() => pickedImageBytes = bytes);
                    },
                    child: Container(
                      height: 140,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade300),
                        color: Colors.grey.shade50,
                      ),
                      child: pickedImageBytes != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.memory(pickedImageBytes!, fit: BoxFit.cover),
                            )
                          : (currentImageUrl != null && currentImageUrl.isNotEmpty)
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.network(currentImageUrl, fit: BoxFit.cover),
                                )

                              : const Center(
                                  child: Text('上传菜品图片'),
                                ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    initialValue: name,
                    decoration: const InputDecoration(
                      labelText: '菜的名称',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) => name = value,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    initialValue: description,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: '菜的描述',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) => description = value,
                  ),
                  const SizedBox(height: 12),
                  if (categoryOptions.isNotEmpty)
                    DropdownButtonFormField<String>(
                      initialValue: category.isNotEmpty ? category : null,

                      decoration: const InputDecoration(
                        labelText: '菜的分类',
                        border: OutlineInputBorder(),
                      ),
                      items: categoryOptions
                          .map(
                            (name) => DropdownMenuItem<String>(
                              value: name,
                              child: Text(name),
                            ),
                          )
                          .toList(),

                      onChanged: (value) {
                        if (value == null) return;
                        setBottomState(() => category = value);
                      },
                    )
                  else
                    TextFormField(
                      initialValue: category,
                      decoration: const InputDecoration(
                        labelText: '菜的分类',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (value) => category = value,
                    ),
                  const SizedBox(height: 8),
                  if (categoryOptions.isEmpty)

                    Text(
                      '暂无分类，请先在首页"我的-分类管理"中添加分类',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Text('推荐星级：'),
                      const SizedBox(width: 6),
                      ...List.generate(5, (index) {
                        final star = index + 1;
                        final active = star <= rating;
                        return IconButton(
                          visualDensity: VisualDensity.compact,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                          onPressed: () => setBottomState(() => rating = star),
                          icon: Icon(
                            active ? Icons.star : Icons.star_border,
                            color: Colors.amber,
                          ),
                        );
                      }),
                      Text('($rating)', style: TextStyle(color: Colors.grey.shade700)),
                    ],
                  ),

                  const SizedBox(height: 12),
                  TextFormField(
                    initialValue: priceInput,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: '设置价格',
                      border: OutlineInputBorder(),
                      prefixText: '¥',
                    ),
                    onChanged: (value) => priceInput = value,
                  ),
                  const SizedBox(height: 8),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('是否开启多规格'),
                    value: enableMultiSpec,
                    onChanged: (value) => setBottomState(() => enableMultiSpec = value),
                  ),
                  if (enableMultiSpec) ...[
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        border: Border.all(color: const Color(0xFF8E7CC3)),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Text('多规格', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                              const Spacer(),
                              OutlinedButton(
                                onPressed: () {
                                  setBottomState(() {
                                    specGroups.add(_SpecGroupDraft.empty());
                                  });
                                },
                                child: const Text('添加规格'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          if (specGroups.isEmpty)
                            Text(
                              '可先添加规格组（例如：口味）',
                              style: TextStyle(color: Colors.grey.shade600),
                            )
                          else
                            ...List.generate(specGroups.length, (groupIndex) {
                              final group = specGroups[groupIndex];
                              return _buildSpecGroupCard(
                                group: group,
                                groupIndex: groupIndex,
                                onChanged: () => setBottomState(() {}),
                                onRemove: () {
                                  setBottomState(() {
                                    specGroups.removeAt(groupIndex);
                                  });
                                },
                              );
                            }),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('上架状态'),
                    value: available,
                    onChanged: (value) => setBottomState(() => available = value),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () => Navigator.pop(sheetContext, true),
                      child: const Text('保存'),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );

    if (saved != true) return;

    final parsedPrice = double.tryParse(priceInput.trim());
    final safeName = name.trim();
    final safeDesc = description.trim();
    final safeCategory = category.trim();

    if (safeName.isEmpty || safeDesc.isEmpty || safeCategory.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请完整填写名称、描述、分类')),
      );
      return;
    }

    if (parsedPrice == null || parsedPrice < 0) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入有效价格')),
      );
      return;
    }

    final normalizedSpecGroups = _normalizeSpecGroups(specGroups);
    if (enableMultiSpec && normalizedSpecGroups.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('已开启多规格，请至少添加一个有效规格组')),
      );
      return;
    }

    try {
      String? imageUrl = currentImageUrl;
      if (pickedImageBytes != null) {
        imageUrl = await _menuService.uploadDishImage(
          bytes: pickedImageBytes!,
          userId: _authService.currentUserId,
        );
      }

      if (dish == null) {
        await _menuService.createDish(
          name: safeName,
          description: safeDesc,
          category: safeCategory,
          price: parsedPrice,
          rating: rating,
          enableMultiSpec: enableMultiSpec,

          specGroups: normalizedSpecGroups,
          imageUrl: imageUrl,
          available: available,
        );
      } else {
        await _menuService.updateDish(
          dishId: dish.id,
          name: safeName,
          description: safeDesc,
          category: safeCategory,
          price: parsedPrice,
          rating: rating,
          enableMultiSpec: enableMultiSpec,
          specGroups: normalizedSpecGroups,
          imageUrl: imageUrl,
          available: available,
        );
      }

      await _loadDishes();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(dish == null ? '菜品新增成功' : '菜品更新成功')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('保存失败：$e')),
      );
    }
  }

  List<DishSpecGroup> _normalizeSpecGroups(List<_SpecGroupDraft> drafts) {
    return drafts
        .map((group) {
          final safeGroupName = group.name.trim();
          final values = group.values
              .map((value) {
                final valueName = value.name.trim();
                final valuePrice = double.tryParse(value.priceText.trim()) ?? 0;
                if (valueName.isEmpty) return null;
                return DishSpecValue(name: valueName, price: valuePrice);
              })
              .whereType<DishSpecValue>()
              .toList();

          if (safeGroupName.isEmpty || values.isEmpty) {
            return null;
          }

          final minSelect = int.tryParse(group.minSelectText.trim()) ?? 0;
          final maxSelectInput = int.tryParse(group.maxSelectText.trim()) ?? values.length;
          final maxSelect = maxSelectInput <= 0 ? values.length : maxSelectInput;

          return DishSpecGroup(
            name: safeGroupName,
            minSelect: minSelect.clamp(0, values.length),
            maxSelect: maxSelect.clamp(1, values.length),
            values: values,
          );
        })
        .whereType<DishSpecGroup>()
        .toList();
  }

  Widget _buildSpecGroupCard({
    required _SpecGroupDraft group,
    required int groupIndex,
    required VoidCallback onChanged,
    required VoidCallback onRemove,
  }) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  initialValue: group.name,
                  decoration: const InputDecoration(
                    labelText: '规格名（如：口味）',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) => group.name = value,
                ),
              ),
              IconButton(
                onPressed: onRemove,
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...List.generate(group.values.length, (valueIndex) {
            final value = group.values[valueIndex];
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      initialValue: value.name,
                      decoration: const InputDecoration(
                        labelText: '规格值（如：三分糖）',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (text) => value.name = text,
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 110,
                    child: TextFormField(
                      initialValue: value.priceText,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: '规格单价',
                        border: OutlineInputBorder(),
                        prefixText: '¥',
                      ),
                      onChanged: (text) => value.priceText = text,
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      group.values.removeAt(valueIndex);
                      onChanged();
                    },
                    icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                  ),
                ],
              ),
            );
          }),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  initialValue: group.minSelectText,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: '最少可选',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) => group.minSelectText = value,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextFormField(
                  initialValue: group.maxSelectText,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: '最多可选',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) => group.maxSelectText = value,
                ),
              ),
            ],
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () {
                group.values.add(_SpecValueDraft.empty());
                onChanged();
              },
              icon: const Icon(Icons.add),
              label: const Text('添加规格值'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleAvailability(Dish dish, bool nextValue) async {
    setState(() => _updatingIds.add(dish.id));
    try {
      await _menuService.updateDishAvailability(
        dishId: dish.id,
        available: nextValue,
      );
      await _loadDishes();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('状态更新失败：$e')),
      );
    } finally {
      if (mounted) {
        setState(() => _updatingIds.remove(dish.id));
      }
    }
  }

  Future<void> _deleteDish(Dish dish) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('删除菜品'),
        content: Text('确认删除"${dish.name}"吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('确认'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _updatingIds.add(dish.id));
    try {
      await _menuService.deleteDish(dishId: dish.id);
      await _loadDishes();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('菜品已删除')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('删除失败：$e')),
      );
    } finally {
      if (mounted) {
        setState(() => _updatingIds.remove(dish.id));
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    final dishes = _filteredDishes;

    return Scaffold(
      appBar: AppBar(
        title: const Text('菜单管理'),
        actions: [
          IconButton(
            onPressed: _loadInitialData,
            icon: const Icon(Icons.refresh),
          ),

        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
                  child: Wrap(
                    spacing: 8,
                    children: [
                      _buildFilterChip('全部'),
                      _buildFilterChip('上架'),
                      _buildFilterChip('下架'),
                    ],
                  ),
                ),
                Expanded(
                  child: dishes.isEmpty
                      ? const Center(child: Text('暂无菜单，点击右下角新增'))
                      : RefreshIndicator(
                          onRefresh: _loadDishes,
                          child: ListView.builder(
                            padding: const EdgeInsets.fromLTRB(12, 8, 12, 96),
                            itemCount: dishes.length,
                            itemBuilder: (context, index) {
                              final dish = dishes[index];
                              final updating = _updatingIds.contains(dish.id);

                              return Card(
                                margin: const EdgeInsets.only(bottom: 10),
                                child: ListTile(
                                  leading: dish.imageUrl != null && dish.imageUrl!.isNotEmpty
                                      ? ClipRRect(
                                          borderRadius: BorderRadius.circular(8),
                                          child: Image.network(
                                            dish.imageUrl!,
                                            width: 52,
                                            height: 52,
                                            fit: BoxFit.cover,
                                          ),
                                        )
                                      : const CircleAvatar(child: Icon(Icons.fastfood_outlined)),
                                  title: Text(dish.name),
                                  subtitle: Text('${dish.category} · ¥${dish.price.toStringAsFixed(2)}'),
                                  isThreeLine: false,
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        visualDensity: VisualDensity.compact,
                                        onPressed: updating ? null : () => _showDishEditor(dish: dish),
                                        icon: const Icon(Icons.edit_outlined, size: 20),
                                      ),
                                      IconButton(
                                        visualDensity: VisualDensity.compact,
                                        onPressed: updating ? null : () => _deleteDish(dish),
                                        icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                                      ),
                                      Switch(
                                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                        value: dish.available,
                                        onChanged: updating
                                            ? null
                                            : (value) => _toggleAvailability(dish, value),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _loading ? null : () => _showDishEditor(),
        icon: const Icon(Icons.add),
        label: const Text('新增菜单'),
      ),
    );
  }

  Widget _buildFilterChip(String value) {
    final isSelected = _filter == value;
    return FilterChip(
      showCheckmark: false,
      label: Text(
        value,
        style: TextStyle(
          color: isSelected ? Colors.white : const Color(0xFF6A4D5D),
          fontWeight: FontWeight.w700,
        ),
      ),
      selectedColor: const Color(0xFFE85D9A),
      backgroundColor: Colors.white,
      side: BorderSide(
        color: isSelected ? const Color(0xFFE85D9A) : const Color(0xFFFFCFE2),
      ),
      selected: isSelected,
      onSelected: (_) => setState(() => _filter = value),
    );
  }
}

class _SpecGroupDraft {
  _SpecGroupDraft({
    required this.name,
    required this.minSelectText,
    required this.maxSelectText,
    required this.values,
  });

  String name;
  String minSelectText;
  String maxSelectText;
  List<_SpecValueDraft> values;

  factory _SpecGroupDraft.empty() {
    return _SpecGroupDraft(
      name: '',
      minSelectText: '0',
      maxSelectText: '1',
      values: [_SpecValueDraft.empty()],
    );
  }

  factory _SpecGroupDraft.fromSpecGroup(DishSpecGroup group) {
    return _SpecGroupDraft(
      name: group.name,
      minSelectText: group.minSelect.toString(),
      maxSelectText: group.maxSelect.toString(),
      values: group.values
          .map((value) => _SpecValueDraft(
                name: value.name,
                priceText: value.price.toStringAsFixed(2),
              ))
          .toList(),
    );
  }
}

class _SpecValueDraft {
  _SpecValueDraft({required this.name, required this.priceText});

  String name;
  String priceText;

  factory _SpecValueDraft.empty() {
    return _SpecValueDraft(name: '', priceText: '0');
  }
}
