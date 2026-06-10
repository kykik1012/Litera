import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart'; // Tambahkan ini untuk LatLng
import 'package:litera/models/merchant.dart';
import 'package:litera/models/thematic_route.dart';

import '../../services/merchant_service.dart';
import '../../services/thematic_service.dart';
import '../../services/route_detail_service.dart'; // Tambahkan ini

// Import halaman detail rute (sesuaikan path-nya jika berbeda)
import 'customer_route_detail_page.dart'; 

class SearchResultsPage extends StatefulWidget {
  final String query;

  const SearchResultsPage({
    super.key,
    required this.query,
  });

  @override
  State<SearchResultsPage> createState() => _SearchResultsPageState();
}

class _SearchResultsPageState extends State<SearchResultsPage> {
  final MerchantService _merchantService = MerchantService();
  final ThematicRouteService _routeService = ThematicRouteService();

  List<ThematicRouteModel> _filteredRoutes = [];
  List<MerchantModel> _filteredMerchants = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _performSearch();
  }

  Future<void> _performSearch() async {
    setState(() => _isLoading = true);
    try {
      // Panggil kedua API secara bersamaan
      final responses = await Future.wait([
        _routeService.getAllThematicRoutes(),
        _merchantService.getAllMerchants(),
      ]);

      final routeResponse = responses[0];
      final merchantResponse = responses[1];

      final String keyword = widget.query.toLowerCase();

      // Filter Data Rute
      if (routeResponse['success'] == true) {
        final List<dynamic> rData = routeResponse['data'];
        _filteredRoutes = rData
            .map((e) => ThematicRouteModel.fromJson(e))
            .where((rute) => 
                !rute.isDelete && // Hanya rute aktif
                (rute.judulRute.toLowerCase().contains(keyword) || 
                 rute.deskripsi.toLowerCase().contains(keyword)))
            .toList();
      }

      // Filter Data Merchant
      if (merchantResponse['success'] == true) {
        final List<dynamic> mData = merchantResponse['data'];
        _filteredMerchants = mData
            .map((e) => MerchantModel.fromJson(e))
            .where((merchant) => 
                merchant.namaBisnis.toLowerCase().contains(keyword))
            .toList();
      }

    } catch (e) {
      debugPrint("Error searching data: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // --- WIDGET LIST RUTE ---
  Widget _buildRouteList() {
    if (_filteredRoutes.isEmpty) {
      return Center(child: Text("Tidak ada rute tematik dengan kata '${widget.query}'"));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _filteredRoutes.length,
      itemBuilder: (context, index) {
        final route = _filteredRoutes[index];
        return Card(
          elevation: 2,
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: const CircleAvatar(
              backgroundColor: Color(0xFF003D33),
              child: Icon(Icons.alt_route, color: Colors.white),
            ),
            title: Text(route.judulRute, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(
              "${route.panjangRute ?? 0} km • ${route.deskripsi}",
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: const Icon(Icons.chevron_right),
            // --- UBAH ONTAP RUTE ---
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CustomerRouteDetailPage(
                    thematicRouteId: int.parse(route.id),
                    judulRute: route.judulRute,
                  ),
                ),
              );
            },
            // ------------------------
          ),
        );
      },
    );
  }

  // --- WIDGET LIST MERCHANT ---
  Widget _buildMerchantList() {
    if (_filteredMerchants.isEmpty) {
      return Center(child: Text("Tidak ada toko dengan nama '${widget.query}'"));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _filteredMerchants.length,
      itemBuilder: (context, index) {
        final merchant = _filteredMerchants[index];
        return Card(
          elevation: 2,
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: const CircleAvatar(
              backgroundColor: Color(0xFFAEEA00),
              child: Icon(Icons.storefront, color: Color(0xFF003D33)),
            ),
            title: Text(merchant.namaBisnis, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(merchant.deskripsi ?? "Toko / Merchant Litera"),
            trailing: const Icon(Icons.chevron_right),
            // --- UBAH ONTAP MERCHANT ---
            onTap: () async {
              // Tampilkan dialog loading
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) => const Center(child: CircularProgressIndicator(color: Colors.green)),
              );

              try {
                final response = await RouteDetailService().getAllRouteDetails();
                if (!mounted) return;
                Navigator.pop(context); // Tutup loading

                if (response['success'] == true) {
                  final List<dynamic> details = response['data'];
                  
                  // Cari data rute yang mengaitkan merchant ini
                  final match = details.firstWhere(
                    (d) => d['merchant_id'].toString() == merchant.id,
                    orElse: () => null,
                  );

                  if (match != null) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CustomerRouteDetailPage(
                          thematicRouteId: match['thematic_route_id'],
                          judulRute: match['judul_rute'] ?? "Rute Merchant",
                          focusLocation: LatLng(merchant.latitude!.toDouble(), merchant.longitude!.toDouble()),
                        ),
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Merchant ini belum terdaftar di rute tematik manapun.")),
                    );
                  }
                }
              } catch (e) {
                if (mounted) Navigator.pop(context);
                debugPrint(e.toString());
              }
            },
            // ---------------------------
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: const Color(0xFF003D33), // Hijau Tua
          foregroundColor: Colors.white,
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Hasil Pencarian", style: TextStyle(fontSize: 16)),
              Text(
                "Kata kunci: '${widget.query}'",
                style: const TextStyle(fontSize: 12, color: Colors.white70, fontWeight: FontWeight.normal),
              ),
            ],
          ),
          bottom: const TabBar(
            labelColor: Color(0xFFAEEA00), // Hijau Stabilo
            unselectedLabelColor: Colors.white54,
            indicatorColor: Color(0xFFAEEA00),
            tabs: [
              Tab(text: "Rute Tematik"),
              Tab(text: "Toko / Merchant"),
            ],
          ),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
                children: [
                  _buildRouteList(),
                  _buildMerchantList(),
                ],
              ),
      ),
    );
  }
}