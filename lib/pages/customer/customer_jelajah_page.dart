import 'package:flutter/material.dart';
import '../../models/merchant.dart';
import '../../models/thematic_route.dart';
import '../../services/merchant_service.dart';
import '../../services/thematic_service.dart';
import '../../services/review_service.dart'; // IMPORT REVIEW SERVICE
import 'customer_route_preview_page.dart';
import 'customer_merchant_detail_page.dart';

class CustomerJelajahPage extends StatefulWidget {
  const CustomerJelajahPage({super.key});

  @override
  State<CustomerJelajahPage> createState() => _CustomerJelajahPageState();
}

class _CustomerJelajahPageState extends State<CustomerJelajahPage> {
  final ThematicRouteService _routeService = ThematicRouteService();
  final MerchantService _merchantService = MerchantService();
  final ReviewService _reviewService = ReviewService(); // Inisialisasi Service

  List<ThematicRouteModel> _routes = [];
  List<MerchantModel> _merchants = [];
  
  // VARIABEL PENYIMPAN RATA-RATA RATING
  Map<String, double> _merchantRatings = {}; 
  
  bool _isLoading = true;

  // Warna Utama Tema
  final Color darkGreen = const Color(0xFF003D33);
  final Color limeGreen = const Color(0xFFAEEA00);

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    try {
      // PANGGIL KETIGA API BERSAMAAN
      final responses = await Future.wait([
        _routeService.getAllThematicRoutes(),
        _merchantService.getAllMerchants(),
        _reviewService.getAllReviews(),
      ]);

      final routeRes = responses[0];
      final merchantRes = responses[1];
      final reviewRes = responses[2];

      if (routeRes['success'] == true) {
        final List<dynamic> rData = routeRes['data'];
        _routes = rData
            .map((e) => ThematicRouteModel.fromJson(e))
            .where((r) => !r.isDelete)
            .toList();
      }

      if (merchantRes['success'] == true) {
        final List<dynamic> mData = merchantRes['data'];
        _merchants = mData.map((e) => MerchantModel.fromJson(e)).toList();
      }

      // --- LOGIKA MENGHITUNG RATA-RATA RATING ---
      if (reviewRes['success'] == true) {
        final List<dynamic> reviewData = reviewRes['data'];
        Map<String, List<num>> tempRatings = {};

        // Kumpulkan semua rating berdasarkan nama bisnis
        for (var r in reviewData) {
          // Abaikan jika is_delete bernilai true
          if (r['is_delete'] == true) continue; 

          String namaBisnis = r['nama_bisnis'].toString().toLowerCase(); // Gunakan lowercase agar pencocokan aman
          num rating = r['rating'];

          if (!tempRatings.containsKey(namaBisnis)) {
            tempRatings[namaBisnis] = [];
          }
          tempRatings[namaBisnis]!.add(rating);
        }

        // Hitung rata-ratanya
        Map<String, double> finalAverages = {};
        tempRatings.forEach((key, listRating) {
          double sum = listRating.fold(0, (prev, element) => prev + element);
          double average = sum / listRating.length;
          finalAverages[key] = average;
        });

        _merchantRatings = finalAverages;
      }
      // -------------------------------------------

    } catch (e) {
      debugPrint("Error loading jelajah data: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return DefaultTabController(
      length: 2, 
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F7F8),
        appBar: AppBar(
          backgroundColor: darkGreen,
          elevation: 0,
          toolbarHeight: 0, 
          bottom: TabBar(
            labelColor: limeGreen,
            unselectedLabelColor: Colors.white70,
            indicatorColor: limeGreen,
            indicatorWeight: 3,
            tabs: const [
              Tab(text: "Rute Tematik"),
              Tab(text: "Merchant"),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // TAB 1: RUTE
            SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 120),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeroSection(),
                  const SizedBox(height: 110), 
                  if (_routes.isNotEmpty) _buildRouteList(),
                ],
              ),
            ),

