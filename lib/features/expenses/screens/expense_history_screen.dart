import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

import '../data/expense_repository.dart';
import '../models/expense_model.dart';
import '../../categories/data/category_repository.dart';
import '../../categories/models/category_model.dart';
import '../widgets/add_expense_sheet.dart';

class ExpenseHistoryScreen extends HookConsumerWidget {
  const ExpenseHistoryScreen({super.key});

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
    final selectedFilterDate = useState<DateTime?>(null);

    Future<void> pickFilterDate() async {
      final picked = await showDatePicker(
        context: context,
        initialDate: selectedFilterDate.value ?? DateTime.now(),
        firstDate: DateTime(2020),
        lastDate: DateTime.now(),
      );
      if (picked != null) selectedFilterDate.value = picked;
    }

    return Scaffold(
      backgroundColor: colorScheme.surfaceContainerLowest,
      body: SafeArea(
        child: expensesAsync.when(
        data: (expenses) {
            final categories = categoriesAsync.value ?? [];

            final filtered = selectedFilterDate.value == null
                ? expenses
                : expenses.where((e) {
                    final d = selectedFilterDate.value!;
                    return e.expenseDate.year == d.year &&
                        e.expenseDate.month == d.month &&
                        e.expenseDate.day == d.day;
                  }).toList();

            final grouped = <String, List<Expense>>{};
            for (final expense in filtered) {
              final key = DateFormat.yMMMM().format(expense.expenseDate);
              grouped.putIfAbsent(key, () => []).add(expense);
            }

           return CustomScrollView(
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
                  sliver: SliverToBoxAdapter(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'History',
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        Row(
                          children: [
                            if (selectedFilterDate.value != null)
                              IconButton(
                                onPressed: () =>
                                    selectedFilterDate.value = null,
                                icon: const Icon(Icons.close_rounded),
                                tooltip: 'Clear filter',
                              ),
                            OutlinedButton.icon(
                              onPressed: pickFilterDate,
                              icon: const Icon(
                                Icons.calendar_today_outlined,
                                size: 16,
                              ),
                              label: Text(
                                selectedFilterDate.value == null
                                    ? 'Filter by date'
                                    : DateFormat.yMMMd().format(
                                        selectedFilterDate.value!,
                                      ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                if (filtered.isEmpty)
                  SliverFillRemaining(
                    child: Center(
                      child: Text(
                        'No expenses found for this date',
                        style: TextStyle(color: colorScheme.onSurfaceVariant),
                      ),
                    ),
                  ),
                for (final entry in grouped.entries) ...[
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
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    sliver: SliverList.separated(
                      itemCount: entry.value.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final expense = entry.value[index];
                        final category = categories
                            .where((c) => c.id == expense.categoryId)
                            .firstOrNull;
                        return _HistoryTile(
                          expense: expense,
                          category: category,
                          onTap: () => _showExpenseSheet(context, expense),
                          onDelete: () async {
                            final shouldDelete = await _confirmDelete(
                              context,
                            );
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
          error: (error, stack) => Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'Something went wrong: $error',
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _HistoryTile extends StatelessWidget {
  const _HistoryTile({
    required this.expense,
    required this.category,
    required this.onTap,
    required this.onDelete,
  });

  final Expense expense;
  final ExpenseCategory? category;
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
    final dateFormatter = DateFormat.MMMd();
    final colorScheme = Theme.of(context).colorScheme;
    final accentColor = _categoryColor(context);

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
                          ? '${expense.note} · ${dateFormatter.format(expense.expenseDate)}'
                          : dateFormatter.format(expense.expenseDate),
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