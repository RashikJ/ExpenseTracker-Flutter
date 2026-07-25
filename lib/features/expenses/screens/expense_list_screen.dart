import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:fl_chart/fl_chart.dart';
import '../data/expense_repository.dart';
import '../models/expense_model.dart';
import '../../categories/data/category_repository.dart';
import '../../categories/models/category_model.dart';
import '../../auth/providers/auth_provider.dart';
import '../widgets/add_expense_sheet.dart';
import 'expense_period_detail_screen.dart';

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

  String _periodLabel(String period, DateTime selectedDate) {
    switch (period) {
      case 'Day':
        return DateFormat.yMMMd().format(selectedDate);
      case 'Year':
        return DateFormat.y().format(selectedDate);
      case 'Month':
      default:
        return DateFormat.yMMMM().format(selectedDate);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expensesAsync = ref.watch(expensesStreamProvider);
    final categoriesAsync = ref.watch(categoriesStreamProvider);
    final colorScheme = Theme.of(context).colorScheme;

    final selectedPeriod = useState('Month');
    final selectedDate = useState(DateTime.now());

    Future<void> pickDay() async {
      final picked = await showDatePicker(
        context: context,
        initialDate: selectedDate.value,
        firstDate: DateTime(2020),
        lastDate: DateTime.now(),
      );
      if (picked != null) selectedDate.value = picked;
    }

    Future<void> pickMonthYear() async {
      var month = selectedDate.value.month;
      var year = selectedDate.value.year;

      final picked = await showDialog<DateTime>(
        context: context,
        builder: (context) {
          return StatefulBuilder(
            builder: (context, setState) {
              return AlertDialog(
                title: const Text('Select month & year'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<int>(
                      initialValue: month,
                      decoration: const InputDecoration(labelText: 'Month'),
                      items: List.generate(12, (i) => i + 1)
                          .map(
                            (m) => DropdownMenuItem(
                              value: m,
                              child: Text(
                                DateFormat.MMMM().format(DateTime(0, m)),
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (value) => setState(() => month = value!),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<int>(
                      initialValue: year,
                      decoration: const InputDecoration(labelText: 'Year'),
                      items:
                          List.generate(
                                DateTime.now().year - 2020 + 1,
                                (i) => 2020 + i,
                              )
                              .map(
                                (y) => DropdownMenuItem(
                                  value: y,
                                  child: Text('$y'),
                                ),
                              )
                              .toList(),
                      onChanged: (value) => setState(() => year = value!),
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                  FilledButton(
                    onPressed: () =>
                        Navigator.of(context).pop(DateTime(year, month)),
                    child: const Text('Apply'),
                  ),
                ],
              );
            },
          );
        },
      );
      if (picked != null) selectedDate.value = picked;
    }

    Future<void> pickYear() async {
      var year = selectedDate.value.year;

      final picked = await showDialog<int>(
        context: context,
        builder: (context) {
          return StatefulBuilder(
            builder: (context, setState) {
              return AlertDialog(
                title: const Text('Select year'),
                content: DropdownButtonFormField<int>(
                  initialValue: year,
                  decoration: const InputDecoration(labelText: 'Year'),
                  items:
                      List.generate(
                            DateTime.now().year - 2020 + 1,
                            (i) => 2020 + i,
                          )
                          .map(
                            (y) =>
                                DropdownMenuItem(value: y, child: Text('$y')),
                          )
                          .toList(),
                  onChanged: (value) => setState(() => year = value!),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                  FilledButton(
                    onPressed: () => Navigator.of(context).pop(year),
                    child: const Text('Apply'),
                  ),
                ],
              );
            },
          );
        },
      );
      if (picked != null) selectedDate.value = DateTime(picked);
    }

    Future<void> pickDate() async {
      switch (selectedPeriod.value) {
        case 'Day':
          await pickDay();
          break;
        case 'Month':
          await pickMonthYear();
          break;
        case 'Year':
          await pickYear();
          break;
      }
    }

    return Container(
      color: colorScheme.surfaceContainerLowest,
      child: SafeArea(
        child: expensesAsync.when(
          data: (expenses) {
            final categories = categoriesAsync.value ?? [];

            final filteredExpenses = expenses.where((e) {
              final d = selectedDate.value;
              switch (selectedPeriod.value) {
                case 'Day':
                  return e.expenseDate.year == d.year &&
                      e.expenseDate.month == d.month &&
                      e.expenseDate.day == d.day;
                case 'Year':
                  return e.expenseDate.year == d.year;
                case 'Month':
                default:
                  return e.expenseDate.year == d.year &&
                      e.expenseDate.month == d.month;
              }
            }).toList();

            final total = filteredExpenses.fold<double>(
              0,
              (sum, e) => sum + e.amount,
            );
            final recentExpenses = filteredExpenses.take(3).toList();

            return CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: _Header(
                    total: total,
                    count: filteredExpenses.length,
                    period: selectedPeriod.value,
                    selectedDate: selectedDate.value,
                    onPeriodChanged: (value) => selectedPeriod.value = value,
                    onPickDate: pickDate,
                    onSignOut: () async {
                      await ref.read(authRepositoryProvider).signOut();
                    },
                  ),
                ),
                if (filteredExpenses.isNotEmpty)
                  SliverToBoxAdapter(
                    child: _CategoryBreakdown(
                      expenses: filteredExpenses,
                      categories: categories,
                    ),
                  ),
                if (recentExpenses.isEmpty)
                  SliverFillRemaining(
                    child: _EmptyState(
                      isFirstTime: expenses.isEmpty,
                      periodLabel: _periodLabel(
                        selectedPeriod.value,
                        selectedDate.value,
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
                    sliver: SliverList.separated(
                      itemCount: recentExpenses.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final expense = recentExpenses[index];
                        final category = categories
                            .where((c) => c.id == expense.categoryId)
                            .firstOrNull;
                        return _ExpenseTile(
                          expense: expense,
                          category: category,
                          period: selectedPeriod.value,
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
                if (filteredExpenses.isNotEmpty)
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                    sliver: SliverToBoxAdapter(
                      child: Center(
                        child: TextButton.icon(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => ExpensePeriodDetailScreen(
                                  period: selectedPeriod.value,
                                  date: selectedDate.value,
                                ),
                              ),
                            );
                          },
                          icon: const Icon(Icons.list_alt_rounded, size: 18),
                          label: const Text('View all transactions'),
                        ),
                      ),
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
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.total,
    required this.count,
    required this.period,
    required this.selectedDate,
    required this.onPeriodChanged,
    required this.onPickDate,
    required this.onSignOut,
  });

  final double total;
  final int count;
  final String period;
  final DateTime selectedDate;
  final ValueChanged<String> onPeriodChanged;
  final VoidCallback onPickDate;
  final VoidCallback onSignOut;

  String get _periodLabel {
    switch (period) {
      case 'Day':
        return DateFormat.yMMMd().format(selectedDate);
      case 'Year':
        return DateFormat.y().format(selectedDate);
      case 'Month':
      default:
        return DateFormat.yMMMM().format(selectedDate);
    }
  }

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
          const SizedBox(height: 16),
          Row(
            children: [
              for (final option in const ['Day', 'Month', 'Year'])
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(option),
                    selected: period == option,
                    onSelected: (_) => onPeriodChanged(option),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
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
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'TOTAL SPENT',
                      style: TextStyle(
                        color: colorScheme.onPrimary.withValues(alpha: 0.85),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.8,
                      ),
                    ),
                    InkWell(
                      onTap: onPickDate,
                      borderRadius: BorderRadius.circular(8),
                      child: Row(
                        children: [
                          Icon(
                            Icons.calendar_today_rounded,
                            size: 14,
                            color: colorScheme.onPrimary.withValues(
                              alpha: 0.85,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _periodLabel,
                            style: TextStyle(
                              color: colorScheme.onPrimary.withValues(
                                alpha: 0.85,
                              ),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
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
                const SizedBox(height: 4),
                Text(
                  count == 1 ? '1 expense' : '$count expenses',
                  style: TextStyle(
                    color: colorScheme.onPrimary.withValues(alpha: 0.85),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
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

class _CategoryBreakdown extends StatelessWidget {
  const _CategoryBreakdown({required this.expenses, required this.categories});

  final List<Expense> expenses;
  final List<ExpenseCategory> categories;

  static const _palette = [
    Color(0xFF0891B2),
    Color(0xFFF97316),
    Color(0xFF7C3AED),
    Color(0xFF059669),
    Color(0xFFDB2777),
    Color(0xFFB45309),
    Color(0xFF64748B),
  ];

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final formatter = NumberFormat.currency(symbol: '₹', locale: 'en_IN');

    final totals = <String, double>{};
    for (final e in expenses) {
      final key = e.categoryId ?? 'uncategorized';
      totals[key] = (totals[key] ?? 0) + e.amount;
    }

    final entries = totals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    if (entries.length < 2) {
      // Not worth showing a breakdown for a single category
      return const SizedBox.shrink();
    }

    final grandTotal = entries.fold<double>(0, (s, e) => s + e.value);

    String nameFor(String categoryId) {
      if (categoryId == 'uncategorized') return 'Uncategorized';
      return categories.where((c) => c.id == categoryId).firstOrNull?.name ??
          'Uncategorized';
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 4),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: colorScheme.outlineVariant.withValues(alpha: 0.3),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'By Category',
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(
                  width: 96,
                  height: 96,
                  child: PieChart(
                    PieChartData(
                      sectionsSpace: 2,
                      centerSpaceRadius: 24,
                      sections: [
                        for (var i = 0; i < entries.length; i++)
                          PieChartSectionData(
                            value: entries[i].value,
                            color: _palette[i % _palette.length],
                            radius: 20,
                            showTitle: false,
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (var i = 0; i < entries.length; i++)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 3),
                          child: Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: _palette[i % _palette.length],
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  nameFor(entries[i].key),
                                  style: const TextStyle(fontSize: 13),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                formatter.format(entries[i].value),
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            if (entries.length > 4) ...[
              const SizedBox(height: 8),
              Text(
                'Total: ${formatter.format(grandTotal)}',
                style: TextStyle(
                  fontSize: 12,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ExpenseTile extends StatelessWidget {
  const _ExpenseTile({
    required this.expense,
    required this.category,
    required this.period,
    required this.onLongPress,
  });

  final Expense expense;
  final ExpenseCategory? category;
  final String period;
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
    final colorScheme = Theme.of(context).colorScheme;
    final accentColor = _categoryColor(context);

    final subtitleTime = period == 'Day'
        ? DateFormat.jm().format(expense.createdAt)
        : DateFormat.MMMd().format(expense.expenseDate);

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
                          ? '${expense.note} · $subtitleTime'
                          : subtitleTime,
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
  const _EmptyState({required this.isFirstTime, required this.periodLabel});

  final bool isFirstTime;
  final String periodLabel;

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
              isFirstTime ? 'No expenses yet' : 'No expenses in $periodLabel',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              isFirstTime
                  ? 'Tap the + button below to add your first expense'
                  : 'Try a different period or add a new expense',
              textAlign: TextAlign.center,
              style: TextStyle(color: colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}
