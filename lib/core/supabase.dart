import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'constants.dart';

SupabaseClient get supabaseClient => Supabase.instance.client;

final supabaseProvider =
    Provider<SupabaseClient>((_) => Supabase.instance.client);

final authStateProvider = StreamProvider<AuthState>((ref) {
  return ref.watch(supabaseProvider).auth.onAuthStateChange;
});

final currentUserProvider = Provider<User?>((ref) {
  return ref.watch(supabaseProvider).auth.currentUser;
});

Future<void> initSupabase() async {
  await Supabase.initialize(
    url: JConst.supabaseUrl,
    anonKey: JConst.supabaseAnonKey,
  );
}
