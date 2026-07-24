import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/expenses/screens/expense_list_screen.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(currentUserProvider);

  return GoRouter(
    initialLocation: '/expenses',
    redirect: (context, state) {
      final isLoggedIn = authState != null;
      final isOnLoginPage = state.matchedLocation == '/login';

      if (!isLoggedIn && !isOnLoginPage) return '/login';
      if (isLoggedIn && isOnLoginPage) return '/expenses';
      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/expenses',
        builder: (context, state) => const ExpenseListScreen(),
      ),
    ],
  );
});