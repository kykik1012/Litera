import 'package:flutter/material.dart';
import '../../models/route_detail.dart';
import '../../models/merchant.dart'; // <--- TAMBAHAN IMPORT MODEL
import '../../services/route_detail_service.dart';
import '../../services/merchant_service.dart'; // <--- TAMBAHAN IMPORT SERVICE

import 'customer_route_detail_page.dart'; 

class CustomerRoutePreviewPage extends StatefulWidget {
  final int thematicRouteId;
  final String judulRute;
  final String deskripsiRute;

  const CustomerRoutePreviewPage({
    super.key,
    required this.thematicRouteId,
    required this.judulRute,
    required this.deskripsiRute,
  });

  @override
  State<CustomerRoutePreviewPage> createState() => _CustomerRoutePreviewPageState();
}

class _CustomerRoutePreviewPageState extends State<CustomerRoutePreviewPage> {
  final RouteDetailService _routeDetailService = RouteDetailService();
  final MerchantService _merchantService = MerchantService(); // Tambahan service

  List<RouteDetailModel> _routePoints = [];
  List<MerchantModel> _allMerchants = []; // Tambahan penyimpan data merchant
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchPreviewData();
  }

  Future<void> _fetchPreviewData() async {
    setState(() => _isLoading = true);
    try {
      // Panggil API Route Details dan API Merchants SECARA BERSAMAAN
      final responses = await Future.wait([
        _routeDetailService.getAllRouteDetails(),
        _merchantService.getAllMerchants(),
      ]);

      // Ekstrak data Rute
      if (responses[0]['success'] == true) {
        final List<dynamic> data = responses[0]['data'];
        _routePoints = data
            .map((json) => RouteDetailModel.fromJson(json))
            .where((detail) => detail.thematicRouteId == widget.thematicRouteId)
            .toList();
      }

      // Ekstrak data Merchant
      if (responses[1]['success'] == true) {
        final List<dynamic> mData = responses[1]['data'];
        _allMerchants = mData.map((e) => MerchantModel.fromJson(e)).toList();
      }

    } catch (e) {
      debugPrint("Error loading preview: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // --- FUNGSI HELPER: Mencari status merchant berdasarkan nama bisnis ---
  String _getMerchantStatus(String namaBisnis) {
    try {
      final merchant = _allMerchants.firstWhere(
        (m) => m.namaBisnis.toLowerCase() == namaBisnis.toLowerCase(),
      );
      return merchant.status;
    } catch (_) {
      return 'Tutup'; // Jika toko tidak ditemukan, asumsikan Tutup
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F8),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D3B2E),
        elevation: 0,
        toolbarHeight: 0,
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
                      padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
                      width: double.infinity,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFF0D3B2E), Color(0xFF1A8A7A)],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                        borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(30),
                          bottomRight: Radius.circular(30),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              GestureDetector(
                                onTap: () => Navigator.pop(context),
                                child: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
                              ),
                              const SizedBox(width: 16),
                              const Text(
                                "Detail Perjalanan",
                                style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          Text(
                            widget.judulRute,
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFFAEEA00)),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            widget.deskripsiRute,
                            style: const TextStyle(fontSize: 13, color: Colors.white70, height: 1.4),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              const Icon(Icons.location_on, color: Color(0xFFAEEA00), size: 16),
                              const SizedBox(width: 6),
                              Text("${_routePoints.length} Destinasi Merchant", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 24),
                      child: Text("Urutan Perjalanan:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                    const SizedBox(height: 12),

                    // List Urutan Toko
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _routePoints.length,
                        itemBuilder: (context, index) {
                          final point = _routePoints[index];
                          
                          // --- CEK STATUS BUKA/TUTUP ---
                          final status = _getMerchantStatus(point.namaBisnis);
                          final isBuka = status.toLowerCase() == 'buka';

                          return Card(
                            elevation: 0,
                            margin: const EdgeInsets.only(bottom: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(color: Colors.grey.withOpacity(0.2)),
                            ),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: isBuka ? const Color(0xFFAEEA00) : Colors.grey[300],
                                child: Text(
                                  "${index + 1}",
                                  style: TextStyle(
                                    color: isBuka ? const Color(0xFF003D33) : Colors.grey[600], 
                                    fontWeight: FontWeight.bold
                                  ),
                                ),
                              ),
                              title: Text(
                                point.namaBisnis, 
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: isBuka ? Colors.black : Colors.grey,
                                  decoration: isBuka ? null : TextDecoration.lineThrough, // Coret jika tutup
                                )
                              ),
                              subtitle: Row(
                                children: [
                                  const Text("Titik Persinggahan", style: TextStyle(fontSize: 12)),
                                  const SizedBox(width: 8),
                                  // --- BADGE BUKA/TUTUP ---
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: isBuka ? Colors.green : Colors.red,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      isBuka ? "Buka" : "Tutup", 
                                      style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
      
      // Tombol Batal & Mulai Rute
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))],
        ),
        child: Row(
          children: [
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
            
            // TOMBOL MULAI RUTE DENGAN LOGIKA SKIP
            Expanded(
              flex: 2, 
              child: ElevatedButton(
                onPressed: _routePoints.isEmpty 
                    ? null 
                    : () {
                        // 1. Kumpulkan Merchant yang sedang 'Buka' saja
                        final ruteBuka = _routePoints.where(
                          (p) => _getMerchantStatus(p.namaBisnis).toLowerCase() == 'buka'
                        ).toList();

                        // 2. Jika semua rute tutup, tampilkan peringatan dan BLOKIR navigasi!
                        if (ruteBuka.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Merchant sedang tutup. Rute tidak dapat diakses hari ini."),
                              backgroundColor: Colors.red,
                              duration: Duration(seconds: 3),
                            ),
                          );
                          return;
                        }

                        // 3. Jika ada yang buka, beri tahu pengguna bahwa yang tutup akan diskip
                        if (ruteBuka.length < _routePoints.length) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Beberapa merchant tutup dan otomatis dilewati dari navigasi."),
                              backgroundColor: Colors.orange,
                              duration: Duration(seconds: 3),
                            ),
                          );
                        }

                        // 4. Lanjutkan Navigasi
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