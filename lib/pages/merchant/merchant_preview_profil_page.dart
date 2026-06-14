import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../models/merchant.dart';
import '../../models/review.dart';
import '../../services/review_service.dart';
import 'package:litera/models/product.dart'; 
import '../../services/product_service.dart'; 
import 'package:google_fonts/google_fonts.dart'; // IMPORT GOOGLE FONTS 

class MerchantPreviewProfilPage extends StatefulWidget {
  final MerchantModel merchant;

  const MerchantPreviewProfilPage({
    super.key,
    required this.merchant,
  });

  @override
  State<MerchantPreviewProfilPage> createState() => _MerchantPreviewProfilPageState();
}

class _MerchantPreviewProfilPageState extends State<MerchantPreviewProfilPage> {
  final ReviewService _reviewService = ReviewService();
  final ProductService _productService = ProductService(); 
  
  List<ReviewModel> _merchantReviews = [];
  List<ProductModel> _merchantProducts = []; 
  String _alamatTeks = "Memuat alamat...";
  bool _isLoadingDetails = true;

  // Custom Tab State
  int _selectedTab = 0; // 0: Katalog, 1: Ulasan

  // Warna Tema
  final Color darkGreen = const Color(0xFF003D33);
  final Color limeGreen = const Color(0xFFAEEA00);
  final Color lightGreyBg = const Color(0xFFF5F7F8);

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

  // --- METRIK ULASAN ---
  double get _averageRating {
    if (_merchantReviews.isEmpty) return 0;
    final total = _merchantReviews.fold<double>(0, (sum, r) => sum + r.rating.toDouble());
    return total / _merchantReviews.length;
  }

  Map<int, int> get _ratingDistribution {
    final dist = {5: 0, 4: 0, 3: 0, 2: 0, 1: 0};
    for (final review in _merchantReviews) {
      final star = review.rating.toInt().clamp(1, 5);
      dist[star] = (dist[star] ?? 0) + 1;
    }
    return dist;
  }

  int get _photoReviewCount {
    return _merchantReviews.where((r) => r.imageUrl != null && r.imageUrl!.isNotEmpty).length;
  }

  Map<String, String> get _usahaDimulai {
    if (widget.merchant.usahaDidirikan != null && widget.merchant.usahaDidirikan!.isNotEmpty) {
      try {
        final parsedDate = DateTime.tryParse(widget.merchant.usahaDidirikan!);
        if (parsedDate != null) {
          const months = ["", "Januari", "Februari", "Maret", "April", "Mei", "Juni", "Juli", "Agustus", "September", "Oktober", "November", "Desember"];
          return {
            'tanggal': parsedDate.day.toString(),
            'bulan': (parsedDate.month >= 1 && parsedDate.month <= 12) ? months[parsedDate.month] : "-",
            'tahun': parsedDate.year.toString(),
          };
        }
      } catch (_) {}
    }
    return {'tanggal': '-', 'bulan': '-', 'tahun': widget.merchant.usahaDidirikan ?? '-'};
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingDetails) {
      return Scaffold(
        backgroundColor: lightGreyBg,
        body: Center(child: CircularProgressIndicator(color: limeGreen)),
      );
    }

    return Scaffold(
      backgroundColor: lightGreyBg,
      body: Stack(
        children: [
          // Scrollable Body
          SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeaderImage(),
                _buildWhiteBodyContainer(),
              ],
            ),
          ),
          
