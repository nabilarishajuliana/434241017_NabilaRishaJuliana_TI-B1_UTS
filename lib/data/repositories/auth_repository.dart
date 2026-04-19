import 'package:supabase_flutter/supabase_flutter.dart';

class AuthRepository {
  final _supabase = Supabase.instance.client;

  // LOGIN
  Future<AuthResponse> login({
    required String email,
    required String password,
  }) async {
    return await _supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  // REGISTER
  Future<AuthResponse> register({
    required String nama,
    required String email,
    required String password,
    required String role,
  }) async {
    return await _supabase.auth.signUp(
      email: email,
      password: password,
      data: {
        'nama': nama,
        'role': role,
      },
    );
  }

  // LOGOUT
  Future<void> logout() async {
    await _supabase.auth.signOut();
  }

  // RESET PASSWORD
  Future<void> resetPassword(String email) async {
    await _supabase.auth.resetPasswordForEmail(email);
  }

  // CEK SESSION / SUDAH LOGIN?
  Session? getSession() {
    return _supabase.auth.currentSession;
  }

  // AMBIL DATA USER YANG SEDANG LOGIN
  Future<Map<String, dynamic>?> getCurrentUserProfile() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return null;

    final response = await _supabase
        .from('profiles')
        .select()
        .eq('id', userId)
        .single();

    return response;
  }
}