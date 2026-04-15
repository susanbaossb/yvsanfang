// ignore_for_file: invalid_use_of_protected_member

/// 主页弹窗扩展
/// 
/// 功能：
/// - _showSpecSelector：规格选择底部弹窗（多规格菜品）
/// - _showCategoryManager：分类管理弹窗（新增/删除分类）

part of 'home_page.dart';


extension _HomePageDialogs on _HomePageState {
  Future<List<CartItemSpec>?> _showSpecSelector(Dish dish) {
    final selected = <int, Set<int>>{};
    // 默认选中必选规格的第一个
    for (var i = 0; i < dish.specGroups.length; i++) {
      final group = dish.specGroups[i];
      if (group.minSelect > 0) {
        selected[i] = {0};
      }
    }
    final invalidGroups = <int>{};

    return showModalBottomSheet<List<CartItemSpec>>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setBottomState) {
            return SafeArea(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  16,
                  16,
                  16,
                  16 + MediaQuery.of(context).viewInsets.bottom,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '选择规格 · ${dish.name}',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 12),
                    Flexible(
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: dish.specGroups.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (_, groupIndex) {
                          final group = dish.specGroups[groupIndex];
                          final selectedIndexes = selected[groupIndex] ?? <int>{};
                          final isSingleSelect = group.maxSelect <= 1;
                          final isRequired = group.minSelect > 0;
                          final isInvalid = isRequired && selectedIndexes.isEmpty;

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${group.name}${isRequired ? '（必选）' : ''}',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: isInvalid ? Colors.red : null,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                decoration: isInvalid
                                    ? BoxDecoration(
                                        border: Border.all(color: Colors.red, width: 2),
                                        borderRadius: BorderRadius.circular(8),
                                      )
                                    : null,
                                padding: isInvalid ? const EdgeInsets.all(4) : null,
                                child: Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: List.generate(group.values.length, (valueIndex) {
                                    final value = group.values[valueIndex];
                                    final chosen = selectedIndexes.contains(valueIndex);
                                    return FilterChip(
                                      selected: chosen,
                                      showCheckmark: false,
                                      selectedColor: const Color(0xFFE85D9A),
                                      backgroundColor: const Color(0xFFFFF3F9),
                                      side: BorderSide(
                                        color: chosen
                                            ? const Color(0xFFE85D9A)
                                            : const Color(0xFFFFCFE2),
                                      ),
                                      label: Text(
                                        '${value.name}${value.price > 0 ? ' +积分${value.price.toStringAsFixed(0)}' : ''}',
                                        style: TextStyle(
                                          color: chosen ? Colors.white : const Color(0xFF7A2F58),
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      onSelected: (checked) {

                                        setBottomState(() {
                                          invalidGroups.remove(groupIndex);
                                          final current = selected[groupIndex] ?? <int>{};
                                          if (isSingleSelect) {
                                            selected[groupIndex] = checked ? {valueIndex} : <int>{};
                                            return;
                                          }
                                          if (checked) {
                                            if (group.maxSelect <= 0 ||
                                                current.length < group.maxSelect) {
                                              current.add(valueIndex);
                                            }
                                          } else {
                                            current.remove(valueIndex);
                                          }
                                          selected[groupIndex] = current;
                                        });
                                      },
                                    );
                                  }),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: () {
                          // 检查必选规格
                          bool hasInvalid = false;
                          for (var i = 0; i < dish.specGroups.length; i++) {
                            final group = dish.specGroups[i];
                            final count = (selected[i] ?? const <int>{}).length;
                            if (group.minSelect > 0 && count < group.minSelect) {
                              hasInvalid = true;
                              invalidGroups.add(i);
                            }
                          }
                          if (hasInvalid) {
                            setBottomState(() {});
                            ScaffoldMessenger.of(sheetContext).showSnackBar(
                              const SnackBar(content: Text('请完成必选规格的选择')),
                            );
                            return;
                          }

                          final result = <CartItemSpec>[];
                          for (var i = 0; i < dish.specGroups.length; i++) {
                            final group = dish.specGroups[i];
                            final indexes = (selected[i] ?? const <int>{}).toList()..sort();
                            for (final idx in indexes) {
                              final value = group.values[idx];
                              result.add(
                                CartItemSpec(
                                  groupName: group.name,
                                  valueName: value.name,
                                  priceAdjustment: value.price,
                                ),
                              );
                            }
                          }
                          Navigator.of(sheetContext).pop(result);
                        },
                        child: const Text('加入购物车'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _showCategoryManager() async {
    String draftName = '';
    int inputVersion = 0;

    await showDialog<void>(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setLocalState) {
          return AlertDialog(
            title: const Text('分类管理'),
            content: SizedBox(
              width: 360,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    key: ValueKey(inputVersion),
                    onChanged: (value) => draftName = value,
                    decoration: InputDecoration(
                      hintText: '新增分类（如：汤羹）',
                      suffixIcon: IconButton(
                        onPressed: () async {
                          final name = draftName.trim();
                          if (name.isEmpty) return;

                          try {
                            await _recipeService.createCategory(name);
                            await _loadRecipeCategories();
                            setLocalState(() {
                              draftName = '';
                              inputVersion++;
                            });
                          } catch (e) {
                            if (!mounted) return;
                            ScaffoldMessenger.of(this.context).showSnackBar(
                              SnackBar(content: Text('新增分类失败：$e')),
                            );
                          }
                        },
                        icon: const Icon(Icons.add),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Flexible(
                    child: ListView(
                      shrinkWrap: true,
                      children: _recipeCategories
                          .map(
                            (category) => ListTile(
                              contentPadding: EdgeInsets.zero,
                              title: Text(category.name),
                              trailing: IconButton(
                                onPressed: () async {
                                  try {
                                    await _recipeService.deleteCategory(category.id);
                                    await _loadRecipeCategories();
                                    if (_selectedCategory == category.name) {
                                      setState(() => _selectedCategory = '全部');
                                    }
                                    setLocalState(() {});
                                  } catch (e) {
                                    if (!mounted) return;
                                    ScaffoldMessenger.of(this.context).showSnackBar(
                                      SnackBar(content: Text('删除分类失败：$e')),
                                    );
                                  }
                                },
                                icon: const Icon(Icons.delete_outline),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('关闭'),
              ),
            ],
          );
        },
      ),
    );
  }
}
