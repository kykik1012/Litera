import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../helpers/shared_pref_helper.dart';
import '../../services/user_service.dart';
import '../../services/product_service.dart';
import '../../services/merchant_service.dart';
import '../../models/product.dart';
import 'merchant_edit_katalog_page.dart';
import 'package:qr_flutter/qr_flutter.dart';

// --- IMPORT HALAMAN BARU ---
import 'merchant_kelola_promo.dart';

class MerchantDashboardPage extends StatefulWidget {
  const MerchantDashboardPage({super.key});

  @override
  State<MerchantDashboardPage> createState() => _MerchantDashboardPageState();
}

class _MerchantDashboardPageState extends State<MerchantDashboardPage> {
  final UserService _userService = UserService();
  final ProductService _productService = ProductService();
  final MerchantService _merchantService = MerchantService();

  String _namaBisnis = '';
  String? _profilePicture;
  String _merchantId = '';
  List<ProductModel> _products = [];
  
  bool _isLoading = true;
  bool _isTokoActive = false; 
  bool _isLoadingStatus = false; 

  static const Color tealDark = Color(0xFF0D3B2E);
  static const Color tealMid = Color(0xFF145C54);
  static const Color tealGradientEnd = Color(0xFF1A8A7A);
  static const Color promoCardColor = Color(0xFF1E6E5E);
  static const Color limeGreen = Color(0xFFAEEA00);

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    await _loadMerchantProfile();
    await _loadProducts();
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _loadMerchantProfile() async {
    try {
      final userId = await SharedPrefHelper.getUserId() ?? 0;
      if (userId == 0) return;
      
      final merchantRes = await _merchantService.getAllMerchants();
      if (merchantRes['success'] == true) {
        final List<dynamic> mList = merchantRes['data'];
        final myMerchant = mList.firstWhere(
          (m) => m['user_id'].toString() == userId.toString(),
          orElse: () => null,
        );
        
        if (myMerchant != null) {
          _namaBisnis = myMerchant["nama_bisnis"] ?? '';
          _profilePicture = myMerchant["profile_picture"];
          _merchantId = myMerchant['id'].toString();
          _isTokoActive = (myMerchant['status']?.toString().toLowerCase() == 'buka'); 

          if (myMerchant['nama_bisnis'] != null && myMerchant['nama_bisnis'].toString().isNotEmpty) {
            _namaBisnis = myMerchant['nama_bisnis'].toString();
          }

          if (myMerchant['profile_picture'] != null && myMerchant['profile_picture'].toString().isNotEmpty) {
             _profilePicture = myMerchant['profile_picture'].toString();
          } else if (myMerchant['image_url'] != null && myMerchant['image_url'].toString().isNotEmpty) {
             _profilePicture = myMerchant['image_url'].toString();
          }
        }
      }
    } catch (e) {
      debugPrint("Error loading merchant profile: $e");
    }
  }

  Future<void> _loadProducts() async {
    try {
      final response = await _productService.getAllProducts();
      if (response["success"] == true && response["data"] != null) {
        final List data = response["data"];
        final allProducts = data.map((json) => ProductModel.fromJson(json)).toList();
        
        if (_namaBisnis.isNotEmpty) {
          _products = allProducts
              .where((p) => p.namaBisnis.toLowerCase() == _namaBisnis.toLowerCase())
              .toList();
        } else {
          _products = [];
        }
      }
    } catch (e) {
      debugPrint("Error loading products: $e");
    }
  }

  Future<void> _toggleStatus(bool value) async {
    if (_merchantId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Data toko belum siap. Coba refresh halaman.")),
      );
      return;
    }

    setState(() => _isLoadingStatus = true);
    String statusBaru = value ? "Buka" : "Tutup";

