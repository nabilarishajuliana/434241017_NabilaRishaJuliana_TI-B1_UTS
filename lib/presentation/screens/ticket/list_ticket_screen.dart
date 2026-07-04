import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../data/models/ticket_model.dart';
import '../../../data/repositories/ticket_repository.dart';
import '../../../core/utils/user_role_helper.dart';

class ListTicketScreen extends StatefulWidget {
  const ListTicketScreen({super.key});

  @override
  State<ListTicketScreen> createState() => _ListTicketScreenState();
}

class _ListTicketScreenState extends State<ListTicketScreen> {
  final _ticketRepository = TicketRepository();
  List<TicketModel> _allTickets = [];
  List<TicketModel> _filteredTickets = [];
  bool _isLoading = true;
  String _selectedFilter = 'all';

  String _userRole = 'user';

  final List<Map<String, String>> _filters = [
    {'value': 'all', 'label': 'Semua'},
    {'value': 'open', 'label': 'Open'},
    {'value': 'assign', 'label': 'Assigned'},
    {'value': 'in_progress', 'label': 'In Progress'},
    {'value': 'closed', 'label': 'Closed'},
  ];

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    // Load role dulu
    final role = await UserRoleHelper.getRole();
    if (mounted) {
      setState(() => _userRole = role);
      // Baru load tiket setelah role dapat
      _loadTickets();
    }
  }

  Future<void> _loadTickets() async {
    setState(() => _isLoading = true);
    try {
      List<TicketModel> tickets;

      // ===== DEBUG =====
      print('===== DEBUG LIST TIKET =====');
      print('User Role: $_userRole');
      print('User ID: ${Supabase.instance.client.auth.currentUser?.id}');
      // =================

      if (_userRole == 'admin') {
        // Admin tetap lihat semua tiket
        tickets = await _ticketRepository.getAllTickets();
      } else if (_userRole == 'helpdesk') {
        // Helpdesk lihat tiket yang di-assign + tiket yang dia buat
        print('Calling getHelpdeskTickets...');
        tickets = await _ticketRepository.getHelpdeskTickets();
        print('Got ${tickets.length} tickets');
      } else {
        // User lihat tiket miliknya sendiri
        print('Calling getMyTickets (fallback ke user)');
        tickets = await _ticketRepository.getMyTickets();
      }
      setState(() {
        _allTickets = tickets;
        _applyFilter(_selectedFilter);
      });
    } catch (e) {
      print('===== ERROR: $e =====');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _applyFilter(String filter) {
    setState(() {
      _selectedFilter = filter;
      if (filter == 'all') {
        _filteredTickets = _allTickets;
      } else {
        _filteredTickets = _allTickets
            .where((t) => t.status == filter)
            .toList();
      }
    });
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

  Widget _buildTicketCard(ticket) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        title: Text(
          ticket.judul,
          style: const TextStyle(fontWeight: FontWeight.w600),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              ticket.deskripsi,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _getStatusColor(ticket.status).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    _getStatusLabel(ticket.status),
                    style: TextStyle(
                      color: _getStatusColor(ticket.status),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  '${ticket.createdAt.day}/${ticket.createdAt.month}/${ticket.createdAt.year}',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                ),
              ],
            ),
          ],
        ),
        onTap: () async {
          await context.push('/tickets/${ticket.id}');
          _loadTickets();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Daftar Tiket'),
        automaticallyImplyLeading: false,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await context.push('/tickets/create');
          _loadTickets();
        },
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          // Filter Chips
          SizedBox(
            height: 56,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: _filters.length,
              itemBuilder: (context, index) {
                final filter = _filters[index];
                final isSelected = _selectedFilter == filter['value'];
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(filter['label']!),
                    selected: isSelected,
                    onSelected: (_) => _applyFilter(filter['value']!),
                    selectedColor: const Color(0xFF2563EB).withOpacity(0.2),
                    checkmarkColor: const Color(0xFF2563EB),
                    labelStyle: TextStyle(
                      color: isSelected
                          ? const Color(0xFF2563EB)
                          : Colors.grey.shade600,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.normal,
                    ),
                  ),
                );
              },
            ),
          ),

          // List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredTickets.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.inbox,
                          size: 80,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _userRole == 'helpdesk'
                              ? 'Belum ada tiket yang di-assign ke kamu'
                              : 'Tidak ada tiket',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        if (_userRole == 'user' &&
                            _selectedFilter == 'all') ...[
                          const SizedBox(height: 8),
                          TextButton(
                            onPressed: () async {
                              await context.push('/tickets/create');
                              _loadTickets();
                            },
                            child: const Text('Buat Tiket Sekarang'),
                          ),
                        ],
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _loadTickets,
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _filteredTickets.length,
                      itemBuilder: (context, index) {
                        final ticket = _filteredTickets[index];

                        // Swipe to delete khusus Admin
                        if (_userRole == 'admin') {
                          return Dismissible(
                            key: Key(ticket.id),
                            direction: DismissDirection.endToStart,
                            background: Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              decoration: BoxDecoration(
                                color: Colors.red,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.only(right: 20),
                              child: const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.delete, color: Colors.white),
                                  SizedBox(height: 4),
                                  Text(
                                    'Hapus',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            confirmDismiss: (direction) async {
                              return await showDialog<bool>(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text('Hapus Tiket'),
                                  content: Text(
                                    'Hapus tiket "${ticket.judul}"? '
                                    'Aksi ini tidak bisa dibatalkan!',
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(context, false),
                                      child: const Text('Batal'),
                                    ),
                                    ElevatedButton(
                                      onPressed: () =>
                                          Navigator.pop(context, true),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.red,
                                        foregroundColor: Colors.white,
                                      ),
                                      child: const Text('Hapus'),
                                    ),
                                  ],
                                ),
                              );
                            },
                            onDismissed: (direction) async {
                              try {
                                await _ticketRepository.deleteTicket(ticket.id);
                                _loadTickets();
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Tiket "${ticket.judul}" dihapus',
                                      ),
                                      backgroundColor: Colors.green,
                                    ),
                                  );
                                }
                              } catch (e) {
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Gagal hapus: ${e.toString()}',
                                      ),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              }
                            },
                            child: _buildTicketCard(ticket),
                          );
                        }

                        return _buildTicketCard(ticket);
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
