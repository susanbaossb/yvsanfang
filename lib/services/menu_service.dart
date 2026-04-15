/// 菜单/菜品服务
/// 
/// 功能：
/// 1. fetchAvailableDishes: 获取可用的菜品列表
/// 2. fetchDishes: 获取菜品列表（可按 available 筛选）
/// 3. uploadDishImage: 上传菜品图片到 Storage
/// 4. createDish: 创建新菜品
/// 5. updateDish: 更新菜品信息
/// 6. updateDishAvailability: 更新菜品上下架状态
/// 7. deleteDish: 删除菜品（软删除，标记 deleted=true）

import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/supabase_client.dart';
import '../models/dish.dart';

class MenuService {
  Future<List<Dish>> fetchAvailableDishes() {
    return fetchDishes(available: true);
  }

  Future<List<Dish>> fetchDishes({bool? available}) async {
    var query = AppSupabase.client.from('dishes').select().eq('deleted', false);

    if (available != null) {
      query = query.eq('available', available);
    }

    final rows = await query.order('category').order('name');
    return rows.map<Dish>((raw) => Dish.fromJson(raw)).toList();
  }

  Future<String> uploadDishImage({
    required Uint8List bytes,
    required String userId,
  }) async {
    final path = '$userId/${DateTime.now().millisecondsSinceEpoch}.jpg';
    await AppSupabase.client.storage.from('dish-images').uploadBinary(
          path,
          bytes,
          fileOptions: const FileOptions(
            upsert: true,
            contentType: 'image/jpeg',
          ),
        );
    return AppSupabase.client.storage.from('dish-images').getPublicUrl(path);
  }

  Future<void> createDish({
    required String name,
    required String description,
    required String category,
    required double price,
    required int rating,
    required bool enableMultiSpec,
    required List<DishSpecGroup> specGroups,
    String? imageUrl,
    bool available = true,
  }) async {
    await AppSupabase.client.from('dishes').insert({
      'name': name,
      'description': description,
      'category': category,
      'price': price,
      'rating': rating,
      'enable_multi_spec': enableMultiSpec,
      'specs_json': specGroups.map((group) => group.toJson()).toList(),
      'image_url': imageUrl,
      'available': available,
    });
  }

  Future<void> updateDish({
    required String dishId,
    required String name,
    required String description,
    required String category,
    required double price,
    required int rating,
    required bool enableMultiSpec,
    required List<DishSpecGroup> specGroups,
    required bool available,
    String? imageUrl,
  }) async {
    await AppSupabase.client
        .from('dishes')
        .update({
          'name': name,
          'description': description,
          'category': category,
          'price': price,
          'rating': rating,
          'enable_multi_spec': enableMultiSpec,
          'specs_json': specGroups.map((group) => group.toJson()).toList(),
          'image_url': imageUrl,
          'available': available,
        })
        .eq('id', dishId);
  }

  Future<void> updateDishAvailability({
    required String dishId,
    required bool available,
  }) async {
    await AppSupabase.client
        .from('dishes')
        .update({'available': available}).eq('id', dishId);
  }

  Future<void> deleteDish({
    required String dishId,
  }) async {
    await AppSupabase.client
        .from('dishes')
        .update({'deleted': true})
        .eq('id', dishId);
  }
}
