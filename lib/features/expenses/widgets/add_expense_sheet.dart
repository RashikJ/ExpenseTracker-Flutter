import 'package:expense_tracker/features/categories/data/category_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';

import '../data/expense_repository.dart';
import '../models/expense_model.dart';
import '../../categories/models/category_model.dart';

class AddExpenseSheet extends HookConsumerWidget {
  const AddExpenseSheet({super.key, this.expense});

  final Expense? expense;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

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
          color: colorScheme.surface,
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
                    color: colorScheme.outlineVariant,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),
              Text(
                expense == null ? 'Add Expense' : 'Edit Expense',
                style: theme.textTheme.titleLarge,
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
                data: (categories) {
                  ExpenseCategory? initial;
                  for (final c in categories) {
                    if (c.id == selectedCategoryId.value) initial = c;
                  }
                  return Autocomplete<ExpenseCategory>(
                    initialValue: TextEditingValue(text: initial?.name ?? ''),
                    displayStringForOption: (category) => category.name,
                    optionsBuilder: (textEditingValue) {
                      if (textEditingValue.text.isEmpty) return categories;
                      final query = textEditingValue.text.toLowerCase();
                      return categories.where(
                        (category) =>
                            category.name.toLowerCase().contains(query),
                      );
                    },
                    onSelected: (category) =>
                        selectedCategoryId.value = category.id,
                    fieldViewBuilder:
                        (context, controller, focusNode, onFieldSubmitted) {
                      return TextFormField(
                        controller: controller,
                        focusNode: focusNode,
                        decoration: const InputDecoration(
                          labelText: 'Category',
                          prefixIcon: Icon(Icons.category_outlined),
                        ),
                      );
                    },
                  );
                },
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
                  style: TextStyle(color: colorScheme.error),
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