import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../data/models/ticket_model.dart';
import '../../../data/models/comment_model.dart';
import '../../../data/repositories/ticket_repository.dart';

class DetailTicketScreen extends StatefulWidget {
  final String ticketId;
  const DetailTicketScreen({super.key, required this.ticketId});

  @override
  State<DetailTicketScreen> createState() => _DetailTicketScreenState();
}

class _DetailTicketScreenState extends State<DetailTicketScreen> {
  final _ticketRepository = TicketRepository();
  final _commentController = TextEditingController();

  TicketModel? _ticket;
  List<CommentModel> _comments = [];
  List<Map<String, dynamic>> _helpdeskList = [];
  bool _isLoading = true;
  bool _isSendingComment = false;

  String get _userRole {
    final user = Supabase.instance.client.auth.currentUser;
    return user?.userMetadata?['role'] ?? 'user';
  }

  bool get _isAdminOrHelpdesk =>
      _userRole == 'admin' || _userRole == 'helpdesk';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final ticket =
          await _ticketRepository.getTicketDetail(widget.ticketId);
      final comments =
          await _ticketRepository.getComments(widget.ticketId);

      List<Map<String, dynamic>> helpdeskList = [];
      if (_userRole == 'admin') {
        helpdeskList = await _ticketRepository.getHelpdeskList();
      }

