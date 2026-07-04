import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/ticket_model.dart';
import '../models/comment_model.dart';

class TicketRepository {
  final _supabase = Supabase.instance.client;

  // AMBIL TIKET MILIK USER SENDIRI
  Future<List<TicketModel>> getMyTickets() async {
    final userId = _supabase.auth.currentUser!.id;
    final response = await _supabase
        .from('tickets')
        .select('*, profiles!tickets_user_id_fkey(*)')
        .eq('user_id', userId)
        .order('created_at', ascending: false);

    return (response as List).map((e) => TicketModel.fromJson(e)).toList();
  }

  // AMBIL SEMUA TIKET (ADMIN)
  Future<List<TicketModel>> getAllTickets() async {
    final response = await _supabase
        .from('tickets')
        .select('*, profiles!tickets_user_id_fkey(*)')
        .order('created_at', ascending: false);

    return (response as List).map((e) => TicketModel.fromJson(e)).toList();
  }

  // AMBIL TIKET YANG DI-ASSIGN KE HELPDESK YANG LOGIN
  Future<List<TicketModel>> getAssignedTickets() async {
    final userId = _supabase.auth.currentUser!.id;
    final response = await _supabase
        .from('tickets')
        .select('*, profiles!tickets_user_id_fkey(*)')
        .eq(
          'assigned_to',
          userId,
        ) // hanya tiket yang assigned_to = id helpdesk ini
        .order('created_at', ascending: false);

    return (response as List).map((e) => TicketModel.fromJson(e)).toList();
  }

  // AMBIL DETAIL TIKET
  Future<TicketModel> getTicketDetail(String ticketId) async {
    final response = await _supabase
        .from('tickets')
        .select('*, profiles!tickets_user_id_fkey(*)')
        .eq('id', ticketId)
        .single();

    return TicketModel.fromJson(response);
  }

  // BUAT TIKET BARU
  Future<void> createTicket({
    required String judul,
    required String deskripsi,
    String? imageUrl,
  }) async {
    final userId = _supabase.auth.currentUser!.id;
    await _supabase.from('tickets').insert({
      'judul': judul,
      'deskripsi': deskripsi,
      'status': 'open',
      'user_id': userId,
      'image_url': imageUrl,
    });
  }

  // UPDATE STATUS TIKET (GADIPAKE LAGI)
  // Future<void> updateTicketStatus({
  //   required String ticketId,
  //   required String status,
  // }) async {
  //   await _supabase
  //       .from('tickets')
  //       .update({
  //         'status': status,
  //         'updated_at': DateTime.now().toIso8601String(),
  //       })
  //       .eq('id', ticketId);
  // }

  // ASSIGN TIKET KE HELPDESK
  Future<void> assignTicket({
    required String ticketId,
    required String helpdeskId,
  }) async {
    await _supabase
        .from('tickets')
        .update({
          'assigned_to': helpdeskId,
          'status': 'in_progress', // otomatis ubah status jadi in_progress
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', ticketId);
  }

  // ADMIN TERIMA TIKET (open -> assign)
  Future<void> acceptTicket(String ticketId) async {
    await _supabase
        .from('tickets')
        .update({
          'status': 'assign',
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', ticketId);
  }

  // HELPDESK SELESAIKAN TIKET (in_progress -> closed)
  Future<void> finishTicket(String ticketId) async {
    await _supabase
        .from('tickets')
        .update({
          'status': 'closed',
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', ticketId);
  }

  // Future<void> assignTicket({
  //   required String ticketId,
  //   required String helpdeskId,
  // }) async {
  //   await _supabase
  //       .from('tickets')
  //       .update({
  //         'assigned_to': helpdeskId,
  //         'updated_at': DateTime.now().toIso8601String(),
  //       })
  //       .eq('id', ticketId);
  // }

  // UPLOAD GAMBAR
  Future<String?> uploadImage(Uint8List imageBytes, String fileName) async {
    final path = 'tickets/$fileName';
    await _supabase.storage
        .from('ticket-images')
        .uploadBinary(path, imageBytes);

    final url = _supabase.storage.from('ticket-images').getPublicUrl(path);

    return url;
  }

  // AMBIL KOMENTAR
  Future<List<CommentModel>> getComments(String ticketId) async {
    final response = await _supabase
        .from('comments')
        .select('*, profiles(*)')
        .eq('ticket_id', ticketId)
        .order('created_at', ascending: true);

    return (response as List).map((e) => CommentModel.fromJson(e)).toList();
  }

  // KIRIM KOMENTAR
  Future<void> addComment({
    required String ticketId,
    required String isi,
  }) async {
    final userId = _supabase.auth.currentUser!.id;
    await _supabase.from('comments').insert({
      'ticket_id': ticketId,
      'user_id': userId,
      'isi': isi,
    });
  }

  // AMBIL LIST HELPDESK (UNTUK ASSIGN)
  Future<List<Map<String, dynamic>>> getHelpdeskList() async {
    final response = await _supabase
        .from('profiles')
        .select()
        .eq('role', 'helpdesk');

    return (response as List).cast<Map<String, dynamic>>();
  }

  // AMBIL TIKET UNTUK HELPDESK
// Gabungan: tiket yang dia buat + tiket yang di-assign ke dia
Future<List<TicketModel>> getHelpdeskTickets() async {
  final userId = _supabase.auth.currentUser!.id;
  final response = await _supabase
      .from('tickets')
      .select('*, profiles!tickets_user_id_fkey(*)')
      .or('user_id.eq.$userId,assigned_to.eq.$userId')
      .order('created_at', ascending: false);

  return (response as List)
      .map((e) => TicketModel.fromJson(e))
      .toList();
}

  // DELETE TIKET
  Future<void> deleteTicket(String ticketId) async {
    // Hapus komentar dulu (karena ada foreign key)
    await _supabase.from('comments').delete().eq('ticket_id', ticketId);

    // Hapus notifikasi terkait tiket
    await _supabase.from('notifications').delete().eq('ticket_id', ticketId);

    // Baru hapus tiketnya
    await _supabase.from('tickets').delete().eq('id', ticketId);
  }
}
