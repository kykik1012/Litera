import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../models/merchant.dart';
import '../../models/review.dart';
import '../../services/review_service.dart';
import 'package:litera/models/product.dart'; 
import '../../services/product_service.dart'; 
import 'customer_single_route_page.dart';
import 'package:intl/intl.dart';

// --- 1. TAMBAHKAN IMPORT HALAMAN FORM ULASAN ---
import 'customer_add_review_page.dart'; 

class CustomerMerchantDetailPage extends StatefulWidget {
  final MerchantModel merchant;

  const CustomerMerchantDetailPage({
    super.key,
    required this.merchant,
  });

  @override
  State<CustomerMerchantDetailPage> createState() => _CustomerMerchantDetailPageState();
}

class _CustomerMerchantDetailPageState extends State<CustomerMerchantDetailPage> {
  final ReviewService _reviewService = ReviewService();
  final ProductService _productService = ProductService(); 
  
  List<ReviewModel> _merchantReviews = [];
  List<ProductModel> _merchantProducts = []; 
  String _alamatTeks = "Memuat alamat...";
  bool _isLoadingDetails = true;

  // Warna Tema
  final Color darkGreen = const Color(0xFF003D33);
  final Color limeGreen = const Color(0xFFAEEA00);

  @override
  void initState() {
    super.initState();
    _loadAllDetails();
  }

  Future<void> _loadAllDetails() async {
    setState(() => _isLoadingDetails = true);
    
    await Future.wait([
      _convertCoordsToAddress(),
      _fetchReviews(),
      _fetchProducts(),
    ]);
    
    setState(() => _isLoadingDetails = false);
  }

