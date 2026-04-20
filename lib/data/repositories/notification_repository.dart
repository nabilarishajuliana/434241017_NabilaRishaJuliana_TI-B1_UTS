import 'package:supabase_flutter/supabase_flutter.dart';

class NotificationRepository {
  final _supabase = Supabase.instance.client;

  // Ambil semua notifikasi user yang login
  Future<List<Map<String, dynamic>>> getNotifications() async {
    final userId = _supabase.auth.currentUser!.id;
    final response = await _supabase
        .from('notifications')
        .select('*, tickets(judul)')
        .eq('user_id', userId)
        .order('created_at', ascending: false);

    return (response as List).cast<Map<String, dynamic>>();
  }

  // Tandai notifikasi sebagai sudah dibaca
  Future<void> markAsRead(String notificationId) async {
    await _supabase
        .from('notifications')
        .update({'is_read': true}).eq('id', notificationId);
  }

  // Tandai semua notifikasi sebagai sudah dibaca
  Future<void> markAllAsRead() async {
    final userId = _supabase.auth.currentUser!.id;
    await _supabase
        .from('notifications')
        .update({'is_read': true})
        .eq('user_id', userId)
        .eq('is_read', false);
  }

  // Hitung notifikasi yang belum dibaca
  Future<int> getUnreadCount() async {
    final userId = _supabase.auth.currentUser!.id;
    final response = await _supabase
        .from('notifications')
        .select()
        .eq('user_id', userId)
        .eq('is_read', false);

    return (response as List).length;
  }
}