            // TAB 2: MERCHANT
            SingleChildScrollView(
              padding: const EdgeInsets.only(top: 16, bottom: 120),
              child: _buildMerchantList(),
            ),
          ],
        ),
      ),
    );
  }

  // --- KOMPONEN HEADER HERO ---
  Widget _buildHeroSection() {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          height: 250,
          width: double.infinity,
          decoration: BoxDecoration(
            color: darkGreen, // DIPERBARUI: Warna dasar jika tidak ada gambar rute
            image: _routes.isNotEmpty && _routes[0].imageUrl != null && _routes[0].imageUrl!.isNotEmpty
                ? DecorationImage(
                    image: NetworkImage(_routes[0].imageUrl!),
                    fit: BoxFit.cover,
                  )
                : null, // DIPERBARUI: Tidak lagi menggunakan gambar acak dari internet
          ),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [darkGreen.withOpacity(0.9), Colors.transparent],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            padding: const EdgeInsets.only(top: 20, left: 20, right: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.location_on, color: limeGreen, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      "Jember",
                      style: TextStyle(color: limeGreen, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  "Jelajahi Rute",
                  style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                const Text(
                  "Pilih petualangan budaya yang ingin\nkamu ikuti",
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
        ),

        Positioned(
          top: 180,
          left: 16,
          right: 16,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [limeGreen, const Color(0xFF8BC34A)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 5)),
              ],
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _routes.isNotEmpty ? _routes[0].judulRute : "Rute Populer",
                      style: TextStyle(color: darkGreen, fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: darkGreen,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.star, color: Colors.amber, size: 12),
                          const SizedBox(width: 4),
                          Text(
                            "Paling Populer",
                            style: TextStyle(color: limeGreen, fontSize: 10),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton(
                    onPressed: () {
                      if (_routes.isNotEmpty) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => CustomerRoutePreviewPage(
                              thematicRouteId: int.parse(_routes[0].id),
                              judulRute: _routes[0].judulRute,
                              // DIPERBARUI: Pastikan mengirimkan deskripsiRute jika di customer_route_preview_page.dart menjadikannya required
                              deskripsiRute: _routes[0].deskripsi, 
                            ),
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: darkGreen,
                      foregroundColor: limeGreen,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    ),
                    child: const Text("Mulai Sekarang", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // --- KOMPONEN LIST RUTE DENGAN GAMBAR ---
  Widget _buildRouteList() {
    return ListView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _routes.length,
      itemBuilder: (context, index) {
        final route = _routes[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                child: route.imageUrl != null && route.imageUrl!.isNotEmpty
                    ? Image.network(
                        route.imageUrl!,
                        height: 120,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          height: 120,
                          width: double.infinity,
                          color: limeGreen.withOpacity(0.2), // DIPERBARUI: Warna fallback lebih menyatu
                          child: Icon(Icons.broken_image, color: darkGreen, size: 40),
                        ),
                      )
                    : Container(
                        height: 120,
                        width: double.infinity,
                        color: limeGreen.withOpacity(0.2), // DIPERBARUI: Tampilan placeholder lebih cantik
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.alt_route, color: darkGreen, size: 40),
                              const SizedBox(height: 4),
                              Text("Rute Litera", style: TextStyle(color: darkGreen, fontSize: 12, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      route.judulRute,
                      style: TextStyle(color: darkGreen, fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => CustomerRoutePreviewPage(
                                thematicRouteId: int.parse(route.id),
                                judulRute: route.judulRute,
                                // DIPERBARUI: Pastikan mengirimkan deskripsiRute
                                deskripsiRute: route.deskripsi, 
                              ),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: limeGreen,
                          foregroundColor: darkGreen,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: const Text("Lihat Detail Rute", style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // --- KOMPONEN LIST MERCHANT (DENGAN RATA-RATA RATING) ---
  Widget _buildMerchantList() {
    if (_merchants.isEmpty) {
      return const Center(child: Text("Belum ada data merchant."));
    }
    
    return ListView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _merchants.length,
      itemBuilder: (context, index) {
        final merchant = _merchants[index];
        
        // AMBIL RATA-RATA RATING UNTUK TOKO INI
        double avgRating = _merchantRatings[merchant.namaBisnis.toLowerCase()] ?? 0.0;
        // Format agar hanya menampilkan 1 angka di belakang koma (misal: 4.5). Jika 0, tampilkan 0.0
        String displayRating = avgRating.toStringAsFixed(1);

        return GestureDetector(
          onTap: () {
            // --- PINDAH KE HALAMAN DETAIL BARU ---
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => CustomerMerchantDetailPage(
                  merchant: merchant, // Mengirim objek data merchant lengkap
                ),
              ),
            );
          },
          child: Card(
            elevation: 2,
            margin: const EdgeInsets.only(bottom: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Row(
              children: [
                // 1. Bagian Foto Merchant (Kiri)
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    bottomLeft: Radius.circular(16),
                  ),
                  child: merchant.profilePicture != null && merchant.profilePicture!.isNotEmpty
                      ? Image.network(
                          merchant.profilePicture!,
                          height: 110,
                          width: 110,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Container(
                            height: 110,
                            width: 110,
                            color: Colors.grey[200],
                            child: Icon(Icons.storefront, color: Colors.grey[400], size: 40),
                          ),
                        )
                      : Container(
                          height: 110,
                          width: 110,
                          color: Colors.grey[200],
                          child: Icon(Icons.storefront, color: Colors.grey[400], size: 40),
                        ),
                ),
                
                // 2. Bagian Detail Teks Merchant (Kanan)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          merchant.namaBisnis,
                          style: TextStyle(
                            fontWeight: FontWeight.bold, 
                            fontSize: 16, 
                            color: darkGreen,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          merchant.deskripsi ?? "Toko / Merchant Litera",
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        const SizedBox(height: 12),
                        
                        // Rating & Ikon Panah
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.star, color: Colors.amber, size: 14),
                                const SizedBox(width: 4),
                                Text(
                                  displayRating, 
                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: darkGreen),
                                ),
                                const SizedBox(width: 8),

                                // --- TAMBAHAN BARU: BADGE STATUS MERCHANT ---
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: merchant.status.toLowerCase() == 'buka' ? Colors.green : Colors.red,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    merchant.status.toUpperCase(),
                                    style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
                                  ),
                                ),
                                // --------------------------------------------
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: limeGreen.withOpacity(0.3),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(Icons.arrow_forward_ios, size: 10, color: darkGreen),
                            ),
                          ],
                        )
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}