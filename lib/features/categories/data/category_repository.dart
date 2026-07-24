import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../main.dart';
import '../models/category_model.dart';

final categoryRepositoryProvider = Provider((ref) => CategoryRepository());

final categoriesStreamProvider = StreamProvider<List<ExpenseCategory>>((ref) {
  final userId = supabase.auth.currentUser?.id;
  if (userId == null) return Stream.value([]);

  return supabase
      .from('categories')
      .stream(primaryKey: ['id'])
      .eq('user_id', userId)
      .order('created_at')
      .map((rows) => rows.map(ExpenseCategory.fromMap).toList());
});

class CategoryRepository {
  Future<void> createCategory({
    required String name,
    String? icon,
    String? color,
  }) async {
    final userId = supabase.auth.currentUser!.id;
    await supabase.from('categories').insert({
      'user_id': userId,
      'name': name,
      'icon': icon,
      'color': color,
    });
  }

  Future<void> deleteCategory(String id) async {
    await supabase.from('categories').delete().eq('id', id);
  }
}