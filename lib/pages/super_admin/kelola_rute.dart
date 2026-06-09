import 'package:flutter/material.dart';
import 'package:litera/models/thematic_route.dart';
import '../../services/thematic_service.dart'; // Sesuaikan penamaan file service kamu
import 'tambah_rute.dart'; // Import halaman tambah rute

class KelolaRutePage extends StatefulWidget {
  const KelolaRutePage({super.key});

  @override
  State<KelolaRutePage> createState() => _KelolaRutePageState();
}

class _KelolaRutePageState extends State<KelolaRutePage> {
  final ThematicRouteService _routeService = ThematicRouteService();
  
  List<ThematicRouteModel> _allRoutes = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchRoutes();
  }

  Future<void> _fetchRoutes() async {
    setState(() => _isLoading = true);
    try {
      final response = await _routeService.getAllThematicRoutes();
      if (response['success'] == true) {
        final List<dynamic> data = response['data'];
        setState(() {
          _allRoutes = data.map((json) => ThematicRouteModel.fromJson(json)).toList();
        });
      }
    } catch (e) {
      debugPrint(e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // Handle Delete / Restore
  Future<void> _handleAction(ThematicRouteModel route) async {
    bool confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(!route.isDelete ? "Hapus Rute?" : "Pulihkan Rute?"),
        content: Text("Apakah Anda yakin ingin ${!route.isDelete ? 'menghapus' : 'memulihkan'} rute '${route.judulRute}'?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Batal", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: !route.isDelete ? Colors.red : Colors.green,
            ),
            child: const Text("Ya, Lanjutkan", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    ) ?? false;

    if (!confirm) return;

    try {
      if (!route.isDelete) {
        await _routeService.deleteThematicRoute(route.id);
      } else {
        await _routeService.restoreThematicRoute(route.id);
      }
      _fetchRoutes();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Berhasil mengubah status rute!")));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Terjadi kesalahan: $e")));
    }
  }

  Widget _buildRouteList(List<ThematicRouteModel> routes) {
    if (routes.isEmpty) {
      return const Center(child: Text("Tidak ada data rute tematik."));
    }

    return ListView.builder(
      padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 120), // Padding bawah agar tidak tertutup navbar
      itemCount: routes.length,
      itemBuilder: (context, index) {
        final route = routes[index];

        return Card(
          elevation: 2,
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: !route.isDelete ? Colors.green : Colors.grey,
              child: const Icon(Icons.alt_route, color: Colors.white),
            ),
            title: Text(
              route.judulRute,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                decoration: route.isDelete ? TextDecoration.lineThrough : null,
                color: route.isDelete ? Colors.grey : Colors.black,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("${route.panjangRute} km • ${route.deskripsi}", maxLines: 2, overflow: TextOverflow.ellipsis),
              ],
            ),
            trailing: IconButton(
              onPressed: () => _handleAction(route),
              icon: Icon(
                !route.isDelete ? Icons.delete_outline : Icons.restore,
                color: !route.isDelete ? Colors.red : Colors.green,
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // isDelete: false berarti rute Aktif, isDelete: true berarti History
    final listAktif = _allRoutes.where((r) => !r.isDelete).toList();
    final listHistory = _allRoutes.where((r) => r.isDelete).toList();

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Kelola Rute"),
          bottom: const TabBar(
            isScrollable: false, // Dibagi rata
            labelColor: Colors.green,
            unselectedLabelColor: Colors.grey,
            indicatorColor: Colors.green,
            tabs: [
              Tab(text: "Semua Rute"),
              Tab(text: "History"),
            ],
          ),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
                children: [
                  _buildRouteList(listAktif),
                  _buildRouteList(listHistory),
                ],
              ),
        // Tombol melayang untuk menambah rute baru
        floatingActionButton: Padding(
          padding: const EdgeInsets.only(bottom: 70), // Naikkan sedikit agar tidak tabrakan dengan custom navbar
          child: FloatingActionButton(
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
            onPressed: () async { // 1. Arahkan ke halaman Tambah Rute dan tunggu hasilnya (karena kita melempar Navigator.pop(context, true) jika sukses)
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const TambahRutePage(), // Import file tambah_rute.dart di atas!
                ),
              );

              // 2. Jika result bernilai true (artinya rute berhasil ditambahkan), Refresh data!
              if (result == true) {
                _fetchRoutes();
              }
            },
            child: const Icon(Icons.add),
          ),
        ),
      ),
    );
  }
}