          // AppBar Melayang
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.merchant.namaBisnis,
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
          

        ],
      ),
    );
  }

  // --- HEADER GAMBAR ---
  Widget _buildHeaderImage() {
    return Stack(
      children: [
        SizedBox(
          height: 250,
          width: double.infinity,
          child: widget.merchant.imageUrl != null && widget.merchant.imageUrl!.isNotEmpty
              ? Image.network(widget.merchant.imageUrl!, fit: BoxFit.cover)
              : Container(color: darkGreen),
        ),
        // Efek gradient agar tulisan AppBar terbaca
        Container(
          height: 100,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.black.withOpacity(0.7), Colors.transparent],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
      ],
    );
  }

  // --- BODY PUTIH (OVERLAPPING) ---
  Widget _buildWhiteBodyContainer() {
    return Transform.translate(
      offset: const Offset(0, -30),
      child: Container(
        decoration: BoxDecoration(
          color: lightGreyBg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 24),
            _buildRatingSummary(),
            const SizedBox(height: 20),
            _buildAddressSection(),
            const SizedBox(height: 24),
            _buildOperasionalSection(),
            const SizedBox(height: 24),
            _buildUsahaDimulaiSection(),
            const SizedBox(height: 24),
            _buildKisahUsahaSection(),
            const SizedBox(height: 24),
            _buildCustomTabSwitcher(),
            const SizedBox(height: 16),
            
            // Konten Dinamis Tab
            _selectedTab == 0 ? _buildKatalogContent() : _buildUlasanContent(),
          ],
        ),
      ),
    );
  }

  // --- KOMPONEN INFORMASI MERCHANT ---
  Widget _buildRatingSummary() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: const Color(0xFFF4F9EB), // Hijau muda cerah
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.star, color: limeGreen, size: 24),
                const SizedBox(width: 8),
                Text(_averageRating.toStringAsFixed(1), style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.bold, color: darkGreen)),
                const SizedBox(width: 12),
                Text("${_merchantReviews.length} ulasan", style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey[700])),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: List.generate(5, (index) {
                return Icon(
                  index < _averageRating.round() ? Icons.star : Icons.star_border,
                  color: limeGreen,
                  size: 20,
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddressSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.location_on_outlined, size: 16, color: darkGreen),
              const SizedBox(width: 8),
              Text("Alamat", style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: darkGreen, fontSize: 13)),
            ],
          ),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.only(left: 24),
            child: Text(
              _alamatTeks,
              style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[700], height: 1.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOperasionalSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Jadwal Operasional", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Buka", style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.grey.shade200)),
                      child: Center(child: Text(widget.merchant.jamBuka ?? "09:00", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 13))),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Tutup", style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.grey.shade200)),
                      child: Center(child: Text(widget.merchant.jamTutup ?? "21:00", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 13))),
                    ),
                  ],
                ),
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildUsahaDimulaiSection() {
    final mulai = _usahaDimulai;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Usaha Dimulai Sejak", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: Column(
                  children: [
                    Text("Tanggal", style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.grey.shade200)),
                      child: Center(child: Text(mulai['tanggal']!, style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 11))),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 3,
                child: Column(
                  children: [
                    Text("Bulan", style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.grey.shade200)),
                      child: Center(child: Text(mulai['bulan']!, style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 11))),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: Column(
                  children: [
                    Text("Tahun", style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.grey.shade200)),
                      child: Center(child: Text(mulai['tahun']!, style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 11))),
                    ),
                  ],
                ),
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildKisahUsahaSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Kisah Usaha", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87)),
          const SizedBox(height: 8),
          Text(
            widget.merchant.deskripsi ?? "Belum ada kisah usaha untuk merchant ini.",
            style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[700], height: 1.6),
          ),
        ],
      ),
    );
  }

  // --- CUSTOM TAB SWITCHER ---
  Widget _buildCustomTabSwitcher() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: Colors.grey.shade200),
        ),
        padding: const EdgeInsets.all(4),
        child: Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _selectedTab = 0),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: _selectedTab == 0 ? limeGreen : Colors.transparent,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.inventory_2, size: 16, color: _selectedTab == 0 ? darkGreen : Colors.grey[600]),
                      const SizedBox(width: 8),
                      Text("Katalog", style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        color: _selectedTab == 0 ? darkGreen : Colors.grey[600],
                        fontSize: 13,
                      )),
                    ],
                  ),
                ),
              ),
            ),
            Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _selectedTab = 1),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: _selectedTab == 1 ? limeGreen : Colors.transparent,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.rate_review_outlined, size: 16, color: _selectedTab == 1 ? darkGreen : Colors.grey[600]),
                      const SizedBox(width: 8),
                      Text("Ulasan", style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        color: _selectedTab == 1 ? darkGreen : Colors.grey[600],
                        fontSize: 13,
                      )),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- KONTEN KATALOG ---
  Widget _buildKatalogContent() {
    if (_merchantProducts.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Text("Belum ada produk.", style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey)),
      );
    }
    return ListView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      itemCount: _merchantProducts.length,
      itemBuilder: (context, index) {
        final product = _merchantProducts[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFFDF8FD), // Warna pink sangat cerah/soft
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.pink.shade50),
          ),
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 60, height: 60,
                decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(12)),
                child: product.imageUrl != null && product.imageUrl!.isNotEmpty
                    ? ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.network(product.imageUrl!, fit: BoxFit.cover))
                    : const Icon(Icons.fastfood, color: Colors.grey),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(product.namaProduk, style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87)),
                    Text(product.deskripsi, style: GoogleFonts.poppins(fontSize: 10, color: Colors.grey.shade500), maxLines: 1, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 6),
                    Text("Rp ${product.hargaProduk}", style: GoogleFonts.poppins(color: Colors.orange.shade400, fontWeight: FontWeight.bold, fontSize: 12)),
                  ],
                ),
              ),

            ],
          ),
        );
      },
    );
  }

  // --- KONTEN ULASAN ---
  Widget _buildUlasanContent() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Statistik Baris
          Row(
            children: [

              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(color: const Color(0xFFF4F9EB), borderRadius: BorderRadius.circular(16)),
                  child: Column(
                    children: [
                      Text("$_photoReviewCount", style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: darkGreen)),
                      Text("Foto", style: GoogleFonts.poppins(fontSize: 10, color: Colors.grey[700])),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(color: const Color(0xFFF4F9EB), borderRadius: BorderRadius.circular(16)),
                  child: Column(
                    children: [
                      Text(_averageRating.toStringAsFixed(1), style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: darkGreen)),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(5, (index) => Icon(Icons.star, color: limeGreen, size: 8)),
                      ),
                      Text("Rating", style: GoogleFonts.poppins(fontSize: 10, color: Colors.grey[700])),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Foto Kunjungan
          if (_photoReviewCount > 0) ...[
            Row(
              children: [
                const Icon(Icons.camera_alt_outlined, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                Text("Foto Kunjungan", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 13, color: darkGreen)),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 80,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _merchantReviews.where((r) => r.imageUrl != null && r.imageUrl!.isNotEmpty).length,
                itemBuilder: (context, index) {
                  final review = _merchantReviews.where((r) => r.imageUrl != null && r.imageUrl!.isNotEmpty).toList()[index];
                  return Container(
                    margin: const EdgeInsets.only(right: 12),
                    width: 80,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      image: DecorationImage(image: NetworkImage(review.imageUrl!), fit: BoxFit.cover),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),
          ],

          // Distribusi Rating
          Row(
            children: [
              const Icon(Icons.star_border, size: 16, color: Colors.grey),
              const SizedBox(width: 8),
              Text("Distribusi Rating", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 13, color: darkGreen)),
            ],
          ),
          const SizedBox(height: 12),
          _buildRatingDistribution(),
          
          const SizedBox(height: 24),
          
          // Ulasan Pengunjung
          Row(
            children: [
              const Icon(Icons.chat_bubble_outline, size: 16, color: Colors.grey),
              const SizedBox(width: 8),
              Text("Ulasan Pengunjung (${_merchantReviews.length})", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 13, color: darkGreen)),
            ],
          ),
          const SizedBox(height: 16),
          _buildUlasanList(),
          
          if (_merchantReviews.isNotEmpty) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () {},
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  side: BorderSide(color: Colors.grey.shade300),
                ),
                child: Text("Lihat Semua ${_merchantReviews.length} Ulasan", style: GoogleFonts.poppins(color: Colors.grey.shade600, fontWeight: FontWeight.bold, fontSize: 12)),
              ),
            )
          ]
        ],
      ),
    );
  }

  Widget _buildRatingDistribution() {
    final dist = _ratingDistribution;
    final maxCount = _merchantReviews.isEmpty ? 1 : _merchantReviews.length;

    return Column(
      children: [5, 4, 3, 2, 1].map((star) {
        final count = dist[star] ?? 0;
        final ratio = count / maxCount;
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              Text("$star", style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey[600])),
              const SizedBox(width: 4),
              Icon(Icons.star, color: limeGreen, size: 10),
              const SizedBox(width: 8),
              Expanded(
                child: Stack(
                  children: [
                    Container(height: 6, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(3))),
                    FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: ratio,
                      child: Container(height: 6, decoration: BoxDecoration(color: limeGreen, borderRadius: BorderRadius.circular(3))),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 20,
                child: Text("$count", textAlign: TextAlign.right, style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey[600])),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildUlasanList() {
    if (_merchantReviews.isEmpty) {
      return Text("Belum ada ulasan.", style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey));
    }
    
    return ListView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: _merchantReviews.length > 5 ? 5 : _merchantReviews.length,
      itemBuilder: (context, index) {
        final review = _merchantReviews[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 20),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                backgroundColor: darkGreen,
                radius: 16,
                child: Text(review.customerName.isNotEmpty ? review.customerName[0].toUpperCase() : "?", style: const TextStyle(color: Colors.white, fontSize: 12)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(review.customerName, style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 12, color: darkGreen)),
                    const SizedBox(height: 2),
                    Row(
                      children: List.generate(5, (i) => Icon(i < review.rating ? Icons.star : Icons.star_border, color: limeGreen, size: 12)),
                    ),
                    const SizedBox(height: 8),
                    Text(review.deskripsi, style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey[700], height: 1.5)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.thumb_up_outlined, size: 12, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Text("Membantu (0)", style: GoogleFonts.poppins(fontSize: 10, color: Colors.grey[600])),
                      ],
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


}