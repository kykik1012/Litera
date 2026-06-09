import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../../services/user_service.dart';

class KelolaAkunPage extends StatefulWidget {
  const KelolaAkunPage({super.key});

  @override
  State<KelolaAkunPage> createState() => _KelolaAkunPageState();
}

class _KelolaAkunPageState extends State<KelolaAkunPage> {
  final UserService _userService = UserService();
  
  List<UserModel> _allUsers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchUsers();
  }

  // Mengambil data dari API
  Future<void> _fetchUsers() async {
    setState(() => _isLoading = true);
    try {
      final response = await _userService.getAllUsers();
      if (response['success'] == true) {
        final List<dynamic> data = response['data'];
        setState(() {
          // Menyaring data agar tidak menampilkan akun Super Admin itu sendiri (jika role = 3)
          _allUsers = data
              .map((json) => UserModel.fromJson(json))
              .where((user) => user.role != 3) 
              .toList();
        });
      }
    } catch (e) {
      debugPrint(e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // Menangani aksi Delete atau Restore
  Future<void> _handleAction(UserModel user) async {
    // Tampilkan konfirmasi dialog
    bool confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(user.isActive ? "Nonaktifkan Akun?" : "Pulihkan Akun?"),
        content: Text(
            "Apakah Anda yakin ingin ${user.isActive ? 'menghapus/menonaktifkan' : 'memulihkan'} akun ${user.name ?? user.namaBisnis ?? user.username}?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Batal", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: user.isActive ? Colors.red : Colors.green,
            ),
            child: const Text("Ya, Lanjutkan", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    ) ?? false;

    if (!confirm) return;

    // Eksekusi API
    try {
      if (user.isActive) {
        await _userService.deleteUser(user.id);
      } else {
        await _userService.restoreUser(user.id);
      }
      
      // Refresh data setelah aksi berhasil
      _fetchUsers();
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Berhasil mengubah status akun!")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Terjadi kesalahan: $e")),
      );
    }
  }

  // Widget untuk menggambar List berdasarkan role yang difilter
  Widget _buildUserList(List<UserModel> users) {
    if (users.isEmpty) {
      return const Center(child: Text("Tidak ada data pengguna."));
    }

    return ListView.builder(
      // PERBAIKAN NAVBAR: Tambahkan padding bottom 120 agar item terakhir bisa di-scroll ke atas navbar
      padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 120),
      itemCount: users.length,
      itemBuilder: (context, index) {
        final user = users[index];
        // Prioritaskan nama, jika tidak ada pakai nama bisnis, jika tidak ada pakai username
        final displayName = user.name ?? user.namaBisnis ?? user.username ?? "Unknown";

        return Card(
          elevation: 2,
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: user.role == 1 ? Colors.orange : Colors.blue,
              child: Icon(
                user.role == 1 ? Icons.store : Icons.person,
                color: Colors.white,
              ),
            ),
            title: Text(
              displayName,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                decoration: !user.isActive ? TextDecoration.lineThrough : null, // Coret nama jika dihapus
                color: !user.isActive ? Colors.grey : Colors.black,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(user.email),
                const SizedBox(height: 4),
                // Badge Status
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: user.isActive ? Colors.green.withValues(alpha: 0.2) : Colors.red.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    user.isActive ? "Aktif" : "Dinonaktifkan",
                    style: TextStyle(
                      fontSize: 12,
                      color: user.isActive ? Colors.green[800] : Colors.red[800],
                    ),
                  ),
                ),
              ],
            ),
            trailing: IconButton(
              onPressed: () => _handleAction(user),
              icon: Icon(
                user.isActive ? Icons.delete_outline : Icons.restore,
                color: user.isActive ? Colors.red : Colors.green,
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // 1. Tab Semua (Hanya yang masih aktif)
    final listSemuaAktif = _allUsers.where((u) => u.isActive).toList();
    
    // 2. Tab Customer (Role 2 dan Aktif)
    final listCustomer = _allUsers.where((u) => u.role == 2 && u.isActive).toList();
    
    // 3. Tab Merchant (Role 1 dan Aktif)
    final listMerchant = _allUsers.where((u) => u.role == 1 && u.isActive).toList();
    
    // 4. Tab History (Semua akun yang di-soft delete / tidak aktif)
    final listHistory = _allUsers.where((u) => !u.isActive).toList();

    return DefaultTabController(
      length: 4, // Jumlah Tab diubah menjadi 4
      child: Scaffold(
        appBar: AppBar(
        title: const Text("Kelola Akun"),
        bottom: const TabBar(
          // Hapus atau jadikan isScrollable false agar ke-4 tab terbagi rata memenuhi layar
          isScrollable: false, 
          
          labelColor: Colors.green,
          unselectedLabelColor: Colors.grey,
          indicatorColor: Colors.green,
          // Opsional: Beri padding vertikal agar area sentuh tab lebih nyaman
          padding: EdgeInsets.zero, 
          indicatorSize: TabBarIndicatorSize.tab, // Agar garis hijau di bawah tab membentang penuh
          tabs: [
            Tab(text: "Semua"),
            Tab(text: "Customer"),
            Tab(text: "Merchant"),
            Tab(text: "History"),
          ],
        ),
      ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
                children: [
                  _buildUserList(listSemuaAktif), // Tab 1: Semua Aktif
                  _buildUserList(listCustomer),   // Tab 2: Customer Aktif
                  _buildUserList(listMerchant),   // Tab 3: Merchant Aktif
                  _buildUserList(listHistory),    // Tab 4: History / Terhapus
                ],
              ),
      ),
    );
  }
}