import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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

  static const Color tealDark = Color(0xFF145C54);
  static const Color limeGreen = Color(0xFFB8E926);

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
        title: Text(!route.isDelete ? "Hapus Rute?" : "Pulihkan Rute?", style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        content: Text(
          "Apakah Anda yakin ingin ${!route.isDelete ? 'menghapus' : 'memulihkan'} rute '${route.judulRute}'?",
          style: GoogleFonts.poppins(),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text("Batal", style: GoogleFonts.poppins(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: !route.isDelete ? Colors.red : limeGreen,
              foregroundColor: !route.isDelete ? Colors.white : tealDark,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text("Ya, Lanjutkan", style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
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
      return Center(child: Text("Tidak ada data rute tematik.", style: GoogleFonts.poppins(color: Colors.grey)));
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
          elevation: 0,
          color: Colors.white,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: Colors.grey.shade200),
          ),
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
              backgroundColor: !route.isDelete ? limeGreen.withValues(alpha: 0.3) : Colors.grey.shade200,
              child: Icon(Icons.alt_route, color: !route.isDelete ? tealDark : Colors.grey),
            ),
            title: Text(
              route.judulRute,
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                decoration: route.isDelete ? TextDecoration.lineThrough : null,
                color: route.isDelete ? Colors.grey : const Color(0xFF1A1A2E),
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
                  style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
            trailing: IconButton(
              onPressed: () => _handleAction(route),
              icon: Icon(
                !route.isDelete ? Icons.delete_outline : Icons.restore,
                color: !route.isDelete ? Colors.red : tealDark,
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
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          scrolledUnderElevation: 0,
          centerTitle: true,
          title: Text(
            "Kelola Rute",
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1A1A2E),
            ),
          ),
          bottom: TabBar(
            isScrollable: false, 
            labelColor: tealDark,
            unselectedLabelColor: Colors.grey,
            indicatorColor: limeGreen,
            labelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            unselectedLabelStyle: GoogleFonts.poppins(),
            tabs: const [
              Tab(text: "Semua Rute"),
              Tab(text: "History"),
            ],
          ),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator(color: tealDark))
            : TabBarView(
                children: [
                  _buildRouteList(listAktif),
                  _buildRouteList(listHistory),
                ],
              ),
        floatingActionButton: Padding(
          padding: const EdgeInsets.only(bottom: 70), 
          child: FloatingActionButton(
            backgroundColor: tealDark,
            foregroundColor: limeGreen,
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