  // --- MENGGUNAKAN API OPENSTREETMAP (NOMINATIM) ---
  Future<void> _convertCoordsToAddress() async {
    if (widget.merchant.latitude == null || widget.merchant.longitude == null) {
      setState(() => _alamatTeks = "Alamat tidak tersedia");
      return;
    }

    try {
      final lat = widget.merchant.latitude!;
      final lon = widget.merchant.longitude!;
      
      final url = Uri.parse('https://nominatim.openstreetmap.org/reverse?format=json&lat=$lat&lon=$lon');
      
      final response = await http.get(url, headers: {
        'User-Agent': 'LiteraApp/1.0', 
      });

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        if (data['address'] != null) {
          final address = data['address'];
          
          final jalan = address['road'] ?? address['pedestrian'] ?? '';
          final kelurahan = address['suburb'] ?? address['village'] ?? '';
          final kota = address['city'] ?? address['town'] ?? address['county'] ?? '';
          
          List<String> alamatRapi = [];
          if (jalan.isNotEmpty) alamatRapi.add(jalan);
          if (kelurahan.isNotEmpty) alamatRapi.add(kelurahan);
          if (kota.isNotEmpty) alamatRapi.add(kota);
          
          setState(() {
            _alamatTeks = alamatRapi.isNotEmpty ? alamatRapi.join(', ') : (data['display_name'] ?? 'Alamat ditemukan');
          });
        } else {
          setState(() => _alamatTeks = "Detail jalan tidak ditemukan");
        }
      } else {
        setState(() => _alamatTeks = "Gagal mengambil alamat dari server");
      }
    } catch (e) {
      debugPrint("Gagal konversi alamat OSM: $e");
      setState(() => _alamatTeks = "Terjadi kesalahan jaringan");
    }
  }

  // Ambil Ulasan
  Future<void> _fetchReviews() async {
    try {
      final response = await _reviewService.getAllReviews();
      if (response['success'] == true) {
        final List<dynamic> data = response['data'];
        _merchantReviews = data
            .map((json) => ReviewModel.fromJson(json))
            .where((review) => 
                !review.isDelete && 
                review.namaBisnis.toLowerCase() == widget.merchant.namaBisnis.toLowerCase())
            .toList();
      }
    } catch (e) {
      debugPrint("Error loading reviews: $e");
    }
  }

  // FUNGSI AMBIL PRODUK DARI API
  Future<void> _fetchProducts() async {
    try {
      final response = await _productService.getAllProducts();
      if (response['success'] == true) {
        final List<dynamic> data = response['data'];
        _merchantProducts = data
            .map((json) => ProductModel.fromJson(json))
            .where((product) => 
                product.namaBisnis.toLowerCase() == widget.merchant.namaBisnis.toLowerCase())
            .toList();
      }
    } catch (e) {
      debugPrint("Error loading products: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2, 
      child: Scaffold(
        body: NestedScrollView(
          headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
            return <Widget>[
              // HERO SECTION
              SliverAppBar(
                expandedHeight: 340.0,
                floating: false,
                pinned: true,
                backgroundColor: darkGreen,
                foregroundColor: Colors.white,
                flexibleSpace: FlexibleSpaceBar(
                  collapseMode: CollapseMode.pin,
                  background: _buildHeroHeader(),
                ),
              ),
              
              // SUB TAB
              SliverPersistentHeader(
                pinned: true,
                delegate: _SliverAppBarDelegate(
                  TabBar(
                    labelColor: darkGreen,
                    unselectedLabelColor: Colors.grey,
                    indicatorColor: darkGreen,
                    indicatorWeight: 3,
                    tabs: const [
                      Tab(text: "Produk Kami"),
                      Tab(text: "Ulasan Pembeli"),
                    ],
                  ),
                ),
              ),
            ];
          },
          
          body: _isLoadingDetails
              ? const Center(child: CircularProgressIndicator())
              : TabBarView(
                  children: [
                    _buildProductTab(),
                    _buildReviewTab(),
                  ],
                ),
        ),
      ),
    );
  }

  // --- WIDGET HERO HEADER ---
  Widget _buildHeroHeader() {
    // ========================================================
    // LOGIKA VARIABEL DIPINDAHKAN KE SINI (DI ATAS RETURN)
    // ========================================================
    String tanggalBerdiri = "Tidak diketahui";
    if (widget.merchant.usahaDidirikan != null) {
      tanggalBerdiri = DateFormat('dd MMMM yyyy', 'id_ID').format(widget.merchant.usahaDidirikan!);
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        widget.merchant.profilePicture != null && widget.merchant.profilePicture!.isNotEmpty
            ? Image.network(widget.merchant.profilePicture!, fit: BoxFit.cover)
            : Container(color: darkGreen),
            
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.black.withOpacity(0.7), Colors.transparent, Colors.black.withOpacity(0.8)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
        
        Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.merchant.namaBisnis,
                style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              
              // ========================================================
              // TAMPILAN WIDGET TANGGAL & JAM OPERASIONAL
              // ========================================================
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Berdiri sejak: $tanggalBerdiri",
                    style: const TextStyle(color: Colors.amber, fontSize: 12),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.access_time, color: Colors.white70, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        "Jam Operasional: ${widget.merchant.jamBuka ?? '-'} s.d ${widget.merchant.jamTutup ?? '-'}",
                        style: const TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ), // <--- Koma ini sebelumnya terlewat
              
              const Divider(color: Colors.white24, height: 20),
              
              Text(
                widget.merchant.deskripsi ?? "Merchant Litera terpercaya dengan produk kualitas terbaik.",
                style: const TextStyle(color: Colors.white70, fontSize: 13),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.location_on, color: Colors.red, size: 16),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      _alamatTeks,
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20), 
                    
              // --- TOMBOL RUTE ---
              SizedBox(
                width: double.infinity, 
                child: ElevatedButton.icon(
                  onPressed: () {
                    if (widget.merchant.latitude != null && widget.merchant.longitude != null) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CustomerSingleRoutePage(
                            merchant: widget.merchant, 
                          ),
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Lokasi merchant ini belum diatur oleh Admin.")),
                      );
                    }
                  },
                  icon: const Icon(Icons.navigation, size: 20),
                  label: const Text(
                    "Lihat Rute Lokasi",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFAEEA00), 
                    foregroundColor: const Color(0xFF003D33), 
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // --- WIDGET TAB PRODUK ---
  Widget _buildProductTab() {
    if (_merchantProducts.isEmpty) {
      return const Center(child: Text("Belum ada produk untuk toko ini."));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _merchantProducts.length,
      itemBuilder: (context, index) {
        final product = _merchantProducts[index];
        return Card(
          elevation: 1,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: product.imageUrl != null && product.imageUrl!.isNotEmpty
                      ? Image.network(
                          product.imageUrl!,
                          width: 70, height: 70, fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Container(
                            width: 70, height: 70, color: Colors.grey[200],
                            child: Icon(Icons.fastfood, color: darkGreen),
                          ),
                        )
                      : Container(
                          width: 70, height: 70, color: Colors.grey[200],
                          child: Icon(Icons.fastfood, color: darkGreen),
                        ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(product.namaProduk, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      const SizedBox(height: 4),
                      Text(
                        product.deskripsi, 
                        maxLines: 1, 
                        overflow: TextOverflow.ellipsis, 
                        style: const TextStyle(fontSize: 12, color: Colors.grey)
                      ),
                      const SizedBox(height: 4),
                      Text("Rp ${product.hargaProduk}", style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                ElevatedButton(
                  onPressed: product.isAvailable ? () {} : null, 
                  style: ElevatedButton.styleFrom(
                    backgroundColor: darkGreen, 
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey[300], 
                  ),
                  child: Text(product.isAvailable ? "Beli" : "Habis"),
                )
              ],
            ),
          ),
        );
      },
    );
  }

  // --- WIDGET TAB ULASAN ---
  Widget _buildReviewTab() {
    return Column(
      children: [
        // Tombol Tambah Ulasan di Header
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          color: Colors.white,
          child: OutlinedButton.icon(
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CustomerAddReviewPage(merchant: widget.merchant),
                ),
              );

              if (result == true) {
                setState(() => _isLoadingDetails = true);
                await _fetchReviews();
                setState(() => _isLoadingDetails = false);
              }
            },
            icon: Icon(Icons.edit, color: darkGreen),
            label: Text("Tulis Ulasan", style: TextStyle(color: darkGreen, fontWeight: FontWeight.bold)),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
              side: BorderSide(color: darkGreen),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),

        // List Ulasan Pembeli
        Expanded(
          child: _merchantReviews.isEmpty
              ? const Center(child: Text("Belum ada ulasan untuk toko ini. Jadilah yang pertama!"))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _merchantReviews.length,
                  itemBuilder: (context, index) {
                    final review = _merchantReviews[index];
                    return Card(
                      elevation: 1,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      margin: const EdgeInsets.only(bottom: 16),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 14,
                                      backgroundColor: limeGreen.withOpacity(0.3),
                                      child: Text(
                                        review.customerName.isNotEmpty ? review.customerName[0].toUpperCase() : '?',
                                        style: TextStyle(color: darkGreen, fontWeight: FontWeight.bold, fontSize: 12),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      review.customerName, 
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                    ),
                                  ],
                                ),
                                Row(
                                  children: List.generate(5, (i) => Icon(
                                    i < review.rating ? Icons.star_rounded : Icons.star_border_rounded,
                                    color: Colors.amber, 
                                    size: 16,
                                  )),
                                )
                              ],
                            ),
                            
                            const SizedBox(height: 12),
                            Text(
                              review.deskripsi, 
                              style: TextStyle(color: Colors.grey[800], fontSize: 13, height: 1.4),
                            ),
                            
                            // Bagian Foto Ulasan
                            if (review.imageUrl != null && review.imageUrl!.isNotEmpty) ...[
                              const SizedBox(height: 12),
                              GestureDetector(
                                onTap: () {
                                  showDialog(
                                    context: context,
                                    builder: (BuildContext context) {
                                      return Dialog(
                                        backgroundColor: Colors.transparent,
                                        insetPadding: EdgeInsets.zero, 
                                        child: Stack(
                                          alignment: Alignment.center,
                                          children: [
                                            Container(
                                              width: double.infinity,
                                              height: double.infinity,
                                              color: Colors.black87,
                                            ),
                                            InteractiveViewer(
                                              panEnabled: true,
                                              minScale: 0.5,
                                              maxScale: 4.0, 
                                              child: Image.network(
                                                review.imageUrl!,
                                                fit: BoxFit.contain,
                                                width: double.infinity,
                                                height: double.infinity,
                                              ),
                                            ),
                                            Positioned(
                                              top: 40,
                                              right: 20,
                                              child: IconButton(
                                                icon: const Icon(Icons.close, color: Colors.white, size: 32),
                                                onPressed: () => Navigator.of(context).pop(),
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  );
                                },
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.network(
                                    review.imageUrl!,
                                    width: double.infinity,
                                    height: 150,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) => Container(
                                      width: double.infinity,
                                      height: 150,
                                      color: Colors.grey[200],
                                      child: const Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.broken_image, color: Colors.grey),
                                          SizedBox(height: 4),
                                          Text("Gambar tidak tersedia", style: TextStyle(color: Colors.grey, fontSize: 12))
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                            
                            if (review.submittedAt != null) ...[
                              const SizedBox(height: 12),
                              Text(
                                "${review.submittedAt!.day}/${review.submittedAt!.month}/${review.submittedAt!.year}",
                                style: const TextStyle(color: Colors.grey, fontSize: 10),
                              ),
                            ]
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

// Helper Class untuk menangani TabBar yang menempel di atas (Sticky)
class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  _SliverAppBarDelegate(this._tabBar);
  final TabBar _tabBar;

  @override get minExtent => _tabBar.preferredSize.height;
  @override get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(color: Colors.white, child: _tabBar);
  }
  @override bool shouldRebuild(_SliverAppBarDelegate oldDelegate) => false;
}