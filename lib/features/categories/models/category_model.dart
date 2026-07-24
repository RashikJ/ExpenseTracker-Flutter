class ExpenseCategory {
  final String id;
  final String userId;
  final String name;
  final String? icon;
  final String? color;

  const ExpenseCategory({
    required this.id,
    required this.userId,
    required this.name,
    this.icon,
    this.color,
  });

  factory ExpenseCategory.fromMap(Map<String, dynamic> map) {
    return ExpenseCategory(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      name: map['name'] as String,
      icon: map['icon'] as String?,
      color: map['color'] as String?,
    );
  }
}