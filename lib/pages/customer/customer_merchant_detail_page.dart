import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../models/merchant.dart';
import '../../models/review.dart';
import '../../services/review_service.dart';

// 1. TAMBAHKAN IMPORT MODEL & SERVICE PRODUK
import 'package:litera/models/product.dart'; // Sesuaikan nama file model produkmu jika berbeda
import '../../services/product_service.dart'; // Sesuaikan nama file service produkmu

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
  final ProductService _productService = ProductService(); // 2. INISIALISASI PRODUCT SERVICE
  
  List<ReviewModel> _merchantReviews = [];
  List<ProductModel> _merchantProducts = []; // 3. PENAMPUNG DATA PRODUK
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
    
    // 4. JALANKAN KETIGANYA BERSAMAAN (Alamat, Review, dan Produk)
    await Future.wait([
      _convertCoordsToAddress(),
      _fetchReviews(),
      _fetchProducts(),
    ]);
    
    setState(() => _isLoadingDetails = false);
  }

  // Konversi koordinat menjadi teks alamat
  // --- MENGGUNAKAN API OPENSTREETMAP (NOMINATIM) ---
  Future<void> _convertCoordsToAddress() async {
    if (widget.merchant.latitude == null || widget.merchant.longitude == null) {
      setState(() => _alamatTeks = "Alamat tidak tersedia");
      return;
    }

    try {
      final lat = widget.merchant.latitude!;
      final lon = widget.merchant.longitude!;
      
      // Memanggil API gratis dari OpenStreetMap
      final url = Uri.parse('https://nominatim.openstreetmap.org/reverse?format=json&lat=$lat&lon=$lon');
      
      final response = await http.get(url, headers: {
        // Nominatim mewajibkan kita mengirim User-Agent (Nama aplikasi kita)
        'User-Agent': 'LiteraApp/1.0', 
      });

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        if (data['address'] != null) {
          final address = data['address'];
          
          // Mengambil komponen alamat (Jalan, Kelurahan/Desa, Kota/Kabupaten)
          final jalan = address['road'] ?? address['pedestrian'] ?? '';
          final kelurahan = address['suburb'] ?? address['village'] ?? '';
          final kota = address['city'] ?? address['town'] ?? address['county'] ?? '';
          
          List<String> alamatRapi = [];
          if (jalan.isNotEmpty) alamatRapi.add(jalan);
          if (kelurahan.isNotEmpty) alamatRapi.add(kelurahan);
          if (kota.isNotEmpty) alamatRapi.add(kota);
          
          setState(() {
            // Jika berhasil disusun, tampilkan. Jika tidak, tampilkan nama lengkap dari OSM
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

  // 5. FUNGSI AMBIL PRODUK DARI API
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
      length: 2, // 2 Tab: Produk & Ulasan
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
              Text(
                "Berdiri sejak tahun: ${widget.merchant.tahunBerdiri ?? 'Tidak diketahui'}",
                style: TextStyle(color: limeGreen, fontSize: 13, fontWeight: FontWeight.w500),
              ),
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
            ],
          ),
        ),
      ],
    );
  }

  // --- 6. WIDGET TAB PRODUK DINAMIS ---
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
                // Gambar Produk
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
                
                // Informasi Produk
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
                
                // Tombol Beli / Habis
                ElevatedButton(
                  onPressed: product.isAvailable ? () {} : null, // Nonaktifkan jika isAvailable == false
                  style: ElevatedButton.styleFrom(
                    backgroundColor: darkGreen, 
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey[300], // Warna kalau habis
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
    if (_merchantReviews.isEmpty) {
      return const Center(child: Text("Belum ada ulasan untuk toko ini."));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _merchantReviews.length,
      itemBuilder: (context, index) {
        final review = _merchantReviews[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(review.customerName, style: const TextStyle(fontWeight: FontWeight.bold)),
                    Row(
                      children: List.generate(5, (i) => Icon(
                        i < review.rating ? Icons.star_rounded : Icons.star_border_rounded,
                        color: Colors.amber, size: 16,
                      )),
                    )
                  ],
                ),
                const SizedBox(height: 8),
                Text(review.deskripsi, style: TextStyle(color: Colors.grey[800], fontSize: 13)),
              ],
            ),
          ),
        );
      },
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