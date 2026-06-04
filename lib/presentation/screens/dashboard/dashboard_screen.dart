import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../data/repositories/ticket_repository.dart';
import '../notification/notification_screen.dart';
import '../../../data/repositories/notification_repository.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _authRepository = AuthRepository();
  final _ticketRepository = TicketRepository();
  int _unreadCount = 0;
  final _notificationRepository = NotificationRepository();

  Map<String, dynamic>? _userProfile;
  List<Map<String, dynamic>> _ticketStats = [];
  int _totalTickets = 0;
  bool _isLoading = true;

  String get _userRole {
    final user = Supabase.instance.client.auth.currentUser;
    return user?.userMetadata?['role'] ?? 'user';
  }

  @override
  void initState() {
    super.initState();
    _loadData();
    _loadUnreadCount();
  }

  Future<void> _loadUnreadCount() async {
    try {
      final count = await _notificationRepository.getUnreadCount();
      if (mounted) setState(() => _unreadCount = count);
    } catch (e) {
      // ignore
    }
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final profile = await _authRepository.getCurrentUserProfile();

      List tickets;
      if (_userRole == 'admin') {
        // Admin lihat statistik semua tiket
        tickets = await _ticketRepository.getAllTickets();
      } else if (_userRole == 'helpdesk') {
        // Helpdesk lihat statistik tiket yang di-assign ke dia
        tickets = await _ticketRepository.getAssignedTickets();
      } else {
        // User lihat statistik tiket miliknya
        tickets = await _ticketRepository.getMyTickets();
      }

      // Hitung per status
      final stats = {'open': 0, 'in_progress': 0, 'resolved': 0, 'closed': 0};
      for (final ticket in tickets) {
        final status = ticket.status;
        if (stats.containsKey(status)) {
          stats[status] = stats[status]! + 1;
        }
      }

      setState(() {
        _userProfile = profile;
        _totalTickets = tickets.length;
        _ticketStats = [
          {
            'label': 'Open',
            'count': stats['open'],
            'color': Colors.blue,
            'icon': Icons.fiber_new,
          },
          {
            'label': 'In Progress',
            'count': stats['in_progress'],
            'color': Colors.orange,
            'icon': Icons.sync,
          },
          {
            'label': 'Resolved',
            'count': stats['resolved'],
            'color': Colors.green,
            'icon': Icons.check_circle,
          },
          {
            'label': 'Closed',
            'count': stats['closed'],
            'color': Colors.grey,
            'icon': Icons.cancel,
          },
        ];
      });
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

  Future<void> _logout() async {
    await _authRepository.logout();
    if (mounted) context.go('/login');
  }

  String _getRoleLabel(String role) {
    switch (role) {
      case 'admin':
        return 'Admin';
      case 'helpdesk':
        return 'Helpdesk';
      default:
        return 'User';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        automaticallyImplyLeading: false,
        actions: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined),
                onPressed: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const NotificationScreen(),
                    ),
                  );
                  if (mounted) {
                    final count = await _notificationRepository
                        .getUnreadCount();
                    setState(() => _unreadCount = count);
                  }
                },
              ),
              if (_unreadCount > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '$_unreadCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header Greeting
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF2563EB), Color(0xFF3B82F6)],
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Halo, ${_userProfile?['nama'] ?? 'User'}! 👋',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              _getRoleLabel(_userRole),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Total Tiket
                    const Text(
                      'Ringkasan Tiket',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2563EB).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFF2563EB).withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.confirmation_number_outlined,
                            color: Color(0xFF2563EB),
                            size: 32,
                          ),
                          const SizedBox(width: 16),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '$_totalTickets',
                                style: const TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF2563EB),
                                ),
                              ),
                              const Text(
                                'Total Tiket',
                                style: TextStyle(color: Colors.grey),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Stats Grid
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: 1.5,
                          ),
                      itemCount: _ticketStats.length,
                      itemBuilder: (context, index) {
                        final stat = _ticketStats[index];
                        return Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: (stat['color'] as Color).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: (stat['color'] as Color).withOpacity(0.3),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                stat['icon'] as IconData,
                                color: stat['color'] as Color,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '${stat['count']}',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: stat['color'] as Color,
                                ),
                              ),
                              Text(
                                stat['label'] as String,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 24),

                    // Shortcut ke List Tiket
                    const Text(
                      'Menu',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildMenuCard(
                      icon: Icons.list_alt,
                      title: 'Daftar Tiket',
                      subtitle: _userRole == 'user'
                          ? 'Lihat tiket yang kamu buat'
                          : 'Kelola semua tiket masuk',
                      color: const Color(0xFF2563EB),
                      onTap: () => context.push('/tickets'),
                    ),
                    const SizedBox(height: 12),
                    if (_userRole == 'user')
                      _buildMenuCard(
                        icon: Icons.add_circle_outline,
                        title: 'Buat Tiket Baru',
                        subtitle: 'Laporkan masalah IT baru',
                        color: Colors.green,
                        onTap: () => context.push('/tickets/create'),
                      ),
                    const SizedBox(height: 12),
                    _buildMenuCard(
                      icon: Icons.person_outline,
                      title: 'Profil Saya',
                      subtitle: 'Lihat dan edit profil',
                      color: Colors.purple,
                      onTap: () => context.push('/profile'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildMenuCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
            const Spacer(),
            Icon(Icons.chevron_right, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }
}
