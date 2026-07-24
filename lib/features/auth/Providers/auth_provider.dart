import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../main.dart';

final authStateProvider = StreamProvider<AuthState>((ref) {
  return supabase.auth.onAuthStateChange;
});

final currentUserProvider = Provider<User?>((ref) {
  final authState = ref.watch(authStateProvider).value;
  return authState?.session?.user ?? supabase.auth.currentUser;
});

final authRepositoryProvider = Provider((ref) => AuthRepository());

class AuthRepository {
  final _client = supabase.auth;

 Future<void> signUp(
  String email,
  String password, {
  String? firstName,
  String? lastName,
}) async {
  await _client.signUp(
    email: email,
    password: password,
    data: {
      'first_name': firstName,
      'last_name': lastName,
    },
  );
}

  Future<void> signIn(String email, String password) async {
    await _client.signInWithPassword(email: email, password: password);
  }

  Future<void> signOut() async {
    await _client.signOut();
  }
}
