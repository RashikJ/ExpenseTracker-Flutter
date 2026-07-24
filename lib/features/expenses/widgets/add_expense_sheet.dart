import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';

import '../data/expense_repository.dart';
import '../models/expense_model.dart';
import '../../categories/data/category_repository.dart';
import '../../categories/models/category_model.dart';

class AddExpenseSheet extends HookConsumerWidget {
  const AddExpenseSheet({super.key, this.expense});

  final Expense? expense;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final amountController = useTextEditingController(
      text: expense?.amount.toString() ?? '',
    );
    final noteController = useTextEditingController(text: expense?.note ?? '');
    final formKey = useMemoized(() => GlobalKey<FormState>());
    final selectedCategoryId = useState<String?>(expense?.categoryId);
    final selectedDate = useState(expense?.expenseDate ?? DateTime.now());
    final isLoading = useState(false);
    final errorMessage = useState<String?>(null);

    final categoriesAsync = ref.watch(categoriesStreamProvider);

    Future<void> submit() async {
      if (!formKey.currentState!.validate()) return;

      isLoading.value = true;
      errorMessage.value = null;

      try {
        final repo = ref.read(expenseRepositoryProvider);
        final note = noteController.text.trim().isEmpty
            ? null
            : noteController.text.trim();
        final amount = double.parse(amountController.text.trim());

        if (expense == null) {
          await repo.addExpense(
            amount: amount,
            categoryId: selectedCategoryId.value,
            note: note,
            expenseDate: selectedDate.value,
          );
        } else {
          await updateExpense(
            id: expense!.id,
            amount: amount,
            categoryId: selectedCategoryId.value,
            note: note,
            expenseDate: selectedDate.value,
          );
        }
        if (context.mounted) Navigator.of(context).pop();
      } catch (e) {
        errorMessage.value = expense == null
            ? 'Failed to add expense. Please try again.'
            : 'Failed to update expense. Please try again.';
      } finally {
        isLoading.value = false;
      }
    }

    Future<void> pickDate() async {
      final picked = await showDatePicker(
        context: context,
        initialDate: selectedDate.value,
        firstDate: DateTime(2020),
        lastDate: DateTime.now(),
      );
      if (picked != null) selectedDate.value = picked;
    }

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.outlineVariant,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),
              Text(
                expense == null ? 'Add Expense' : 'Edit Expense',
                style: Theme.of(context).textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: amountController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Amount',
                  prefixIcon: Icon(Icons.currency_rupee),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Amount is required';
                  }
                  final parsed = double.tryParse(value.trim());
                  if (parsed == null || parsed <= 0) {
                    return 'Enter a valid amount';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              categoriesAsync.when(
                data: (categories) => _CategoryPicker(
                  categories: categories,
                  selectedId: selectedCategoryId.value,
                  onChanged: (id) => selectedCategoryId.value = id,
                ),
                loading: () => const LinearProgressIndicator(),
                error: (_, __) => const SizedBox.shrink(),
              ),
              const SizedBox(height: 16),
              InkWell(
                onTap: pickDate,
                borderRadius: BorderRadius.circular(12),
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Date',
                    prefixIcon: Icon(Icons.calendar_today_outlined),
                  ),
                  child: Text(DateFormat.yMMMd().format(selectedDate.value)),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: noteController,
                decoration: const InputDecoration(
                  labelText: 'Note (optional)',
                  prefixIcon: Icon(Icons.notes_outlined),
                ),
              ),
              if (errorMessage.value != null) ...[
                const SizedBox(height: 12),
                Text(
                  errorMessage.value!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                  textAlign: TextAlign.center,
                ),
              ],
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: isLoading.value ? null : submit,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                ),
                child: isLoading.value
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(expense == null ? 'Save Expense' : 'Update Expense'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoryPicker extends HookConsumerWidget {
  const _CategoryPicker({
    required this.categories,
    required this.selectedId,
    required this.onChanged,
  });

  final List<ExpenseCategory> categories;
  final String? selectedId;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (categories.isEmpty) {
      return OutlinedButton.icon(
        onPressed: () => _showCreateCategoryDialog(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Create your first category'),
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        ...categories.map((category) {
          final isSelected = category.id == selectedId;
          return ChoiceChip(
            label: Text(category.name),
            selected: isSelected,
            onSelected: (_) => onChanged(category.id),
          );
        }),
        ActionChip(
          avatar: const Icon(Icons.add, size: 18),
          label: const Text('New'),
          onPressed: () => _showCreateCategoryDialog(context, ref),
        ),
      ],
    );
  }

  Future<void> _showCreateCategoryDialog(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('New Category'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Category name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(controller.text.trim()),
            child: const Text('Create'),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
      await ref.read(categoryRepositoryProvider).createCategory(name: result);
    }
  }
}