      setState(() {
        _ticket = ticket;
        _comments = comments;
        _helpdeskList = helpdeskList;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _sendComment() async {
    if (_commentController.text.trim().isEmpty) return;

    setState(() => _isSendingComment = true);
    try {
      await _ticketRepository.addComment(
        ticketId: widget.ticketId,
        isi: _commentController.text.trim(),
      );
      _commentController.clear();
      await _loadData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal kirim: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSendingComment = false);
    }
  }

  void _showUpdateStatusDialog() {
    final statuses = [
      {'value': 'open', 'label': 'Open', 'color': Colors.blue},
      {'value': 'in_progress', 'label': 'In Progress', 'color': Colors.orange},
      {'value': 'resolved', 'label': 'Resolved', 'color': Colors.green},
      {'value': 'closed', 'label': 'Closed', 'color': Colors.grey},
    ];

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Update Status Tiket',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...statuses.map((status) => ListTile(
                  leading: CircleAvatar(
                    backgroundColor:
                        (status['color'] as Color).withOpacity(0.2),
                    child: Icon(
                      Icons.circle,
                      color: status['color'] as Color,
                      size: 12,
                    ),
                  ),
                  title: Text(status['label'] as String),
                  trailing: _ticket?.status == status['value']
                      ? const Icon(Icons.check, color: Colors.green)
                      : null,
                  onTap: () async {
                    Navigator.pop(context);
                    await _ticketRepository.updateTicketStatus(
                      ticketId: widget.ticketId,
                      status: status['value'] as String,
                    );
                    await _loadData();
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Status berhasil diupdate!'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  },
                )),
          ],
        ),
      ),
    );
  }

  void _showAssignDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Assign ke Helpdesk',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            if (_helpdeskList.isEmpty)
              const Center(child: Text('Tidak ada helpdesk tersedia'))
            else
              ..._helpdeskList.map((helpdesk) => ListTile(
                    leading: CircleAvatar(
                      child: Text(
                        (helpdesk['nama'] as String)[0].toUpperCase(),
                      ),
                    ),
                    title: Text(helpdesk['nama'] as String),
                    subtitle: Text(helpdesk['email'] as String),
                    trailing: _ticket?.assignedTo == helpdesk['id']
                        ? const Icon(Icons.check, color: Colors.green)
                        : null,
                    onTap: () async {
                      Navigator.pop(context);
                      await _ticketRepository.assignTicket(
                        ticketId: widget.ticketId,
                        helpdeskId: helpdesk['id'] as String,
                      );
                      await _loadData();
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Tiket di-assign ke ${helpdesk['nama']}',
                            ),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }
                    },
                  )),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'open': return Colors.blue;
      case 'in_progress': return Colors.orange;
      case 'resolved': return Colors.green;
      case 'closed': return Colors.grey;
      default: return Colors.blue;
    }
  }

  String _getStatusLabel(String status) {
    switch (status) {
      case 'open': return 'Open';
      case 'in_progress': return 'In Progress';
      case 'resolved': return 'Resolved';
      case 'closed': return 'Closed';
      default: return status;
    }
  }

  Widget _buildTrackingTimeline(String currentStatus) {
  final steps = [
    {'status': 'open', 'label': 'Open', 'desc': 'Tiket diterima'},
    {'status': 'in_progress', 'label': 'In Progress', 'desc': 'Sedang ditangani'},
    {'status': 'resolved', 'label': 'Resolved', 'desc': 'Masalah diselesaikan'},
    {'status': 'closed', 'label': 'Closed', 'desc': 'Tiket ditutup'},
  ];

  final statusOrder = ['open', 'in_progress', 'resolved', 'closed'];
  final currentIndex = statusOrder.indexOf(currentStatus);

  return Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
  color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
  borderRadius: BorderRadius.circular(12),
  border: Border.all(color: Theme.of(context).dividerColor),
),
    child: Row(
      children: List.generate(steps.length, (index) {
        final step = steps[index];
        final isDone = index <= currentIndex;
        final isCurrent = index == currentIndex;
        final isLast = index == steps.length - 1;

        return Expanded(
          child: Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    // Circle indicator
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: isDone
                            ? const Color(0xFF2563EB)
                            : Colors.grey.shade300,
                        shape: BoxShape.circle,
                        border: isCurrent
                            ? Border.all(
                                color: const Color(0xFF2563EB),
                                width: 3,
                              )
                            : null,
                      ),
                      child: Icon(
                        isDone ? Icons.check : Icons.circle,
                        color: Colors.white,
                        size: isDone ? 16 : 8,
                      ),
                    ),
                    const SizedBox(height: 6),
                    // Label
                    Text(
                      step['label']!,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: isCurrent
                            ? FontWeight.bold
                            : FontWeight.normal,
                        color: isDone
                            ? const Color(0xFF2563EB)
                            : Colors.grey.shade400,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    // Desc
                    Text(
                      step['desc']!,
                      style: TextStyle(
                        fontSize: 9,
                        color: Colors.grey.shade400,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              // Line connector
              if (!isLast)
                Expanded(
                  child: Container(
                    height: 2,
                    margin: const EdgeInsets.only(bottom: 32),
                    color: index < currentIndex
                        ? const Color(0xFF2563EB)
                        : Colors.grey.shade300,
                  ),
                ),
            ],
          ),
        );
      }),
    ),
  );
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Tiket'),
        actions: [
          if (_isAdminOrHelpdesk) ...[
            IconButton(
              icon: const Icon(Icons.update),
              tooltip: 'Update Status',
              onPressed: _showUpdateStatusDialog,
            ),
            if (_userRole == 'admin')
              IconButton(
                icon: const Icon(Icons.person_add_outlined),
                tooltip: 'Assign Tiket',
                onPressed: _showAssignDialog,
              ),
          ],
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _ticket == null
              ? const Center(child: Text('Tiket tidak ditemukan'))
              : Column(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Status Badge
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _getStatusColor(_ticket!.status)
                                        .withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    _getStatusLabel(_ticket!.status),
                                    style: TextStyle(
                                      color:
                                          _getStatusColor(_ticket!.status),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
// Tracking Timeline
const SizedBox(height: 16),
const Text(
  'Tracking Status',
  style: TextStyle(fontWeight: FontWeight.w600),
),
const SizedBox(height: 12),
_buildTrackingTimeline(_ticket!.status),
const SizedBox(height: 16),
                            // Judul
                            Text(
                              _ticket!.judul,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),

                            // Tanggal
                            Text(
                              'Dibuat: ${_ticket!.createdAt.day}/${_ticket!.createdAt.month}/${_ticket!.createdAt.year}',
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Assigned To (kalau ada)
                            if (_ticket!.assignedTo != null) ...[
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.purple.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: Colors.purple.withOpacity(0.3),
                                  ),
                                ),
                                child: const Row(
                                  children: [
                                    Icon(
                                      Icons.person_outline,
                                      color: Colors.purple,
                                      size: 16,
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      'Sudah di-assign ke Helpdesk',
                                      style: TextStyle(
                                        color: Colors.purple,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),
                            ],

                            // Deskripsi
                            const Text(
                              'Deskripsi',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
  color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
  borderRadius: BorderRadius.circular(8),
),
                              child: Text(_ticket!.deskripsi),
                            ),
                            const SizedBox(height: 16),

                            // Gambar kalau ada
                            if (_ticket!.imageUrl != null) ...[
                              const Text(
                                'Lampiran',
                                style:
                                    TextStyle(fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(height: 8),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  _ticket!.imageUrl!,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                  errorBuilder: (c, e, s) => const Text(
                                    'Gambar tidak bisa dimuat',
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                            ],

                            // Komentar
                            Text(
                              'Komentar (${_comments.length})',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 8),
                            if (_comments.isEmpty)
                              Text(
                                'Belum ada komentar',
                                style: TextStyle(
                                  color: Colors.grey.shade500,
                                ),
                              )
                            else
                              ListView.builder(
                                shrinkWrap: true,
                                physics:
                                    const NeverScrollableScrollPhysics(),
                                itemCount: _comments.length,
                                itemBuilder: (context, index) {
                                  final comment = _comments[index];
                                  final isMe = comment.userId ==
                                      Supabase.instance.client.auth
                                          .currentUser?.id;
                                  return Align(
                                    alignment: isMe
                                        ? Alignment.centerRight
                                        : Alignment.centerLeft,
                                    child: Container(
                                      margin: const EdgeInsets.only(
                                        bottom: 8,
                                      ),
                                      padding: const EdgeInsets.all(12),
                                      constraints: BoxConstraints(
                                        maxWidth: MediaQuery.of(context)
                                                .size
                                                .width *
                                            0.75,
                                      ),
                                      decoration: BoxDecoration(
                                        color: isMe
    ? const Color(0xFF2563EB)
    : Theme.of(context).colorScheme.surfaceVariant,
                                        borderRadius:
                                            BorderRadius.circular(12),
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            comment.userProfile?['nama'] ??
                                                'User',
                                            style: TextStyle(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 12,
                                              color: isMe
                                                  ? Colors.white70
                                                  : Colors.grey.shade600,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            comment.isi,
                                            style: TextStyle(
                                              color: isMe
    ? Colors.white
    : Theme.of(context).colorScheme.onSurface,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                          ],
                        ),
                      ),
                    ),

                    // Input Komentar
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).scaffoldBackgroundColor,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, -4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _commentController,
                              decoration: InputDecoration(
                                hintText: 'Tulis komentar...',
                                contentPadding:
                                    const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(24),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          _isSendingComment
                              ? const CircularProgressIndicator()
                              : IconButton(
                                  onPressed: _sendComment,
                                  icon: const Icon(Icons.send),
                                  color: const Color(0xFF2563EB),
                                  style: IconButton.styleFrom(
                                    backgroundColor: const Color(0xFF2563EB)
                                        .withOpacity(0.1),
                                  ),
                                ),
                        ],
                      ),
                    ),
                  ],
                ),
    );
  }
}