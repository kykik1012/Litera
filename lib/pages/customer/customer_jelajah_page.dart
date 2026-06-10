import 'package:flutter/material.dart';
import '../../models/merchant.dart';
import '../../models/thematic_route.dart';
import '../../services/merchant_service.dart';
import '../../services/thematic_service.dart';
import 'customer_route_preview_page.dart';
import 'customer_route_detail_page.dart'; // Import halaman detail rute

class CustomerJelajahPage extends StatefulWidget {
  const CustomerJelajahPage({super.key});

  @override
  State<CustomerJelajahPage> createState() => _CustomerJelajahPageState();
}

class _CustomerJelajahPageState extends State<CustomerJelajahPage> {
  final ThematicRouteService _routeService = ThematicRouteService();
  final MerchantService _merchantService = MerchantService();

  List<ThematicRouteModel> _routes = [];
  List<MerchantModel> _merchants = [];
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
      final responses = await Future.wait([
        _routeService.getAllThematicRoutes(),
        _merchantService.getAllMerchants(),
      ]);

      final routeRes = responses[0];
      final merchantRes = responses[1];

      if (routeRes['success'] == true) {
        final List<dynamic> rData = routeRes['data'];
        _routes = rData.map((e) => ThematicRouteModel.fromJson(e)).where((r) => !r.isDelete).toList();
      }

      if (merchantRes['success'] == true) {
        final List<dynamic> mData = merchantRes['data'];
        _merchants = mData.map((e) => MerchantModel.fromJson(e)).toList();
      }
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

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F8), // Latar belakang abu-abu sangat muda
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 120), // Jarak aman untuk custom navbar
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. BAGIAN HEADER HERO & KARTU UNGGULAN
            _buildHeroSection(),

            const SizedBox(height: 30), // Jarak setelah kartu menonjol

            // 2. BAGIAN SEMUA RUTE TEMATIK
            if (_routes.isNotEmpty) ...[
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0),
                child: Text(
                  "Semua Rute Tematik",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF003D33)),
                ),
              ),
              const SizedBox(height: 12),
              _buildRouteList(),
            ],

            const SizedBox(height: 24),

            // 3. BAGIAN SEMUA MERCHANT
            if (_merchants.isNotEmpty) ...[
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0),
                child: Text(
                  "Eksplorasi Merchant",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF003D33)),
                ),
              ),
              const SizedBox(height: 12),
              _buildMerchantList(),
            ],
          ],
        ),
      ),
    );
  }

  // --- KOMPONEN HEADER HERO ---
  Widget _buildHeroSection() {
    return Stack(
      clipBehavior: Clip.none, // Mengizinkan widget anak meluap dari batas Stack
      children: [
        // Gambar Background dengan Gradient Overlay
        Container(
          height: 250,
          width: double.infinity,
          decoration: const BoxDecoration(
            image: DecorationImage(
              // Placeholder gambar kota/budaya. Bisa diganti NetworkImage jika ada URL dari API
              image: NetworkImage('https://images.unsplash.com/photo-1555899434-94d1368aa7af?ixlib=rb-4.0.3&auto=format&fit=crop&w=800&q=80'),
              fit: BoxFit.cover,
            ),
          ),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  darkGreen.withOpacity(0.9),
                  Colors.transparent,
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 20,
              left: 20,
              right: 20,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.location_on, color: limeGreen, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      "Jember", // Lokasi default yang relevan
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

        // Kartu Hijau Stabilo (Featured) - Posisinya ditarik ke bawah agar memotong batas gambar
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
                          Text("Paling Populer", style: TextStyle(color: limeGreen, fontSize: 10)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  _routes.isNotEmpty ? _routes[0].deskripsi : "Petualangan kuliner terfavorit dengan rating yang bagus",
                  style: TextStyle(color: darkGreen.withOpacity(0.8), fontSize: 12),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
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
                )
              ],
            ),
          ),
        ),
      ],
    );
  }

  // --- KOMPONEN LIST RUTE ---
  Widget _buildRouteList() {
    return ListView.builder(
      physics: const NeverScrollableScrollPhysics(), // Scroll mengikuti SingleChildScrollView luar
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
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Gambar Thumbnail (Placeholder)
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                child: Container(
                  height: 120,
                  width: double.infinity,
                  color: Colors.grey[300],
                  child: const Center(child: Icon(Icons.image, color: Colors.grey, size: 40)),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(route.judulRute, style: TextStyle(color: darkGreen, fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 6),
                    Text(route.deskripsi, style: const TextStyle(color: Colors.grey, fontSize: 12), maxLines: 2, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 12),
                    
                    // Info Row
                    Row(
                      children: [
                        const Icon(Icons.access_time, size: 14, color: Colors.grey),
                        const SizedBox(width: 4),
                        const Text("2-3 jam", style: TextStyle(fontSize: 12, color: Colors.grey)),
                        const SizedBox(width: 12),
                        const Icon(Icons.route, size: 14, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text("${route.panjangRute} km", style: const TextStyle(fontSize: 12, color: Colors.grey)),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Tombol Lihat Detail
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

  // --- KOMPONEN LIST MERCHANT ---
  Widget _buildMerchantList() {
    return ListView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _merchants.length,
      itemBuilder: (context, index) {
        final merchant = _merchants[index];
        return Card(
          elevation: 2,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: ListTile(
            contentPadding: const EdgeInsets.all(12),
            leading: Container(
              height: 50,
              width: 50,
              decoration: BoxDecoration(
                color: darkGreen.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.storefront, color: darkGreen),
            ),
            title: Text(merchant.namaBisnis, style: TextStyle(fontWeight: FontWeight.bold, color: darkGreen)),
            subtitle: Text(
              merchant.deskripsi ?? "Merchant Litera",
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12),
            ),
            trailing: IconButton(
              icon: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
              onPressed: () {
                // TODO: Navigasi ke Halaman Detail Merchant (jika sudah ada)
              },
            ),
          ),
        );
      },
    );
  }
}