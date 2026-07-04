import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/utils/user_role_helper.dart';

class AuthRepository {
  final _supabase = Supabase.instance.client;

  //LOGIN
  Future<AuthResponse> login({
    required String email,
    required String password,
  }) async {
    final response = await _supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );

    if (response.user != null) {
      final profile = await _supabase
          .from('profiles')
          .select('is_active, role')
          .eq('id', response.user!.id)
          .single();

      final isActive = profile['is_active'] ?? true;

      if (!isActive) {
        await _supabase.auth.signOut();
        throw Exception(
          'Akun kamu telah dinonaktifkan. Hubungi admin untuk informasi lebih lanjut.',
        );
      }

      // Simpan role ke local storage
      await UserRoleHelper.saveRole(profile['role'] ?? 'user');
    }

    return response;
  }

  // LOGIN (OLD)
  // Future<AuthResponse> login({
  //   required String email,
  //   required String password,
  // }) async {
  //   // Login dulu ke Supabase Auth
  //   final response = await _supabase.auth.signInWithPassword(
  //     email: email,
  //     password: password,
  //   );

  //   // Setelah login berhasil, cek apakah akun aktif
  //   if (response.user != null) {
  //     final profile = await _supabase
  //         .from('profiles')
  //         .select('is_active')
  //         .eq('id', response.user!.id)
  //         .single();

  //     final isActive = profile['is_active'] ?? true;

  //     if (!isActive) {
  //       // Langsung logout kalau tidak aktif
  //       await _supabase.auth.signOut();
  //       throw Exception(
  //         'Akun kamu telah dinonaktifkan. Hubungi admin untuk informasi lebih lanjut.',
  //       );
  //     }
  //   }

  //   return response;
  // }

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
      data: {'nama': nama, 'role': role},
    );
  }

  // LOGOUT
  Future<void> logout() async {
    await UserRoleHelper.clearRole(); // clear role cache
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

  // AMBIL SEMUA USER (KHUSUS ADMIN)
  Future<List<Map<String, dynamic>>> getAllUsers() async {
    final response = await _supabase
        .from('profiles')
        .select()
        .order('created_at', ascending: false);

    return (response as List).cast<Map<String, dynamic>>();
  }

  // NON-AKTIFKAN / AKTIFKAN USER
  Future<void> toggleUserActive({
    required String userId,
    required bool isActive,
  }) async {
    await _supabase
        .from('profiles')
        .update({'is_active': isActive})
        .eq('id', userId);
  }

  // UBAH ROLE USER
  Future<void> updateUserRole({
    required String userId,
    required String newRole,
  }) async {
    await _supabase.from('profiles').update({'role': newRole}).eq('id', userId);
  }
}
