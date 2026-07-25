import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';

import '../data/expense_repository.dart';
import '../models/expense_model.dart';
import '../../categories/data/category_repository.dart';
import '../../categories/models/category_model.dart';
import '../widgets/add_expense_sheet.dart';

class ExpensePeriodDetailScreen extends ConsumerWidget {
  const ExpensePeriodDetailScreen({
    super.key,
    required this.period,
    required this.date,
  });

  final String period;
  final DateTime date;

  String get _periodLabel {
    switch (period) {
      case 'Day':
        return DateFormat.yMMMd().format(date);
      case 'Year':
        return DateFormat.y().format(date);
      case 'Month':
      default:
        return DateFormat.yMMMM().format(date);
    }
  }

  Future<void> _showExpenseSheet(BuildContext context, Expense? expense) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddExpenseSheet(expense: expense),
    );
  }

  Future<bool> _confirmDelete(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete expense?'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expensesAsync = ref.watch(expensesStreamProvider);
    final categoriesAsync = ref.watch(categoriesStreamProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final formatter = NumberFormat.currency(symbol: '₹', locale: 'en_IN');

    return Scaffold(
      backgroundColor: colorScheme.surfaceContainerLowest,
      appBar: AppBar(title: Text(_periodLabel)),
      body: expensesAsync.when(
        data: (expenses) {
          final categories = categoriesAsync.value ?? [];

          final filtered = expenses.where((e) {
            switch (period) {
              case 'Day':
                return e.expenseDate.year == date.year &&
                    e.expenseDate.month == date.month &&
                    e.expenseDate.day == date.day;
              case 'Year':
                return e.expenseDate.year == date.year;
              case 'Month':
              default:
                return e.expenseDate.year == date.year &&
                    e.expenseDate.month == date.month;
            }
          }).toList();

          if (filtered.isEmpty) {
            return Center(
              child: Text(
                'No expenses in $_periodLabel',
                style: TextStyle(color: colorScheme.onSurfaceVariant),
              ),
            );
          }

          final total = filtered.fold<double>(0, (sum, e) => sum + e.amount);
          final groupByMonth = period == 'Year';
          final grouped = <String, List<Expense>>{};
          for (final expense in filtered) {
            final key = groupByMonth
                ? DateFormat.MMMM().format(expense.expenseDate)
                : 'all';
            grouped.putIfAbsent(key, () => []).add(expense);
          }

          return CustomScrollView(
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                sliver: SliverToBoxAdapter(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${filtered.length} ${filtered.length == 1 ? 'expense' : 'expenses'}',
                        style: TextStyle(
                          color: colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        formatter.format(total),
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              for (final entry in grouped.entries) ...[
                if (groupByMonth)
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                    sliver: SliverToBoxAdapter(
                      child: Text(
                        entry.key,
                        style: Theme.of(context).textTheme.titleSmall
                            ?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ),
                  ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                  sliver: SliverList.separated(
                    itemCount: entry.value.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final expense = entry.value[index];
                      final category = categories
                          .where((c) => c.id == expense.categoryId)
                          .firstOrNull;
                      return _DetailTile(
                        expense: expense,
                        category: category,
                        period: period,
                        onTap: () => _showExpenseSheet(context, expense),
                        onDelete: () async {
                          final shouldDelete = await _confirmDelete(context);
                          if (!shouldDelete) return;
                          await ref
                              .read(expenseRepositoryProvider)
                              .deleteExpense(expense.id);
                        },
                      );
                    },
                  ),
                ),
              ],
              const SliverPadding(padding: EdgeInsets.only(bottom: 24)),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) =>
            Center(child: Text('Something went wrong: $error')),
      ),
    );
  }
}

class _DetailTile extends StatelessWidget {
  const _DetailTile({
    required this.expense,
    required this.category,
    required this.period,
    required this.onTap,
    required this.onDelete,
  });

  final Expense expense;
  final ExpenseCategory? category;
  final String period;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  Color _categoryColor(BuildContext context) {
    if (category?.color != null) {
      try {
        return Color(int.parse(category!.color!.replaceFirst('#', '0xFF')));
      } catch (_) {}
    }
    return Theme.of(context).colorScheme.primary;
  }

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat.currency(symbol: '₹', locale: 'en_IN');
    final colorScheme = Theme.of(context).colorScheme;
    final accentColor = _categoryColor(context);

    final subtitle = period == 'Day'
        ? DateFormat.jm().format(expense.createdAt)
        : DateFormat.MMMd().format(expense.expenseDate);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        onLongPress: onDelete,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: colorScheme.outlineVariant.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  Icons.receipt_long_rounded,
                  color: accentColor,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      category?.name ?? 'Uncategorized',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      expense.note?.isNotEmpty == true
                          ? '${expense.note} · $subtitle'
                          : subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: colorScheme.onSurfaceVariant,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                formatter.format(expense.amount),
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}