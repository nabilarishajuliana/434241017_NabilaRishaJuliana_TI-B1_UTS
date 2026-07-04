import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../data/models/ticket_model.dart';
import '../../../data/repositories/ticket_repository.dart';
import '../../../core/utils/user_role_helper.dart';

class TrackingTicketScreen extends StatefulWidget {
  const TrackingTicketScreen({super.key});

  @override
  State<TrackingTicketScreen> createState() => _TrackingTicketScreenState();
}

class _TrackingTicketScreenState extends State<TrackingTicketScreen> {
  final _ticketRepository = TicketRepository();
  List<TicketModel> _tickets = [];
  bool _isLoading = true;

  String _userRole = 'user';

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    final role = await UserRoleHelper.getRole();
    if (mounted) {
      setState(() => _userRole = role);
      _loadTickets();
    }
  }

  Future<void> _loadTickets() async {
    setState(() => _isLoading = true);
    try {
      List<TicketModel> tickets;
      if (_userRole == 'admin') {
        // Admin lihat semua tiket yang belum closed
        final all = await _ticketRepository.getAllTickets();
        tickets = all.where((t) => t.status != 'closed').toList();
      } else if (_userRole == 'helpdesk') {
        // Helpdesk lihat tiket yang related dengan dia (buat + di-assign)
        final helpdeskTickets = await _ticketRepository.getHelpdeskTickets();
        tickets = helpdeskTickets.where((t) => t.status != 'closed').toList();
      } else {
        // User lihat tiket aktif miliknya
        final mine = await _ticketRepository.getMyTickets();
        tickets = mine.where((t) => t.status != 'closed').toList();
      }
      setState(() => _tickets = tickets);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'open':
        return Colors.blue;
      case 'assign':
        return Colors.purple;
      case 'in_progress':
        return Colors.orange;
      case 'closed':
        return Colors.grey;
      default:
        return Colors.blue;
    }
  }

  String _getStatusLabel(String status) {
    switch (status) {
      case 'open':
        return 'Open';
      case 'assign':
        return 'Assigned';
      case 'in_progress':
        return 'In Progress';
      case 'closed':
        return 'Closed';
      default:
        return status;
    }
  }

  Widget _buildTrackingTimeline(String currentStatus) {
    final steps = [
      {
        'status': 'open',
        'label': 'Open',
        'desc': 'Tiket dibuat',
        'icon': Icons.fiber_new,
      },
      {
        'status': 'assign',
        'label': 'Assigned',
        'desc': 'Diterima admin',
        'icon': Icons.person_pin,
      },
      {
        'status': 'in_progress',
        'label': 'In Progress',
        'desc': 'Sedang ditangani',
        'icon': Icons.sync,
      },
      {
        'status': 'closed',
        'label': 'Closed',
        'desc': 'Selesai',
        'icon': Icons.check_circle,
      },
    ];

    final statusOrder = ['open', 'assign', 'in_progress', 'closed'];
    final currentIndex = statusOrder.indexOf(currentStatus);

    return Row(
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
                                color: const Color.fromARGB(255, 248, 234, 51),
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
                    const SizedBox(height: 4),
                    // Label
                    Text(
                      step['label'] as String,
                      style: TextStyle(
                        fontSize: 9,
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
                      step['desc'] as String,
                      style: TextStyle(
                        fontSize: 8,
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
    );
  }

  String _getTrackingTitle() {
    switch (_userRole) {
      case 'admin':
        return 'Tracking Semua Tiket Aktif';
      case 'helpdesk':
        return 'Tracking Tiket Ditugaskan';
      default:
        return 'Tracking Tiket Saya';
    }
  }

  String _getEmptyMessage() {
    switch (_userRole) {
      case 'admin':
        return 'Tidak ada tiket aktif saat ini';
      case 'helpdesk':
        return 'Tidak ada tiket yang sedang ditangani';
      default:
        return 'Tidak ada tiket aktif saat ini';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tracking Tiket'),
        automaticallyImplyLeading: false,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Header info
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  color: const Color(0xFF2563EB).withOpacity(0.05),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.track_changes,
                        color: Color(0xFF2563EB),
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _getTrackingTitle(),
                          style: const TextStyle(
                            color: Color(0xFF2563EB),
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2563EB),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${_tickets.length} tiket',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // List tiket dengan tracking
                Expanded(
                  child: _tickets.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.track_changes,
                                size: 80,
                                color: Colors.grey.shade400,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                _getEmptyMessage(),
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey.shade600,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Tiket yang sudah Closed\ntidak ditampilkan di sini',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade400,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _loadTickets,
                          child: ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _tickets.length,
                            itemBuilder: (context, index) {
                              final ticket = _tickets[index];
                              return GestureDetector(
                                onTap: () async {
                                  await context.push('/tickets/${ticket.id}');
                                  _loadTickets();
                                },
                                child: Container(
                                  margin: const EdgeInsets.only(bottom: 16),
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: Colors.grey.shade200,
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      // Header tiket
                                      Container(
                                        padding: const EdgeInsets.all(16),
                                        decoration: BoxDecoration(
                                          color: _getStatusColor(
                                            ticket.status,
                                          ).withOpacity(0.08),
                                          borderRadius: const BorderRadius.only(
                                            topLeft: Radius.circular(12),
                                            topRight: Radius.circular(12),
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            // Badge status
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                    vertical: 4,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: _getStatusColor(
                                                  ticket.status,
                                                ).withOpacity(0.15),
                                                borderRadius:
                                                    BorderRadius.circular(4),
                                              ),
                                              child: Text(
                                                _getStatusLabel(ticket.status),
                                                style: TextStyle(
                                                  color: _getStatusColor(
                                                    ticket.status,
                                                  ),
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            // Judul
                                            Expanded(
                                              child: Text(
                                                ticket.judul,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 14,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            // Arrow
                                            Icon(
                                              Icons.chevron_right,
                                              color: Colors.grey.shade400,
                                              size: 20,
                                            ),
                                          ],
                                        ),
                                      ),

                                      // Tracking Timeline
                                      Padding(
                                        padding: const EdgeInsets.all(16),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            // Info tambahan
                                            Row(
                                              children: [
                                                Icon(
                                                  Icons.access_time,
                                                  size: 12,
                                                  color: Colors.grey.shade500,
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  'Dibuat: ${ticket.createdAt.day}/${ticket.createdAt.month}/${ticket.createdAt.year}',
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    color: Colors.grey.shade500,
                                                  ),
                                                ),
                                                const Spacer(),
                                                if (ticket.assignedTo !=
                                                    null) ...[
                                                  Icon(
                                                    Icons.person_outline,
                                                    size: 12,
                                                    color:
                                                        Colors.purple.shade300,
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    'Assigned',
                                                    style: TextStyle(
                                                      fontSize: 11,
                                                      color: Colors
                                                          .purple
                                                          .shade300,
                                                    ),
                                                  ),
                                                ],
                                              ],
                                            ),
                                            const SizedBox(height: 16),

                                            // Timeline
                                            _buildTrackingTimeline(
                                              ticket.status,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                ),
              ],
            ),
    );
  }
}
