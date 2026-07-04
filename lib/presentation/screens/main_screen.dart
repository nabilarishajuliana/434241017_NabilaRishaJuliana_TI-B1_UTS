import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dashboard/dashboard_screen.dart';
import 'ticket/list_ticket_screen.dart';
import 'history/history_screen.dart';
import 'tracking/tracking_ticket_screen.dart';
import 'profile/profile_screen.dart';
import '../../core/utils/user_role_helper.dart';

class MainScreen extends StatefulWidget {
  final int initialIndex;
  const MainScreen({super.key, this.initialIndex = 0});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  late int _currentIndex;

  // String get _userRole {
  //   final user = Supabase.instance.client.auth.currentUser;
  //   return user?.userMetadata?['role'] ?? 'user';
  // }

  String _userRole = 'user';

  @override
  void initState() {
    super.initState();
    _loadRole();
    _currentIndex = widget.initialIndex;
  }

  Future<void> _loadRole() async {
    final role = await UserRoleHelper.getRole();
    if (mounted) setState(() => _userRole = role);
  }

  List<Widget> get _screens => [
    const DashboardScreen(),
    const ListTicketScreen(),
    const HistoryScreen(),
    const TrackingTicketScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() => _currentIndex = index);
        },
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: const Icon(Icons.confirmation_number_outlined),
            selectedIcon: const Icon(Icons.confirmation_number),
            label: _userRole == 'user' ? 'Tiket Saya' : 'Semua Tiket',
          ),
          const NavigationDestination(
            icon: Icon(Icons.history_outlined),
            selectedIcon: Icon(Icons.history),
            label: 'Riwayat',
          ),
          const NavigationDestination(
            icon: Icon(Icons.track_changes_outlined),
            selectedIcon: Icon(Icons.track_changes),
            label: 'Tracking',
          ),
          const NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profil',
          ),
        ],
      ),
    );
  }
}
