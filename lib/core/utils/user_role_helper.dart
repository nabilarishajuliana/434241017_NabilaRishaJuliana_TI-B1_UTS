import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class UserRoleHelper {
  static const String _roleKey = 'user_role';

  // Simpan role ke local storage
  static Future<void> saveRole(String role) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_roleKey, role);
  }

  // Ambil role dari local storage
  static Future<String> getRole() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_roleKey) ?? 'user';
  }

  // Ambil role langsung dari database (fresh)
  static Future<String> fetchRoleFromDb() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return 'user';

    try {
      final response = await Supabase.instance.client
          .from('profiles')
          .select('role')
          .eq('id', userId)
          .single();
      
      final role = response['role'] ?? 'user';
      await saveRole(role); // update cache
      return role;
    } catch (e) {
      return 'user';
    }
  }

  // Hapus role saat logout
  static Future<void> clearRole() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_roleKey);
  }
}