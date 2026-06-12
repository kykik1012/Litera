import 'package:flutter/material.dart';
import '../../models/route_detail.dart';
import '../../services/route_detail_service.dart';

// Import halaman peta navigasi yang sudah kita buat sebelumnya
import 'customer_route_detail_page.dart'; 

class CustomerRoutePreviewPage extends StatefulWidget {
  final int thematicRouteId;
  final String judulRute;
  final String deskripsiRute; // <--- 1. TAMBAHAN VARIABEL BARU

  const CustomerRoutePreviewPage({
    super.key,
    required this.thematicRouteId,
    required this.judulRute,
    required this.deskripsiRute, // <--- PASTIKAN INI REQUIRED
  });

  @override
  State<CustomerRoutePreviewPage> createState() => _CustomerRoutePreviewPageState();
}

class _CustomerRoutePreviewPageState extends State<CustomerRoutePreviewPage> {
  final RouteDetailService _routeDetailService = RouteDetailService();
  List<RouteDetailModel> _routePoints = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchPreviewData();
  }

  Future<void> _fetchPreviewData() async {
    setState(() => _isLoading = true);
    try {
      final response = await _routeDetailService.getAllRouteDetails();
      if (response['success'] == true) {
        final List<dynamic> data = response['data'];
        
        setState(() {
          _routePoints = data
              .map((json) => RouteDetailModel.fromJson(json))
              .where((detail) => detail.thematicRouteId == widget.thematicRouteId)
              .toList();
        });
      }
    } catch (e) {
      debugPrint("Error loading preview: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F8),
      appBar: AppBar(
        backgroundColor: const Color(0xFF003D33), // Hijau Tua Litera
        foregroundColor: Colors.white,
        title: const Text("Detail Perjalanan"),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _routePoints.isEmpty
              ? const Center(child: Text("Belum ada titik lokasi di rute ini."))
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header Info
                    Container(
                      padding: const EdgeInsets.all(20),
                      width: double.infinity,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(24),
                          bottomRight: Radius.circular(24),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.judulRute,
                            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF003D33)),
                          ),
                          const SizedBox(height: 8),
                          
                          // --- 2. TAMPILKAN DESKRIPSI DI SINI ---
                          Text(
                            widget.deskripsiRute,
                            style: TextStyle(fontSize: 14, color: Colors.grey[800], height: 1.4),
                          ),
                          const SizedBox(height: 12),
                          // --------------------------------------

                          Row(
                            children: [
                              const Icon(Icons.location_on, color: Colors.red, size: 16),
                              const SizedBox(width: 4),
                              Text("${_routePoints.length} Destinasi Merchant", style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20),
                      child: Text("Urutan Perjalanan:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                    const SizedBox(height: 8),

                    // List Urutan Toko
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _routePoints.length,
                        itemBuilder: (context, index) {
                          final point = _routePoints[index];
                          return Card(
                            elevation: 0,
                            margin: const EdgeInsets.only(bottom: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(color: Colors.grey.withOpacity(0.2)),
                            ),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: const Color(0xFFAEEA00),
                                child: Text(
                                  "${index + 1}",
                                  style: const TextStyle(color: Color(0xFF003D33), fontWeight: FontWeight.bold),
                                ),
                              ),
                              title: Text(point.namaBisnis, style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: const Text("Titik Persinggahan", style: TextStyle(fontSize: 12)),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
      
      // Tombol Batal & Mulai Rute di area bawah (Bottom Nav)
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))],
        ),
        child: Row(
          children: [
            // Tombol Batal
            Expanded(
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  side: const BorderSide(color: Color(0xFF003D33)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text("Batal", style: TextStyle(color: Color(0xFF003D33), fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(width: 16),
            
            // Tombol Mulai Rute
            Expanded(
              flex: 2, 
              child: ElevatedButton(
                onPressed: _routePoints.isEmpty 
                    ? null 
                    : () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => CustomerRouteDetailPage(
                              thematicRouteId: widget.thematicRouteId,
                              judulRute: widget.judulRute,
                            ),
                          ),
                        );
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF003D33),
                  foregroundColor: const Color(0xFFAEEA00),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text("Mulai Rute", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    SizedBox(width: 8),
                    Icon(Icons.navigation, size: 18),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}