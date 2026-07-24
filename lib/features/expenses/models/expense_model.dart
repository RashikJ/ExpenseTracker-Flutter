class Expense {
  final String id;
  final String userId;
  final String? categoryId;
  final double amount;
  final String? note;
  final DateTime expenseDate;
  final DateTime createdAt;

  const Expense({
    required this.id,
    required this.userId,
    this.categoryId,
    required this.amount,
    this.note,
    required this.expenseDate,
    required this.createdAt,
  });

  factory Expense.fromMap(Map<String, dynamic> map) {
    return Expense(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      categoryId: map['category_id'] as String?,
      amount: (map['amount'] as num).toDouble(),
      note: map['note'] as String?,
      expenseDate: DateTime.parse(map['expense_date'] as String),
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  Map<String, dynamic> toInsertMap() {
    return {
      'category_id': categoryId,
      'amount': amount,
      'note': note,
      'expense_date': expenseDate.toIso8601String().split('T').first,
    };
  }
}