import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../main.dart';
import '../models/expense_model.dart';

final expenseRepositoryProvider = Provider((ref) => ExpenseRepository());

final expensesStreamProvider = StreamProvider<List<Expense>>((ref) {
  final userId = supabase.auth.currentUser?.id;
  if (userId == null) return Stream.value([]);

  return supabase
      .from('expenses')
      .stream(primaryKey: ['id'])
      .eq('user_id', userId)
      .order('expense_date', ascending: false)
      .map((rows) => rows.map(Expense.fromMap).toList());
});

class ExpenseRepository {
  Future<void> addExpense({
    required double amount,
    String? categoryId,
    String? note,
    required DateTime expenseDate,
  }) async {
    final userId = supabase.auth.currentUser!.id;
    await supabase.from('expenses').insert({
      'user_id': userId,
      'category_id': categoryId,
      'amount': amount,
      'note': note,
      'expense_date': expenseDate.toIso8601String().split('T').first,
    });
  }

  Future<void> deleteExpense(String id) async {
    await supabase.from('expenses').delete().eq('id', id);
  }
}

Future<void> updateExpense({
  required String id,
  required double amount,
  String? categoryId,
  String? note,
  required DateTime expenseDate,
}) async {
  await supabase.from('expenses').update({
    'category_id': categoryId,
    'amount': amount,
    'note': note,
    'expense_date': expenseDate.toIso8601String().split('T').first,
  }).eq('id', id);
}
