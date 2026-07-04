import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../data/repositories/auth_repository.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  final _authRepository = AuthRepository();
  List<Map<String, dynamic>> _users = [];
  List<Map<String, dynamic>> _filteredUsers = [];
  bool _isLoading = true;
  String _selectedFilter = 'all';

  final List<Map<String, String>> _filters = [
    {'value': 'all', 'label': 'Semua'},
    {'value': 'user', 'label': 'User'},
    {'value': 'helpdesk', 'label': 'Helpdesk'},
    {'value': 'admin', 'label': 'Admin'},
  ];

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() => _isLoading = true);
    try {
      final users = await _authRepository.getAllUsers();
      setState(() {
        _users = users;
        _applyFilter(_selectedFilter);
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

  void _applyFilter(String filter) {
    setState(() {
      _selectedFilter = filter;
      if (filter == 'all') {
        _filteredUsers = _users;
      } else {
        _filteredUsers = _users
            .where((user) => user['role'] == filter)
            .toList();
      }
    });
  }

  void _showToggleUserDialog(Map<String, dynamic> user) {
    final isActive = user['is_active'] ?? true;
    final nama = user['nama'] ?? 'User';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isActive ? 'Non-aktifkan Pengguna' : 'Aktifkan Pengguna'),
        content: Text(
          isActive
              ? 'Apakah kamu yakin ingin menonaktifkan akun $nama? Pengguna tidak akan bisa login.'
              : 'Apakah kamu yakin ingin mengaktifkan kembali akun $nama?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _toggleUserActive(user, !isActive);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: isActive ? Colors.red : Colors.green,
              foregroundColor: Colors.white,
            ),
            child: Text(isActive ? 'Non-aktifkan' : 'Aktifkan'),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleUserActive(
    Map<String, dynamic> user,
    bool isActive,
  ) async {
    try {
      await _authRepository.toggleUserActive(
        userId: user['id'],
        isActive: isActive,
      );
      await _loadUsers();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isActive
                  ? '${user['nama']} berhasil diaktifkan'
                  : '${user['nama']} berhasil dinonaktifkan',
            ),
            backgroundColor: isActive ? Colors.green : Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showChangeRoleDialog(Map<String, dynamic> user) {
    String selectedRole = user['role'] ?? 'user';
    final nama = user['nama'] ?? 'User';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Ubah Role Pengguna'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Pilih role baru untuk $nama:',
                style: TextStyle(color: Colors.grey.shade600),
              ),
              const SizedBox(height: 16),

              // Radio: User
              RadioListTile<String>(
                value: 'user',
                groupValue: selectedRole,
                onChanged: (value) {
                  setDialogState(() => selectedRole = value!);
                },
                title: const Text('User'),
                subtitle: const Text(
                  'Bisa buat tiket dan komentar',
                  style: TextStyle(fontSize: 12),
                ),
                activeColor: Colors.blue,
              ),

              // Radio: Helpdesk
              RadioListTile<String>(
                value: 'helpdesk',
                groupValue: selectedRole,
                onChanged: (value) {
                  setDialogState(() => selectedRole = value!);
                },
                title: const Text('Helpdesk'),
                subtitle: const Text(
                  'Menangani tiket yang di-assign',
                  style: TextStyle(fontSize: 12),
                ),
                activeColor: Colors.orange,
              ),

              // Radio: Admin
              RadioListTile<String>(
                value: 'admin',
                groupValue: selectedRole,
                onChanged: (value) {
                  setDialogState(() => selectedRole = value!);
                },
                title: const Text('Admin'),
                subtitle: const Text(
                  'Akses penuh ke semua fitur',
                  style: TextStyle(fontSize: 12),
                ),
                activeColor: Colors.red,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () async {
                // Kalau role sama, tidak perlu update
                if (selectedRole == user['role']) {
                  Navigator.pop(context);
                  return;
                }

                Navigator.pop(context);
                await _updateUserRole(user, selectedRole);
              },
              child: const Text('Simpan'),
            ),
          ],
        ),
      ),
    );
  }

  //UPDATE ROLE
  Future<void> _updateUserRole(
    Map<String, dynamic> user,
    String newRole,
  ) async {
    try {
      await _authRepository.updateUserRole(
        userId: user['id'],
        newRole: newRole,
      );
      await _loadUsers();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Role ${user['nama']} diubah menjadi ${_getRoleLabel(newRole)}. '
              'User perlu logout dan login ulang agar role baru aktif.',
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal ubah role: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Color _getRoleColor(String role) {
    switch (role) {
      case 'admin':
        return Colors.red;
      case 'helpdesk':
        return Colors.orange;
      default:
        return Colors.blue;
    }
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
    // Cek apakah user yang login adalah admin
    final currentUser = Supabase.instance.client.auth.currentUser;
    final currentUserId = currentUser?.id;

    return Scaffold(
      appBar: AppBar(title: const Text('Kelola Pengguna')),
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

          // Jumlah user
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                Text(
                  '${_filteredUsers.length} pengguna',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                ),
              ],
            ),
          ),

          // List User
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredUsers.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.people_outline,
                          size: 80,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Tidak ada pengguna',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _loadUsers,
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _filteredUsers.length,
                      itemBuilder: (context, index) {
                        final user = _filteredUsers[index];
                        final isActive = user['is_active'] ?? true;
                        final isCurrentUser = user['id'] == currentUserId;
                        final role = user['role'] ?? 'user';

                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                // Avatar
                                Stack(
                                  children: [
                                    CircleAvatar(
                                      radius: 24,
                                      backgroundColor: isActive
                                          ? _getRoleColor(role).withOpacity(0.2)
                                          : Colors.grey.shade300,
                                      child: Text(
                                        (user['nama'] ?? 'U')[0].toUpperCase(),
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: isActive
                                              ? _getRoleColor(role)
                                              : Colors.grey,
                                        ),
                                      ),
                                    ),
                                    if (!isActive)
                                      Positioned(
                                        right: 0,
                                        bottom: 0,
                                        child: Container(
                                          width: 14,
                                          height: 14,
                                          decoration: const BoxDecoration(
                                            color: Colors.red,
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(
                                            Icons.close,
                                            color: Colors.white,
                                            size: 10,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(width: 12),

                                // Info User
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Text(
                                            user['nama'] ?? '-',
                                            style: TextStyle(
                                              fontWeight: FontWeight.w600,
                                              color: isActive
                                                  ? null
                                                  : Colors.grey,
                                            ),
                                          ),
                                          if (isCurrentUser) ...[
                                            const SizedBox(width: 6),
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 6,
                                                    vertical: 2,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: Colors.green.withOpacity(
                                                  0.15,
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(4),
                                              ),
                                              child: const Text(
                                                'Kamu',
                                                style: TextStyle(
                                                  fontSize: 10,
                                                  color: Colors.green,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        user['email'] ?? '-',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Row(
                                        children: [
                                          // Badge Role
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 3,
                                            ),
                                            decoration: BoxDecoration(
                                              color: _getRoleColor(
                                                role,
                                              ).withOpacity(0.15),
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              _getRoleLabel(role),
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: _getRoleColor(role),
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          // Badge Status
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 3,
                                            ),
                                            decoration: BoxDecoration(
                                              color: isActive
                                                  ? Colors.green.withOpacity(
                                                      0.15,
                                                    )
                                                  : Colors.red.withOpacity(
                                                      0.15,
                                                    ),
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              isActive ? 'Aktif' : 'Non-aktif',
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: isActive
                                                    ? Colors.green
                                                    : Colors.red,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),

                                // Tombol aksi (kalau bukan user yang sedang login)
                                if (!isCurrentUser)
                                  PopupMenuButton<String>(
                                    icon: Icon(
                                      Icons.more_vert,
                                      color: Colors.grey.shade600,
                                    ),
                                    onSelected: (value) {
                                      if (value == 'change_role') {
                                        _showChangeRoleDialog(user);
                                      } else if (value == 'toggle_active') {
                                        _showToggleUserDialog(user);
                                      }
                                    },
                                    itemBuilder: (context) => [
                                      const PopupMenuItem(
                                        value: 'change_role',
                                        child: Row(
                                          children: [
                                            Icon(
                                              Icons.badge_outlined,
                                              size: 18,
                                            ),
                                            SizedBox(width: 12),
                                            Text('Ubah Role'),
                                          ],
                                        ),
                                      ),
                                      PopupMenuItem(
                                        value: 'toggle_active',
                                        child: Row(
                                          children: [
                                            Icon(
                                              isActive
                                                  ? Icons.person_off_outlined
                                                  : Icons.person_outline,
                                              size: 18,
                                              color: isActive
                                                  ? Colors.red
                                                  : Colors.green,
                                            ),
                                            const SizedBox(width: 12),
                                            Text(
                                              isActive
                                                  ? 'Non-aktifkan'
                                                  : 'Aktifkan',
                                              style: TextStyle(
                                                color: isActive
                                                    ? Colors.red
                                                    : Colors.green,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
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