    try {
      final response = await _merchantService.updateMerchantStatus(_merchantId, statusBaru);
      
      if (response['success'] == true) {
        setState(() => _isTokoActive = value);
        if (!mounted) return;
        
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Row(
              children: [
                Icon(value ? Icons.check_circle : Icons.info, color: value ? limeGreen : Colors.orange),
                const SizedBox(width: 8),
                Text("Status Diperbarui", style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: tealDark)),
              ],
            ),
            content: Text(
              "Toko kamu sekarang berstatus $statusBaru.",
              style: GoogleFonts.poppins(color: Colors.grey[700]),
            ),
            actions: [
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                style: ElevatedButton.styleFrom(
                  backgroundColor: tealDark,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text("Tutup"),
              )
            ],
          ),
        );
      } else {
        throw Exception(response['message'] ?? "Gagal merubah status");
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Terjadi kesalahan: $e")));
    } finally {
      if (mounted) setState(() => _isLoadingStatus = false);
    }
  }

  // --- FUNGSI BARU: MENAMPILKAN QR TOKO ---
  void _tampilkanQRToko() {
    if (_merchantId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Data toko sedang dimuat, coba lagi.")));
      return;
    }

    // JSON Rahasia untuk dibaca oleh Scanner Pelanggan
    String qrData = '{"tipe": "toko_litera", "merchant_id": "$_merchantId"}';

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "QR Code Toko Anda",
                style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: tealDark),
              ),
              const SizedBox(height: 8),
              Text(
                "Cetak dan pajang QR ini di kasir. Pelanggan dapat melakukan scan untuk melihat katalog produkmu.",
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600]),
              ),
              const SizedBox(height: 24),
              
              // Widget pembuat gambar QR
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade200, width: 2),
                ),
                child: QrImageView(
                  data: qrData, 
                  version: QrVersions.auto,
                  size: 200.0,
                  foregroundColor: tealDark,
                ),
              ),
              
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: limeGreen,
                    foregroundColor: tealDark,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text("Tutup", style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  String _formatCurrency(num price) {
    return NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    ).format(price);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: tealMid))
          : RefreshIndicator(
              color: tealMid,
              onRefresh: _loadData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeaderSection(),
                    _buildStatusOperasionalSection(),
                    
                    // --- TOMBOL BARU UNTUK MEMBUKA QR ---
                    _buildQrTokoCard(),

                    _buildKatalogSection(),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
    );
  }

  // ═══════════════════════════════════════════
  // HEADER SECTION 
  // ═══════════════════════════════════════════
  Widget _buildHeaderSection() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [tealDark, tealGradientEnd],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.2),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.3),
                    width: 2,
                  ),
                ),
                child: _profilePicture != null
                    ? ClipOval(
                        child: Image.network(
                          _profilePicture!,
                          fit: BoxFit.cover,
                          width: 56,
                          height: 56,
                          errorBuilder: (c, e, s) => const Icon(Icons.storefront_rounded, color: Colors.white70, size: 28),
                        ),
                      )
                    : const Icon(Icons.storefront_rounded, color: Colors.white70, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _namaBisnis.isEmpty ? 'Nama Merchant' : _namaBisnis,
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Mari kelola dan pantau usahamu hari ini.',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.white.withOpacity(0.8),
                      ),
                    ),
                  ],
                ),
              ),

            ],
          ),
        ),
      ),
    );
  }



  // ═══════════════════════════════════════════
  // TAMPILKAN QR TOKO KARTU BARU
  // ═══════════════════════════════════════════
  Widget _buildQrTokoCard() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: InkWell(
        onTap: _tampilkanQRToko,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: tealDark.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.qr_code_2, color: tealDark, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'QR Code Toko',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: tealDark,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Tampilkan QR untuk dipindai oleh pelanggan.',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.chevron_right, color: Colors.grey[400]),
            ],
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════
  // STATUS OPERASIONAL TOKO
  // ═══════════════════════════════════════════
  Widget _buildStatusOperasionalSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Status Operasional Toko',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1A1A2E),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _isTokoActive ? limeGreen : Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: _isTokoActive
                  ? []
                  : [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
              border: Border.all(
                color: _isTokoActive ? limeGreen : Colors.grey[200]!,
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: _isTokoActive ? tealDark : Colors.blueGrey[600],
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.storefront_rounded,
                    color: Colors.white,
                    size: 26,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Buka Toko',
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: _isTokoActive ? tealDark : const Color(0xFF1A1A2E),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _isTokoActive ? 'Aktif' : 'Tidak Aktif (Tutup)',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: _isTokoActive ? tealDark : Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Transform.scale(
                  scale: 1.1,
                  child: _isLoadingStatus
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(color: tealDark, strokeWidth: 2),
                        )
                      : Switch(
                          value: _isTokoActive,
                          onChanged: _toggleStatus,
                          activeThumbColor: tealDark,
                          activeTrackColor: Colors.white,
                          inactiveThumbColor: Colors.grey[400],
                          inactiveTrackColor: Colors.grey[300],
                          trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════
  // KATALOG SAYA
  // ═══════════════════════════════════════════
  Widget _buildKatalogSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Katalog Saya',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1A1A2E),
                ),
              ),
              GestureDetector(
                onTap: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const MerchantEditKatalogPage(),
                    ),
                  );
                  _loadData();
                },
                child: Text(
                  'Lihat Semua',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[500],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _products.isEmpty
              ? _buildEmptyKatalog()
              : ListView.separated(
                  padding: EdgeInsets.zero,
                  physics: const NeverScrollableScrollPhysics(),
                  shrinkWrap: true,
                  itemCount: _products.length > 5 ? 5 : _products.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) => _buildProductCard(_products[index]),
                ),
        ],
      ),
    );
  }

  Widget _buildEmptyKatalog() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Column(
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.shopping_bag_outlined,
                size: 36,
                color: Colors.grey[300],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Belum ada produk',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey[500],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Tambahkan produk melalui halaman Usaha',
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: Colors.grey[400],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductCard(ProductModel product) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(14),
              bottomLeft: Radius.circular(14),
            ),
            child: SizedBox(
              width: 120,
              height: 100,
              child: product.imageUrl != null && product.imageUrl!.isNotEmpty
                  ? Image.network(
                      product.imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (c, e, s) => Container(
                        color: Colors.grey[200],
                        child: Icon(Icons.fastfood_rounded, color: Colors.grey[400], size: 32),
                      ),
                    )
                  : Container(
                      color: Colors.grey[200],
                      child: Icon(Icons.fastfood_rounded, color: Colors.grey[400], size: 32),
                    ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    product.namaProduk,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF1A1A2E),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    product.deskripsi,
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: Colors.grey[500],
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _formatCurrency(product.hargaProduk),
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF1A1A2E),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: product.isAvailable ? limeGreen : Colors.grey[300],
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          product.isAvailable ? 'Tersedia' : 'Kosong',
                          style: GoogleFonts.poppins(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: product.isAvailable ? tealDark : Colors.grey[600],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}