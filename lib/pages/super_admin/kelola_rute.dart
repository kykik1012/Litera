import 'package:flutter/material.dart';
import 'package:litera/models/thematic_route.dart';
import '../../services/thematic_service.dart'; 
import 'tambah_rute.dart'; 
import 'kelola_detail_rute.dart'; 

import '../../services/route_detail_service.dart'; 
import 'package:litera/models/route_detail.dart'; 

class KelolaRutePage extends StatefulWidget {
  const KelolaRutePage({super.key});

  @override
  State<KelolaRutePage> createState() => _KelolaRutePageState();
}

class _KelolaRutePageState extends State<KelolaRutePage> {
  final ThematicRouteService _routeService = ThematicRouteService();
  // 1. TAMBAHKAN inisialisasi service untuk route detail
  final RouteDetailService _routeDetailService = RouteDetailService();
  
  List<ThematicRouteModel> _allRoutes = [];
  // 2. TAMBAHKAN penampung untuk data route detail
  List<RouteDetailModel> _allRouteDetails = []; 
  
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchRoutes();
  }

  // 3. UBAH fungsi fetch agar mengambil dua API sekaligus
  Future<void> _fetchRoutes() async {
    setState(() => _isLoading = true);
    try {
      // Gunakan Future.wait untuk menjalankan 2 API secara bersamaan
      final responses = await Future.wait([
        _routeService.getAllThematicRoutes(),
        _routeDetailService.getAllRouteDetails(),
      ]);

      final routeResponse = responses[0];
      final detailResponse = responses[1];

      if (routeResponse['success'] == true && detailResponse['success'] == true) {
        final List<dynamic> routeData = routeResponse['data'];
        final List<dynamic> detailData = detailResponse['data'];
        
        setState(() {
          _allRoutes = routeData.map((json) => ThematicRouteModel.fromJson(json)).toList();
          _allRouteDetails = detailData.map((json) => RouteDetailModel.fromJson(json)).toList();
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
      padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 120), 
      itemCount: routes.length,
      itemBuilder: (context, index) {
        final route = routes[index];

        // 4. LOGIKA PENGHITUNGAN DESTINASI: 
        // Hitung berapa banyak detail rute yang thematicRouteId-nya sama dengan id rute ini
        final int jumlahDestinasi = _allRouteDetails
            .where((detail) => detail.thematicRouteId.toString() == route.id)
            .length;

        return Card(
          elevation: 2,
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            onTap: () async {
              // Gunakan await agar jika admin selesai menambah destinasi, halaman ini ter-refresh
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => KelolaRuteDetailPage(
                    thematicRouteId: int.parse(route.id),
                    judulRute: route.judulRute,
                  ),
                ),
              );
              _fetchRoutes(); // Refresh data jika kembali dari detail rute
            },
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
                // 5. UBAH TAMPILAN TEKS DI SINI
                Text(
                  "$jumlahDestinasi Destinasi • ${route.deskripsi}", 
                  maxLines: 2, 
                  overflow: TextOverflow.ellipsis,
                ),
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
    final listAktif = _allRoutes.where((r) => !r.isDelete).toList();
    final listHistory = _allRoutes.where((r) => r.isDelete).toList();

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Kelola Rute"),
          bottom: const TabBar(
            isScrollable: false, 
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
        floatingActionButton: Padding(
          padding: const EdgeInsets.only(bottom: 70), 
          child: FloatingActionButton(
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
            onPressed: () async { 
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const TambahRutePage(), 
                ),
              );

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