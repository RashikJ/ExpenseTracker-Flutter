import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../expenses/screens/expense_list_screen.dart';
import '../../expenses/screens/expense_history_screen.dart';
import '../../expenses/widgets/add_expense_sheet.dart';
import '../providers/navigation_provider.dart';

class HomeShell extends HookConsumerWidget {
  const HomeShell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedIndex = ref.watch(selectedTabProvider);
    const screens = [ExpenseListScreen(), ExpenseHistoryScreen()];

    return Scaffold(
      body: IndexedStack(index: selectedIndex, children: screens),
      floatingActionButton: selectedIndex == 0
          ? FloatingActionButton.extended(
              onPressed: () => showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (_) => const AddExpenseSheet(),
              ),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Add Expense'),
            )
          : null,
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: (index) =>
            ref.read(selectedTabProvider.notifier).state = index,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.history_outlined),
            selectedIcon: Icon(Icons.history_rounded),
            label: 'History',
          ),
        ],
      ),
    );
  }
}