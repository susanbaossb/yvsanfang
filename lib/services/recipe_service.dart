/// 菜谱分类服务
/// 
/// 功能：
/// 1. fetchCategories: 获取所有菜谱分类
/// 2. createCategory: 创建新分类
/// 3. deleteCategory: 删除分类
/// 4. fetchRecipes: 获取菜谱列表
/// 5. createRecipe: 创建菜谱
/// 
/// 注意：分类用于厨房 Tab 的菜品筛选

import '../core/supabase_client.dart';
import '../models/recipe.dart';
import '../models/recipe_category.dart';

class RecipeService {
  Future<List<RecipeCategory>> fetchCategories() async {
    final rows = await AppSupabase.client
        .from('recipe_categories')
        .select('id,name,sort_order,created_at')
        .order('sort_order')
        .order('created_at', ascending: false);

    return rows
        .map<RecipeCategory>((raw) => RecipeCategory.fromJson(raw))
        .toList();
  }

  Future<RecipeCategory> createCategory(String name) async {
    final row = await AppSupabase.client
        .from('recipe_categories')
        .insert({'name': name})
        .select('id,name,sort_order,created_at')
        .single();

    return RecipeCategory.fromJson(row);
  }

  Future<void> deleteCategory(String categoryId) async {
    await AppSupabase.client
        .from('recipe_categories')
        .delete()
        .eq('id', categoryId);
  }

  Future<List<Recipe>> fetchRecipes() async {
    final rows = await AppSupabase.client
        .from('recipes')
        .select('id,name,description,created_at,recipe_categories(name)')
        .order('created_at', ascending: false);

    return rows.map<Recipe>((raw) => Recipe.fromJson(raw)).toList();
  }

  Future<void> createRecipe({
    required String name,
    required String description,
    required String userId,
    String? categoryId,
  }) async {
    await AppSupabase.client.from('recipes').insert({
      'name': name,
      'description': description,
      'category_id': categoryId,
      'created_by': userId,
    });
  }
}
