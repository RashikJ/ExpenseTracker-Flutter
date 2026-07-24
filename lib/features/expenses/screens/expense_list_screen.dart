import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';

import '../data/expense_repository.dart';
import '../models/expense_model.dart';
import '../../categories/data/category_repository.dart';
import '../../categories/models/category_model.dart';
import '../../auth/providers/auth_provider.dart';
import '../widgets/add_expense_sheet.dart';

class ExpenseListScreen extends HookConsumerWidget {
  const ExpenseListScreen({super.key});

  Future<void> _showExpenseSheet(BuildContext context, Expense? expense) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddExpenseSheet(expense: expense),
    );
  }

  Future<void> _showExpenseActions(
    BuildContext context,
    Expense expense,
    VoidCallback onEdit,
    VoidCallback onDelete,
  ) async {
    await showModalBottomSheet(
      context: context,
      showDragHandle: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Expense actions',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: () {
                    Navigator.of(context).pop();
                    onEdit();
                  },
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('Edit expense'),
                ),
                const SizedBox(height: 10),
                FilledButton.tonalIcon(
                  onPressed: () {
                    Navigator.of(context).pop();
                    onDelete();
                  },
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Delete expense'),
                ),
                const SizedBox(height: 4),
                Text(
                  expense.note?.isNotEmpty == true
                      ? expense.note!
                      : 'Long-press actions are available for this expense.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        );
      },
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

    return Scaffold(
      backgroundColor: colorScheme.surfaceContainerLowest,
      body: SafeArea(
        child: expensesAsync.when(
          data: (expenses) {
            final categories = categoriesAsync.value ?? [];
            final total = expenses.fold<double>(0, (sum, e) => sum + e.amount);

            return CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: _Header(
                    total: total,
                    onSignOut: () async {
                      await ref.read(authRepositoryProvider).signOut();
                    },
                  ),
                ),
                if (expenses.isEmpty)
                  const SliverFillRemaining(child: _EmptyState())
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
                    sliver: SliverList.separated(
                      itemCount: expenses.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final expense = expenses[index];
                        final category = categories
                            .where((c) => c.id == expense.categoryId)
                            .firstOrNull;
                        return _ExpenseTile(
                          expense: expense,
                          category: category,
                          onLongPress: () => _showExpenseActions(
                            context,
                            expense,
                            () => _showExpenseSheet(context, expense),
                            () async {
                              final shouldDelete = await _confirmDelete(
                                context,
                              );
                              if (!shouldDelete) return;
                              await ref
                                  .read(expenseRepositoryProvider)
                                  .deleteExpense(expense.id);
                            },
                          ),
                        );
                      },
                    ),
                  ),
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showExpenseSheet(context, null),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Expense'),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.total, required this.onSignOut});

  final double total;
  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final formatter = NumberFormat.currency(symbol: '₹', locale: 'en_IN');

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Expenses',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              IconButton.filledTonal(
                onPressed: onSignOut,
                icon: const Icon(Icons.logout_rounded, size: 20),
                tooltip: 'Sign out',
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  colorScheme.primary,
                  colorScheme.primary.withValues(alpha: 0.82),
                ],
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: colorScheme.primary.withValues(alpha: 0.28),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const SizedBox(width: 6),
                    Text(
                      'TOTAL SPENT',
                      style: TextStyle(
                        color: colorScheme.onPrimary.withValues(alpha: 0.85),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  formatter.format(total),
                  style: TextStyle(
                    color: colorScheme.onPrimary,
                    fontSize: 34,
                    fontWeight: FontWeight.w700,
                    height: 1.1,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Recent',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _ExpenseTile extends StatelessWidget {
  const _ExpenseTile({
    required this.expense,
    required this.category,
    required this.onLongPress,
  });

  final Expense expense;
  final ExpenseCategory? category;
  final VoidCallback onLongPress;

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
        onLongPress: onLongPress,
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

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer.withValues(alpha: 0.5),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.receipt_long_outlined,
                size: 40,
                color: colorScheme.primary,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'No expenses yet',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            Text(
              'Tap the + button below to add your first expense',
              textAlign: TextAlign.center,
              style: TextStyle(color: colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}
